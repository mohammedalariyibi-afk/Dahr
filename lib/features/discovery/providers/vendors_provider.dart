import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/models.dart';
import '../../../core/supabase/supabase_client.dart';

class VendorFilters {
  const VendorFilters({
    this.category,
    this.city,
    this.search,
    this.priceMin,
    this.priceMax,
  });

  final VendorCategory? category;
  final CityCode? city;
  final String? search;
  final double? priceMin;
  final double? priceMax;

  bool get hasActiveFilters =>
      city != null || priceMin != null || priceMax != null;

  VendorFilters copyWith({
    VendorCategory? category,
    CityCode? city,
    String? search,
    double? priceMin,
    double? priceMax,
    bool clearCategory = false,
    bool clearCity = false,
    bool clearSearch = false,
    bool clearPrice = false,
  }) {
    return VendorFilters(
      category: clearCategory ? null : (category ?? this.category),
      city: clearCity ? null : (city ?? this.city),
      search: clearSearch ? null : (search ?? this.search),
      priceMin: clearPrice ? null : (priceMin ?? this.priceMin),
      priceMax: clearPrice ? null : (priceMax ?? this.priceMax),
    );
  }
}

final vendorFiltersProvider =
    StateNotifierProvider<VendorFiltersController, VendorFilters>((ref) {
  return VendorFiltersController();
});

class VendorFiltersController extends StateNotifier<VendorFilters> {
  VendorFiltersController() : super(const VendorFilters());

  void setCategory(VendorCategory? category) {
    state = state.copyWith(
      category: category,
      clearCategory: category == null,
    );
  }

  void setCity(CityCode? city) {
    state = state.copyWith(city: city, clearCity: city == null);
  }

  void setSearch(String? search) {
    final t = search?.trim();
    state = state.copyWith(
      search: t,
      clearSearch: t == null || t.isEmpty,
    );
  }

  void setPriceRange(double? min, double? max) {
    state = VendorFilters(
      category: state.category,
      city: state.city,
      search: state.search,
      priceMin: min,
      priceMax: max,
    );
  }

  void clear() => state = const VendorFilters();
}

final vendorsProvider =
    AsyncNotifierProvider<VendorsNotifier, List<VendorProfile>>(
  VendorsNotifier.new,
);

class VendorsNotifier extends AsyncNotifier<List<VendorProfile>> {
  @override
  Future<List<VendorProfile>> build() async {
    ref.watch(vendorFiltersProvider);
    return _fetch();
  }

  Future<List<VendorProfile>> _fetch() async {
    final filters = ref.read(vendorFiltersProvider);
    var query = DahrSupabase.client
        .from('vendor_profiles')
        .select('*, vendor_photos(*)')
        .eq('is_approved', true);

    if (filters.category != null) {
      query = query.eq('category', filters.category!.name);
    }
    if (filters.city != null) {
      query = query.eq('city', filters.city!.name);
    }
    if (filters.priceMin != null) {
      query = query.gte('price_max', filters.priceMin!);
    }
    if (filters.priceMax != null) {
      query = query.lte('price_min', filters.priceMax!);
    }
    if (filters.search != null && filters.search!.isNotEmpty) {
      // Sanitize for PostgREST .or() filter syntax.
      final q = filters.search!.replaceAll(RegExp(r'[%_,]'), ' ').trim();
      if (q.isNotEmpty) {
        query = query.or(
          'business_name.ilike.%$q%,description.ilike.%$q%',
        );
      }
    }

    final rows = await query.order('created_at', ascending: false);
    final vendors = (rows as List)
        .map((e) => VendorProfile.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    return _withRatings(vendors);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }
}

/// Attaches avg rating / review count from the reviews table
/// (columns are not stored on vendor_profiles).
Future<List<VendorProfile>> _withRatings(List<VendorProfile> vendors) async {
  if (vendors.isEmpty) return vendors;
  final ids = vendors.map((v) => v.id).toList();
  final rows = await DahrSupabase.client
      .from('reviews')
      .select('vendor_id, rating')
      .eq('is_hidden', false)
      .inFilter('vendor_id', ids);

  final sums = <String, double>{};
  final counts = <String, int>{};
  for (final raw in rows as List) {
    final row = Map<String, dynamic>.from(raw as Map);
    final id = row['vendor_id'] as String;
    final rating = (row['rating'] as num).toDouble();
    sums[id] = (sums[id] ?? 0) + rating;
    counts[id] = (counts[id] ?? 0) + 1;
  }

  return vendors
      .map((v) {
        final count = counts[v.id] ?? 0;
        if (count == 0) return v;
        return v.copyWith(
          avgRating: sums[v.id]! / count,
          reviewCount: count,
        );
      })
      .toList();
}

final vendorDetailProvider =
    FutureProvider.family<VendorProfile, String>((ref, id) async {
  final row = await DahrSupabase.client
      .from('vendor_profiles')
      .select('*, vendor_photos(*)')
      .eq('id', id)
      .maybeSingle();
  if (row == null) throw StateError('Vendor not found');

  // Fire-and-forget view increment
  // ignore: unawaited_futures
  DahrSupabase.client.rpc('increment_vendor_views', params: {
    'p_vendor_id': id,
  });

  final vendor = VendorProfile.fromJson(Map<String, dynamic>.from(row));
  final withRatings = await _withRatings([vendor]);
  return withRatings.first;
});

final vendorReviewsProvider =
    FutureProvider.family<List<Review>, String>((ref, vendorId) async {
  final rows = await DahrSupabase.client
      .from('reviews')
      .select('*, profiles(full_name)')
      .eq('vendor_id', vendorId)
      .eq('is_hidden', false)
      .order('created_at', ascending: false);
      return (rows as List)
          .map((e) => Review.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList()
          .where((r) => r.isVisibleToPublic)
          .toList();
});
