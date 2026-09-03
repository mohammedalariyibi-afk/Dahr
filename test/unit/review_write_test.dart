import 'package:flutter_test/flutter_test.dart';
import 'package:dahr/core/models/enums.dart';
import 'package:dahr/core/models/review.dart';
import 'package:dahr/core/security/review_write.dart';

Matcher _writeRejected() => isA<StateError>().having(
      (e) => e.message,
      'message',
      'write_rejected',
    );

void main() {
  group('ReviewWrite', () {
    test('consumers insert only and cannot UPDATE including is_hidden', () {
      expect(ReviewWrite.canInsert(UserRole.consumer), isTrue);
      expect(ReviewWrite.canUpdate(UserRole.consumer), isFalse);
      expect(
        () => ReviewWrite.consumerUpdate({'comment': 'edit'}),
        throwsA(_writeRejected()),
      );
      expect(
        () => ReviewWrite.consumerUpdate({'is_hidden': true}),
        throwsA(_writeRejected()),
      );
      expect(
        () => ReviewWrite.consumerUpdate({'is_hidden': false}),
        throwsA(_writeRejected()),
      );
    });

    test('consumer insert payload omits is_hidden', () {
      final json = ReviewWrite.consumerInsert({
        'vendor_id': 'v1',
        'consumer_id': 'c1',
        'booking_request_id': 'b1',
        'rating': 5,
        'comment': 'Great',
      });
      expect(json.containsKey('is_hidden'), isFalse);
      expect(
        () => ReviewWrite.consumerInsert({
          'vendor_id': 'v1',
          'is_hidden': false,
        }),
        throwsA(_writeRejected()),
      );
      expect(
        () => ReviewWrite.consumerInsert({'is_hidden': true}),
        throwsA(_writeRejected()),
      );
    });

    test('hide is admin-only', () {
      expect(ReviewWrite.canUpdate(UserRole.admin), isTrue);
      expect(ReviewWrite.adminHidePatch(), {'is_hidden': true});
      expect(ReviewWrite.hiddenColumn, 'is_hidden');
    });
  });

  group('ReviewPayload write guard', () {
    test('toJson is insert-only and has no is_hidden', () {
      const payload = ReviewPayload(
        vendorId: 'v1',
        consumerId: 'c1',
        bookingRequestId: 'b1',
        rating: 5,
        comment: 'Beautiful hall',
      );
      final json = payload.toJson();
      expect(json.containsKey('is_hidden'), isFalse);
      expect(json['rating'], 5);
    });

    test('toInsertJson never sends is_hidden', () {
      const review = Review(
        id: 'r1',
        vendorId: 'v1',
        consumerId: 'c1',
        bookingRequestId: 'b1',
        rating: 4,
        isHidden: true,
      );
      final json = review.toInsertJson();
      expect(json.containsKey('is_hidden'), isFalse);
    });
  });
}
