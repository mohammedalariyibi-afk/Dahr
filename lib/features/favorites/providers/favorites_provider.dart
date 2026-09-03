import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

import '../../../core/models/models.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/supabase/supabase_client.dart';

final favoriteVendorIdsProvider =
    FutureProvider<Set<String>>((ref) async {
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
      .inFilter('id', ids.toList());
  return (rows as List)
      .map((e) => VendorProfile.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList();
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

  Future<void> toggle(String vendorId, {BuildContext? context}) async {
    final auth = ref.read(authProvider);
    if (!auth.isLoggedIn) {
      if (context != null && context.mounted) {
        final from = Uri.encodeComponent('/favorites');
        context.push('/auth/login?from=$from');
      }
      return;
    }
    final uid = auth.session!.user.id;
    final current = state.valueOrNull ?? {};
    if (current.contains(vendorId)) {
      await DahrSupabase.client
          .from('favorites')
          .delete()
          .eq('consumer_id', uid)
          .eq('vendor_id', vendorId);
      state = AsyncData({...current}..remove(vendorId));
    } else {
      await DahrSupabase.client.from('favorites').insert({
        'consumer_id': uid,
        'vendor_id': vendorId,
      });
      state = AsyncData({...current, vendorId});
    }
    ref.invalidate(favoriteVendorIdsProvider);
    ref.invalidate(favoriteVendorsProvider);
  }
}
