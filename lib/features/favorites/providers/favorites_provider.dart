import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/models.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/security/safe_user_error.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../../core/supabase/write_guard.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../discovery/providers/vendors_provider.dart';

final favoriteVendorIdsProvider = FutureProvider<Set<String>>((ref) async {
  final auth = ref.watch(authProvider);
  if (!auth.isLoggedIn) return {};
  final uid = auth.session!.user.id;
  final rows = await DahrSupabase.client
      .from('favorites')
      .select('vendor_id')
      .eq('consumer_id', uid);
  return {
    for (final r in rows as List) (r as Map)['vendor_id'] as String,
  };
});

final favoriteVendorsProvider =
    FutureProvider<List<VendorProfile>>((ref) async {
  final ids = await ref.watch(favoriteVendorIdsProvider.future);
  if (ids.isEmpty) return [];
  final rows = await DahrSupabase.client
      .from('vendor_profiles')
      .select('*, vendor_photos(*)')
      .inFilter('id', ids.toList())
      .eq('is_approved', true);
  final vendors = (rows as List)
      .map((e) => VendorProfile.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList();
  return attachVendorRatings(vendors);
});

final favoritesProvider =
    AsyncNotifierProvider<FavoritesNotifier, Set<String>>(
  FavoritesNotifier.new,
);

class FavoritesNotifier extends AsyncNotifier<Set<String>> {
  @override
  Future<Set<String>> build() async {
    return ref.watch(favoriteVendorIdsProvider.future);
  }

  /// Toggles favorite. Guests are sent to login with [returnPath] (or current route).
  Future<void> toggle(
    String vendorId, {
    BuildContext? context,
    String? returnPath,
  }) async {
    final auth = ref.read(authProvider);
    if (!auth.isLoggedIn) {
      if (context != null && context.mounted) {
        final path = returnPath ??
            GoRouterState.of(context).uri.toString();
        final from = Uri.encodeComponent(path);
        context.push('/auth/login?from=$from');
      }
      return;
    }

    final uid = auth.session!.user.id;
    final current = {...(state.valueOrNull ?? {})};
    final removing = current.contains(vendorId);

    // Optimistic update
    if (removing) {
      current.remove(vendorId);
    } else {
      current.add(vendorId);
    }
    state = AsyncData(current);

    try {
      if (removing) {
        final rows = await DahrSupabase.client
            .from('favorites')
            .delete()
            .eq('consumer_id', uid)
            .eq('vendor_id', vendorId)
            .select('id');
        requireMutatedRows(rows);
      } else {
        final rows = await DahrSupabase.client
            .from('favorites')
            .insert({
              'consumer_id': uid,
              'vendor_id': vendorId,
            })
            .select('id');
        requireMutatedRows(rows);
      }
      ref.invalidate(favoriteVendorIdsProvider);
      ref.invalidate(favoriteVendorsProvider);
    } catch (e) {
      // Revert optimistic update
      if (removing) {
        current.add(vendorId);
      } else {
        current.remove(vendorId);
      }
      state = AsyncData(current);
      if (context != null && context.mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(SafeUserError.of(l10n, e))),
        );
      }
    }
  }
}
