import 'package:flutter_test/flutter_test.dart';
import 'package:dahr/core/models/vendor.dart';

Map<String, dynamic> _row(Map<String, dynamic> extra) => {
      'id': 'c1',
      'profile_id': 'b1',
      'business_name': 'قاعة النور',
      'category': 'venues',
      'city': 'tripoli',
      ...extra,
    };

void main() {
  group('VendorProfile.fromJson tolerates either NUMERIC encoding', () {
    test('numbers parse', () {
      final vendor = VendorProfile.fromJson(_row({
        'price_min': 1500.0,
        'price_max': 3000,
        'view_count': 12,
        'avg_rating': 4.5,
        'review_count': 3,
      }));
      expect(vendor.priceMin, 1500.0);
      expect(vendor.priceMax, 3000);
      expect(vendor.viewCount, 12);
      expect(vendor.avgRating, 4.5);
      expect(vendor.reviewCount, 3);
    });

    test('quoted numerics parse instead of throwing', () {
      final vendor = VendorProfile.fromJson(_row({
        'price_min': '1500.00',
        'price_max': '3000.00',
        'view_count': '12',
        'avg_rating': '4.5',
        'review_count': '3',
      }));
      expect(vendor.priceMin, 1500.0);
      expect(vendor.priceMax, 3000.0);
      expect(vendor.viewCount, 12);
      expect(vendor.avgRating, 4.5);
      expect(vendor.reviewCount, 3);
    });

    test('missing and unparseable values fall back instead of throwing', () {
      final vendor = VendorProfile.fromJson(_row({
        'price_min': null,
        'price_max': 'not a number',
      }));
      expect(vendor.priceMin, isNull);
      expect(vendor.priceMax, isNull);
      expect(vendor.viewCount, 0);
      expect(vendor.reviewCount, 0);
      expect(vendor.avgRating, isNull);
    });

    test('photo sort order survives a quoted integer', () {
      final photo = VendorPhoto.fromJson({
        'id': 'p1',
        'vendor_id': 'c1',
        'storage_url': 'https://example.test/p.jpg',
        'sort_order': '2',
      });
      expect(photo.sortOrder, 2);
    });
  });
}
