import 'package:flutter_test/flutter_test.dart';
import 'package:dahr/core/models/enums.dart';
import 'package:dahr/core/models/vendor.dart';
import 'package:dahr/features/discovery/providers/vendors_provider.dart';

VendorProfile _vendor(String id) => VendorProfile(
      id: id,
      profileId: 'p$id',
      businessName: 'Hall $id',
      category: VendorCategory.venues,
      city: CityCode.tripoli,
    );

void main() {
  group('applyVendorRatingRows', () {
    test('quoted NUMERIC ratings roll up instead of throwing', () {
      final vendors = [_vendor('v1'), _vendor('v2')];
      final rolled = applyVendorRatingRows(vendors, [
        {'vendor_id': 'v1', 'rating': '5'},
        {'vendor_id': 'v1', 'rating': '3.0'},
        {'vendor_id': 'v2', 'rating': '4'},
      ]);
      expect(rolled[0].avgRating, 4.0);
      expect(rolled[0].reviewCount, 2);
      expect(rolled[1].avgRating, 4.0);
      expect(rolled[1].reviewCount, 1);
    });

    test('numeric ratings still average', () {
      final rolled = applyVendorRatingRows([_vendor('v1')], [
        {'vendor_id': 'v1', 'rating': 5},
        {'vendor_id': 'v1', 'rating': 4},
      ]);
      expect(rolled.single.avgRating, 4.5);
      expect(rolled.single.reviewCount, 2);
    });

    test('null and unparseable ratings are skipped, not thrown', () {
      final rolled = applyVendorRatingRows([_vendor('v1')], [
        {'vendor_id': 'v1', 'rating': null},
        {'vendor_id': 'v1', 'rating': 'not a number'},
        {'vendor_id': 'v1', 'rating': '5'},
      ]);
      expect(rolled.single.avgRating, 5.0);
      expect(rolled.single.reviewCount, 1);
    });

    test('a vendor with no usable ratings stays unchanged', () {
      final vendor = _vendor('v1');
      final rolled = applyVendorRatingRows([vendor], [
        {'vendor_id': 'other', 'rating': '5'},
        {'vendor_id': 'v1', 'rating': null},
      ]);
      expect(rolled.single.avgRating, isNull);
      expect(rolled.single.reviewCount, 0);
    });
  });
}
