import 'package:flutter_test/flutter_test.dart';
import 'package:dahr/core/models/enums.dart';
import 'package:dahr/features/discovery/providers/vendors_provider.dart';

void main() {
  test('hasNarrowing includes category and search', () {
    expect(const VendorFilters().hasNarrowing, isFalse);
    expect(
      const VendorFilters(category: VendorCategory.venues).hasNarrowing,
      isTrue,
    );
    expect(const VendorFilters(search: 'hall').hasNarrowing, isTrue);
    expect(
      const VendorFilters(city: CityCode.tripoli).hasActiveFilters,
      isTrue,
    );
  });

  test('sanitizeSearch strips PostgREST filter metacharacters', () {
    expect(VendorFilters.sanitizeSearch('قاعة, hall'), 'قاعة hall');
    expect(VendorFilters.sanitizeSearch('hall%_'), 'hall');
    expect(VendorFilters.sanitizeSearch('a).or(id.eq.1'), 'a or id eq 1');
    expect(VendorFilters.sanitizeSearch('  photo-studio  '), 'photo-studio');
    expect(VendorFilters.sanitizeSearch(''), '');
  });
}
