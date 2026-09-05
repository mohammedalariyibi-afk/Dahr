import 'package:flutter_test/flutter_test.dart';
import 'package:dahr/core/models/booking.dart';
import 'package:dahr/core/models/enums.dart';
import 'package:dahr/core/models/review.dart';
import 'package:dahr/features/vendor_profile/providers/vendor_provider.dart';

void main() {
  group('AvailabilitySlot', () {
    test('isDateBooked matches booked days only', () {
      final slots = [
        AvailabilitySlot(
          id: '1',
          vendorId: 'v1',
          date: DateTime(2030, 6, 15),
          status: 'booked',
        ),
        AvailabilitySlot(
          id: '2',
          vendorId: 'v1',
          date: DateTime(2030, 6, 16),
          status: 'available',
        ),
      ];
      expect(
        AvailabilitySlot.isDateBooked(slots, DateTime(2030, 6, 15)),
        isTrue,
      );
      expect(
        AvailabilitySlot.isDateBooked(slots, DateTime(2030, 6, 16)),
        isFalse,
      );
      expect(
        AvailabilitySlot.isDateBooked(slots, DateTime(2030, 6, 17)),
        isFalse,
      );
    });
  });

  group('ReviewPayload', () {
    test('validate accepts 1-5 rating', () {
      const ok = ReviewPayload(
        vendorId: 'v1',
        consumerId: 'c1',
        bookingRequestId: 'b1',
        rating: 4,
        comment: 'Great',
      );
      expect(ok.validate(), isNull);
      expect(ok.toJson()['rating'], 4);
    });

    test('validate rejects empty ids and out of range rating', () {
      expect(
        const ReviewPayload(
          vendorId: '',
          consumerId: 'c1',
          bookingRequestId: 'b1',
          rating: 5,
        ).validate(),
        'vendor_required',
      );
      expect(
        const ReviewPayload(
          vendorId: 'v1',
          consumerId: 'c1',
          bookingRequestId: 'b1',
          rating: 0,
        ).validate(),
        'rating_invalid',
      );
      expect(
        const ReviewPayload(
          vendorId: 'v1',
          consumerId: 'c1',
          bookingRequestId: 'b1',
          rating: 6,
        ).validate(),
        'rating_invalid',
      );
    });
  });

  group('BookingRequest json extras', () {
    test('reads consumer name and existing review', () {
      final booking = BookingRequest.fromJson({
        'id': 'b1',
        'vendor_id': 'v1',
        'consumer_id': 'c1',
        'event_date': '2030-06-15',
        'status': 'completed',
        'profile_public': {'full_name': 'Amina'},
        'reviews': [
          {'id': 'r1'},
        ],
      });
      expect(booking.consumerName, 'Amina');
      expect(booking.hasReview, isTrue);
      expect(booking.status, BookingStatus.completed);
    });
  });

  group('storagePathFromPublicUrl', () {
    test('extracts object path from public URL', () {
      const url =
          'https://example.supabase.co/storage/v1/object/public/vendor-photos/user-1/photo.jpg';
      expect(storagePathFromPublicUrl(url), 'user-1/photo.jpg');
      expect(storagePathFromPublicUrl('https://example.com/other'), isNull);
    });
  });
}
