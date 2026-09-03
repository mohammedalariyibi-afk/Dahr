import 'package:flutter_test/flutter_test.dart';
import 'package:dahr/core/models/vendor.dart';
import 'package:dahr/core/models/enums.dart';

void main() {
  VendorOnboardingPayload payload({
    String profileId = 'p1',
    String businessName = 'Riad Hall',
    VendorCategory category = VendorCategory.venues,
    CityCode city = CityCode.tripoli,
    String description = 'Wedding hall in Tripoli',
    String whatsapp = '912345678',
    double? priceMin = 1000,
    double? priceMax = 4000,
  }) {
    return VendorOnboardingPayload(
      profileId: profileId,
      businessName: businessName,
      category: category,
      city: city,
      description: description,
      whatsappNumber: whatsapp,
      priceMin: priceMin,
      priceMax: priceMax,
    );
  }

  group('VendorOnboardingPayload.validate', () {
    test('accepts required fields', () {
      expect(payload().validate(), isNull);
    });

    test('requires business name, description, WhatsApp, and price range', () {
      expect(payload(businessName: '  ').validate(), 'business_name_required');
      expect(payload(description: '').validate(), 'description_required');
      expect(payload(whatsapp: '').validate(), 'whatsapp_required');
      expect(payload(whatsapp: '123').validate(), 'whatsapp_invalid');
      expect(payload(priceMin: null).validate(), 'price_range_required');
      expect(payload(priceMax: null).validate(), 'price_range_required');
      expect(payload(priceMin: 0, priceMax: 100).validate(), 'price_range_invalid');
      expect(
        payload(priceMin: 5000, priceMax: 1000).validate(),
        'price_range_invalid',
      );
    });

    test('fromInput parses services and prices', () {
      final p = VendorOnboardingPayload.fromInput(
        profileId: 'p1',
        businessName: ' Studio ',
        category: VendorCategory.photography,
        city: CityCode.benghazi,
        description: 'Photos',
        whatsappNumber: '+218912345678',
        priceMinRaw: '800',
        priceMaxRaw: '2500',
        servicesRaw: 'bridal,  engagement',
      );
      expect(p.validate(), isNull);
      expect(p.services, ['bridal', 'engagement']);
      expect(p.toJson()['whatsapp_number'], '+218912345678');
      expect(p.toJson()['city'], 'benghazi');
      expect(p.toJson()['category'], 'photography');
    });

    test('requires a profile id', () {
      expect(payload(profileId: '').validate(), 'profile_required');
    });
  });

  group('VendorPhotoStorage', () {
    test('rejects traversal and non-https public URLs', () {
      expect(
        VendorPhotoStorage.objectPathFromPublicUrl(
          'https://xyz.supabase.co/storage/v1/object/public/vendor-photos/../etc/passwd',
        ),
        isNull,
      );
      expect(
        VendorPhotoStorage.objectPathFromPublicUrl(
          'http://xyz.supabase.co/storage/v1/object/public/vendor-photos/user-1/abc.jpg',
        ),
        isNull,
      );
      expect(VendorPhotoStorage.isSafeObjectPath('user-1/abc.jpg'), isTrue);
      expect(VendorPhotoStorage.isOwnedObjectPath('user-1', 'user-1/abc.jpg'), isTrue);
      expect(VendorPhotoStorage.isOwnedObjectPath('user-1', 'user-2/abc.jpg'), isFalse);
    });

    test('parses public storage url', () {
      const url =
          'https://xyz.supabase.co/storage/v1/object/public/vendor-photos/user-1/abc.jpg';
      expect(
        VendorPhotoStorage.objectPathFromPublicUrl(url),
        'user-1/abc.jpg',
      );
      expect(
        VendorPhotoStorage.objectPathFromPublicUrl('$url?token=1'),
        'user-1/abc.jpg',
      );
      expect(
        VendorPhotoStorage.objectPath(
          '11111111-1111-1111-1111-111111111111',
          'abc',
        ),
        '11111111-1111-1111-1111-111111111111/abc.jpg',
      );
      expect(VendorPhotoStorage.objectPathFromPublicUrl('https://example.com'), isNull);
      expect(
        VendorPhotoStorage.objectPathFromPublicUrl(
          'https://xyz.supabase.co/storage/v1/object/sign/vendor-photos/user-1/abc.jpg',
        ),
        isNull,
      );
    });

    test('reorders photos and rewrites sort_order', () {
      const photos = [
        VendorPhoto(id: 'a', vendorId: 'v', storageUrl: 'u1', sortOrder: 0),
        VendorPhoto(id: 'b', vendorId: 'v', storageUrl: 'u2', sortOrder: 1),
        VendorPhoto(id: 'c', vendorId: 'v', storageUrl: 'u3', sortOrder: 2),
      ];
      // onReorderItem / applyReorder: newIndex is the destination after removal.
      final moved = VendorPhotoStorage.applyReorder(photos, 0, 1);
      expect(moved.map((p) => p.id).toList(), ['b', 'a', 'c']);
      expect(moved.map((p) => p.sortOrder).toList(), [0, 1, 2]);
      final toEnd = VendorPhotoStorage.applyReorder(photos, 0, 2);
      expect(toEnd.map((p) => p.id).toList(), ['b', 'c', 'a']);
      final lastToFirst = VendorPhotoStorage.applyReorder(photos, 2, 0);
      expect(lastToFirst.map((p) => p.id).toList(), ['c', 'a', 'b']);
      final upOne = VendorPhotoStorage.applyReorder(photos, 2, 1);
      expect(upOne.map((p) => p.id).toList(), ['a', 'c', 'b']);
      final same = VendorPhotoStorage.applyReorder(photos, 1, 1);
      expect(same.map((p) => p.id).toList(), ['a', 'b', 'c']);
      expect(
        VendorPhotoStorage.applyReorder(photos, -1, 0).map((p) => p.id).toList(),
        ['a', 'b', 'c'],
      );
    });
  });
}
