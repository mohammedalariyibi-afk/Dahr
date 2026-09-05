import 'package:flutter_test/flutter_test.dart';
import 'package:dahr/core/models/review.dart';

Map<String, dynamic> _row(Object? rating) => {
      'id': 'r1',
      'vendor_id': 'v1',
      'consumer_id': 'c1',
      'booking_request_id': 'b1',
      'rating': rating,
    };

void main() {
  group('Review.fromJson rating', () {
    test('quoted NUMERIC does not throw', () {
      final review = Review.fromJson(_row('4'));
      expect(review.rating, 4);
    });

    test('numeric rating still parses', () {
      expect(Review.fromJson(_row(5)).rating, 5);
      expect(Review.fromJson(_row(3.0)).rating, 3);
    });

    test('null and junk fall back instead of throwing', () {
      expect(Review.fromJson(_row(null)).rating, 0);
      expect(Review.fromJson(_row('nope')).rating, 0);
    });
  });
}
