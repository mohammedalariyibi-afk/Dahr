import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/models.dart';
import '../supabase/supabase_client.dart';

enum AuthFlowStatus {
  unknown,
  unauthenticated,
  needsRole,
  needsProfile,
  authenticated,
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
  AuthController()
      : super(const AppAuthState(status: AuthFlowStatus.unknown)) {
    _authSub = DahrSupabase.auth.onAuthStateChange.listen((data) {
      _syncFromSession(data.session);
    });
    _syncFromSession(DahrSupabase.auth.currentSession);
  }

  late final StreamSubscription<AuthState> _authSub;

  Future<void> _syncFromSession(Session? session) async {
    if (session == null) {
      state = const AppAuthState(status: AuthFlowStatus.unauthenticated);
      return;
    }

    try {
      final profile = await fetchProfile(session.user.id);
      if (profile == null ||
          profile.fullName == null ||
          profile.fullName!.trim().isEmpty) {
        state = AppAuthState(
          status: AuthFlowStatus.needsRole,
          session: session,
          profile: profile,
        );
        return;
      }

      if (!profile.isProfileComplete) {
        state = AppAuthState(
          status: AuthFlowStatus.needsProfile,
          session: session,
          profile: profile,
        );
        return;
      }

      state = AppAuthState(
        status: AuthFlowStatus.authenticated,
        session: session,
        profile: profile,
      );
    } catch (_) {
      state = AppAuthState(
        status: AuthFlowStatus.needsProfile,
        session: session,
      );
    }
  }

  Future<Profile?> fetchProfile(String userId) async {
    final row = await DahrSupabase.client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    if (row == null) return null;
    return Profile.fromJson(Map<String, dynamic>.from(row));
  }

  Future<void> refreshProfile() async {
    await _syncFromSession(DahrSupabase.auth.currentSession);
  }

  Future<void> signInWithPhone(String e164Phone) async {
    await DahrSupabase.auth.signInWithOtp(phone: e164Phone);
  }

  Future<void> signInWithEmail(String email) async {
    await DahrSupabase.auth.signInWithOtp(
      email: email.trim(),
      shouldCreateUser: true,
    );
  }

  Future<AuthResponse> verifyPhoneOtp({
    required String e164Phone,
    required String token,
  }) {
    return DahrSupabase.auth.verifyOTP(
      phone: e164Phone,
      token: token,
      type: OtpType.sms,
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
    await DahrSupabase.client.from('profiles').upsert({
      'id': uid,
      'role': role.name,
    });
    // Keep a complete profile authenticated (e.g. consumer becoming vendor).
    await refreshProfile();
  }

  Future<void> completeProfile({
    required String fullName,
    required CityCode city,
    DateTime? weddingDate,
    String? locale,
  }) async {
    final uid = DahrSupabase.currentUserId;
    if (uid == null) throw StateError('Not signed in');
    final payload = <String, dynamic>{
      'id': uid,
      'full_name': fullName.trim(),
      'city': city.name,
      if (weddingDate != null)
        'wedding_date': weddingDate.toIso8601String().split('T').first,
      if (locale != null) 'locale': locale,
    };
    await DahrSupabase.client.from('profiles').upsert(payload);
    await refreshProfile();
  }

  Future<void> updateLocale(String locale) async {
    final uid = DahrSupabase.currentUserId;
    if (uid == null) return;
    await DahrSupabase.client
        .from('profiles')
        .update({'locale': locale}).eq('id', uid);
  }

  Future<void> signOut() async {
    await DahrSupabase.auth.signOut();
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
