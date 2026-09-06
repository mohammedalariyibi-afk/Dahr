import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/app_constants.dart';
import '../models/models.dart';
import '../supabase/supabase_client.dart';
import '../supabase/write_guard.dart';
import 'role_choice_store.dart';

enum AuthFlowStatus {
  unknown,
  unauthenticated,
  needsRole,
  needsProfile,
  authenticated,
}

/// Maps a signed-in profile onto the onboarding step that is still missing.
///
/// `profiles.role` defaults to `consumer`, so the row itself cannot say
/// whether the user ever saw the role screen. [roleChosen] carries that,
/// otherwise picking a role would leave the status on [AuthFlowStatus.needsRole]
/// and the router would bounce the user back to `/auth/role` forever.
AuthFlowStatus resolveAuthFlowStatus({
  required Profile? profile,
  required bool roleChosen,
}) {
  final hasName = profile?.fullName?.trim().isNotEmpty ?? false;
  if (!roleChosen && !hasName) return AuthFlowStatus.needsRole;
  if (profile == null || !profile.isProfileComplete) {
    return AuthFlowStatus.needsProfile;
  }
  return AuthFlowStatus.authenticated;
}

class AppAuthState {
  const AppAuthState({
    required this.status,
    this.session,
    this.profile,
  });

  final AuthFlowStatus status;
  final Session? session;
  final Profile? profile;

  bool get isLoggedIn => session != null;
  bool get isGuest => session == null;
  bool get isVendor => profile?.role == UserRole.vendor;
  bool get isConsumer =>
      profile == null || profile?.role == UserRole.consumer;
}

final authProvider =
    StateNotifierProvider<AuthController, AppAuthState>((ref) {
  return AuthController();
});

class AuthController extends StateNotifier<AppAuthState> {
  AuthController({RoleChoiceStore? roleChoice})
      : _roleChoice = roleChoice,
        super(const AppAuthState(status: AuthFlowStatus.unknown)) {
    _roleChosenBy = roleChoice?.chosenBy;
    _authSub = DahrSupabase.auth.onAuthStateChange.listen((data) {
      _syncFromSession(data.session);
    });
    _hydrateAndSync();
  }

  late final StreamSubscription<AuthState> _authSub;

  /// User id that picked a role on this device since sign-in.
  /// Hydrated from [RoleChoiceStore] so a kill-app before the name is saved
  /// still reports the pick to [resolveAuthFlowStatus].
  String? _roleChosenBy;

  RoleChoiceStore? _roleChoice;

  /// Bumped by every sync. A profile fetch that finishes after a newer sync
  /// started must not write its result — otherwise a fetch still in flight
  /// when the user signs out would resurrect the signed-in state.
  int _syncGeneration = 0;

  Future<RoleChoiceStore?> _ensureStore() async {
    if (_roleChoice != null) return _roleChoice;
    try {
      _roleChoice = await RoleChoiceStore.open();
    } catch (_) {
      return null;
    }
    return _roleChoice;
  }

  Future<void> _hydrateAndSync() async {
    final store = await _ensureStore();
    _roleChosenBy ??= store?.chosenBy;
    await _syncFromSession(DahrSupabase.auth.currentSession);
  }

  bool _roleChosenFor(String userId) {
    return isRoleChosenForUser(
      userId: userId,
      inMemoryChosenBy: _roleChosenBy,
      persistedChosenBy: _roleChoice?.chosenBy,
    );
  }

  Future<void> _syncFromSession(Session? session) async {
    final generation = ++_syncGeneration;

    if (session == null) {
      _roleChosenBy = null;
      state = const AppAuthState(status: AuthFlowStatus.unauthenticated);
      return;
    }

    await _ensureStore();
    if (!_isCurrent(generation, session)) return;
    _roleChosenBy ??= _roleChoice?.chosenBy;

    try {
      final profile = await fetchProfile(session.user.id);
      if (!_isCurrent(generation, session)) return;
      state = AppAuthState(
        status: resolveAuthFlowStatus(
          profile: profile,
          roleChosen: _roleChosenFor(session.user.id),
        ),
        session: session,
        profile: profile,
      );
    } catch (_) {
      if (!_isCurrent(generation, session)) return;
      // A failed profile read must not push a finished user back through
      // onboarding; keep what we already know.
      final known = state.profile;
      if (known != null && known.id == session.user.id) {
        state = AppAuthState(
          status: resolveAuthFlowStatus(
            profile: known,
            roleChosen: _roleChosenFor(session.user.id),
          ),
          session: session,
          profile: known,
        );
        return;
      }
      state = AppAuthState(
        status: AuthFlowStatus.needsProfile,
        session: session,
      );
    }
  }

  /// False once a newer sync has started, or once the client has moved on to
  /// another session (or to none at all).
  bool _isCurrent(int generation, Session session) {
    if (generation != _syncGeneration) return false;
    return DahrSupabase.auth.currentSession?.user.id == session.user.id;
  }

  Future<Profile?> fetchProfile(String userId) async {
    final row = await DahrSupabase.client
        .from('profiles')
        .select(
          'id, phone, full_name, role, city, wedding_date, locale, created_at',
        )
        .eq('id', userId)
        .maybeSingle();
    if (row == null) return null;
    return Profile.fromJson(Map<String, dynamic>.from(row));
  }

  Future<void> refreshProfile() async {
    await _syncFromSession(DahrSupabase.auth.currentSession);
  }

  Future<void> signInWithEmail(String email) async {
    await DahrSupabase.auth.signInWithOtp(
      email: email.trim(),
      shouldCreateUser: true,
    );
  }

  Future<AuthResponse> verifyEmailOtp({
    required String email,
    required String token,
  }) {
    return DahrSupabase.auth.verifyOTP(
      email: email.trim(),
      token: token,
      type: OtpType.email,
    );
  }

  Future<void> setRole(UserRole role) async {
    final uid = DahrSupabase.currentUserId;
    if (uid == null) throw StateError('Not signed in');
    final payload = ProfileRoleWrite.upsertPayload(userId: uid, role: role);
    final rows = await DahrSupabase.client
        .from('profiles')
        .upsert(payload)
        .select('id, role');
    requireMutatedRows(rows);
    // `profiles.role` defaults to consumer, so a re-read cannot tell "picked
    // consumer" from "never picked" and would keep reporting needsRole, with
    // the router bouncing profile setup back to role select. Recording the
    // pick here keeps that true for every later refresh in this session, not
    // just the one below.
    _roleChosenBy = uid;
    try {
      await (await _ensureStore())?.remember(uid);
    } catch (_) {
      // In-memory pick still advances this session; persist is best-effort.
    }
    // Keep a complete profile authenticated (e.g. consumer becoming vendor).
    await refreshProfile();
  }

  Future<void> completeProfile({
    required String fullName,
    required CityCode city,
    DateTime? weddingDate,
    String? locale,
    String? phone,
    bool requirePhone = false,
  }) async {
    final uid = DahrSupabase.currentUserId;
    if (uid == null) throw StateError('Not signed in');
    final trimmedPhone = phone?.trim() ?? '';
    if (requirePhone && trimmedPhone.isEmpty) {
      throw StateError('phone_required');
    }
    if (trimmedPhone.isNotEmpty && !AppConstants.isValidLibyaPhone(trimmedPhone)) {
      throw StateError('phone_invalid');
    }
    final payload = <String, dynamic>{
      'id': uid,
      'full_name': fullName.trim(),
      'city': city.name,
      if (weddingDate != null)
        'wedding_date': weddingDate.toIso8601String().split('T').first,
      if (locale != null) 'locale': locale,
      if (requirePhone || phone != null)
        'phone': trimmedPhone.isEmpty
            ? null
            : AppConstants.toE164Libya(trimmedPhone),
    };
    final rows =
        await DahrSupabase.client.from('profiles').upsert(payload).select('id');
    requireMutatedRows(rows);
    await refreshProfile();
  }

  Future<void> updateLocale(String locale) async {
    final uid = DahrSupabase.currentUserId;
    if (uid == null) return;
    final rows = await DahrSupabase.client
        .from('profiles')
        .update({'locale': locale})
        .eq('id', uid)
        .select('id');
    requireMutatedRows(rows);
  }

  Future<void> signOut() async {
    await DahrSupabase.auth.signOut();
    _roleChosenBy = null;
    try {
      await (await _ensureStore())?.forget();
    } catch (_) {}
    state = const AppAuthState(status: AuthFlowStatus.unauthenticated);
  }

  /// Deletes the signed-in auth user via SECURITY DEFINER RPC.
  /// Best-effort Storage cleanup first — owning objects blocks auth delete.
  Future<void> deleteAccount() async {
    final uid = DahrSupabase.currentUserId;
    if (uid == null) throw StateError('Not signed in');

    try {
      final listed = await DahrSupabase.client.storage
          .from(VendorPhotoStorage.bucket)
          .list(path: uid);
      if (listed.isNotEmpty) {
        await DahrSupabase.client.storage.from(VendorPhotoStorage.bucket).remove(
              listed.map((f) => '$uid/${f.name}').toList(),
            );
      }
    } catch (_) {
      // RPC still deletes storage.objects metadata for this uid prefix.
    }

    // RPC name must match DeleteAccountRpcSpec — no user-id argument.
    await DahrSupabase.client.rpc('delete_own_account');
    await signOut();
  }

  @override
  void dispose() {
    _authSub.cancel();
    super.dispose();
  }
}

final currentProfileProvider = Provider<Profile?>((ref) {
  return ref.watch(authProvider).profile;
});
