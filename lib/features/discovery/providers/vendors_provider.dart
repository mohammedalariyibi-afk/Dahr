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
      query = query.ilike('business_name', '%${filters.search}%');
    }

    final rows = await query.order('created_at', ascending: false);
    return (rows as List)
        .map((e) => VendorProfile.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }
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
  DahrSupabase.client.rpc('increment_vendor_views', params: {
    'p_vendor_id': id,
  });

  return VendorProfile.fromJson(Map<String, dynamic>.from(row));
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
