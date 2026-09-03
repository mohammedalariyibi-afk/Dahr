import 'package:flutter_test/flutter_test.dart';
import 'package:dahr/core/models/review.dart';
import 'package:dahr/core/models/enums.dart';

void main() {
  ReviewPayload payload() => const ReviewPayload(
        vendorId: 'v1',
        consumerId: 'c1',
        bookingRequestId: 'b1',
        rating: 5,
        comment: 'Beautiful hall',
      );

  group('ReviewPayload', () {
    test('allows a review only when the booking is completed', () {
      expect(
        payload().validate(bookingStatus: BookingStatus.pending),
        'review_not_completed',
      );
      expect(
        payload().validate(bookingStatus: BookingStatus.accepted),
        'review_not_completed',
      );
      expect(
        payload().validate(bookingStatus: BookingStatus.declined),
        'review_not_completed',
      );
      expect(
        payload().validate(bookingStatus: BookingStatus.completed),
        isNull,
      );
    });

    test('rejects a second review on the same booking', () {
      expect(
        payload().validate(
          bookingStatus: BookingStatus.completed,
          alreadyReviewed: true,
        ),
        'already_reviewed',
      );
    });

    test('rejects an out-of-range rating', () {
      expect(
        const ReviewPayload(
          vendorId: 'v1',
          consumerId: 'c1',
          bookingRequestId: 'b1',
          rating: 0,
        ).validate(bookingStatus: BookingStatus.completed),
        'rating_invalid',
      );
    });
  });

  group('hidden reviews', () {
    test('visibleReviews drops hidden rows', () {
      const shown = Review(
        id: '1',
        vendorId: 'v',
        consumerId: 'c',
        bookingRequestId: 'b1',
        rating: 5,
      );
      const hidden = Review(
        id: '2',
        vendorId: 'v',
        consumerId: 'c',
        bookingRequestId: 'b2',
        rating: 1,
        isHidden: true,
      );
      expect(visibleReviews([shown, hidden]).map((r) => r.id), ['1']);
      expect(canLeaveReview(status: BookingStatus.completed, alreadyReviewed: false), isTrue);
      expect(canLeaveReview(status: BookingStatus.accepted, alreadyReviewed: false), isFalse);
    });
  });
}
