import 'package:flutter_test/flutter_test.dart';
import 'package:dahr/core/models/booking.dart';
import 'package:dahr/core/models/enums.dart';

void main() {
  group('BookingRequestPayload', () {
    test('maps to insert json with pending status', () {
      final payload = BookingRequestPayload(
        vendorId: 'v1',
        consumerId: 'c1',
        eventDate: DateTime(2030, 6, 15),
        guestCount: 120,
        message: 'Hello',
      );
      final json = payload.toJson();
      expect(json['vendor_id'], 'v1');
      expect(json['consumer_id'], 'c1');
      expect(json['event_date'], '2030-06-15');
      expect(json['guest_count'], 120);
      expect(json['message'], 'Hello');
      expect(json['status'], 'pending');
    });

    test('validate rejects past dates and empty ids', () {
      final past = BookingRequestPayload(
        vendorId: 'v1',
        consumerId: 'c1',
        eventDate: DateTime(2020, 1, 1),
      );
      expect(past.validate(), 'event_date_past');

      final missingVendor = BookingRequestPayload(
        vendorId: '',
        consumerId: 'c1',
        eventDate: DateTime.now().add(const Duration(days: 10)),
      );
      expect(missingVendor.validate(), 'vendor_required');

      final badGuests = BookingRequestPayload(
        vendorId: 'v1',
        consumerId: 'c1',
        eventDate: DateTime.now().add(const Duration(days: 10)),
        guestCount: 0,
      );
      expect(badGuests.validate(), 'guest_count_invalid');

      final hugeGuests = BookingRequestPayload(
        vendorId: 'v1',
        consumerId: 'c1',
        eventDate: DateTime.now().add(const Duration(days: 10)),
        guestCount: 10001,
      );
      expect(hugeGuests.validate(), 'guest_count_invalid');
    });

    test('validate rejects a date the vendor marked booked', () {
      final payload = BookingRequestPayload(
        vendorId: 'v1',
        consumerId: 'c1',
        eventDate: DateTime(2030, 6, 15),
      );
      expect(
        payload.validate(bookedDateKeys: {'2030-06-15'}),
        'event_date_booked',
      );
      expect(
        payload.validate(bookedDateKeys: {'2030-06-16'}),
        isNull,
      );
    });

    test('validate rejects empty consumer and overly long messages', () {
      final missingConsumer = BookingRequestPayload(
        vendorId: 'v1',
        consumerId: '',
        eventDate: DateTime.now().add(const Duration(days: 10)),
      );
      expect(missingConsumer.validate(), 'consumer_required');

      final longMessage = BookingRequestPayload(
        vendorId: 'v1',
        consumerId: 'c1',
        eventDate: DateTime.now().add(const Duration(days: 10)),
        message: 'x' * 2001,
      );
      expect(longMessage.validate(), 'message_too_long');
    });

    test('validate allows today and requires create payload to stay pending',
        () {
      final now = DateTime.now();
      final today = BookingRequestPayload(
        vendorId: 'v1',
        consumerId: 'c1',
        eventDate: DateTime(now.year, now.month, now.day),
        guestCount: 80,
        message: 'Please hold this date',
      );
      expect(today.validate(), isNull);
      expect(today.toJson()['status'], 'pending');
      expect(today.toJson().containsKey('quoted_amount_lyd'), isFalse);
    });

    test('validate accepts future booking', () {
      final ok = BookingRequestPayload(
        vendorId: 'v1',
        consumerId: 'c1',
        eventDate: DateTime.now().add(const Duration(days: 30)),
        guestCount: 50,
      );
      expect(ok.validate(), isNull);
    });
  });

  group('BookingDateConflict', () {
    test('matches client validation key and live trigger exception', () {
      expect(BookingDateConflict.clientKey, 'event_date_booked');
      expect(BookingDateConflict.dbException, 'date_unavailable');
      expect(BookingDateConflict.matches(StateError('event_date_booked')), isTrue);
      expect(
        BookingDateConflict.matches(
          Exception('PostgrestException(message: date_unavailable, code: P0001)'),
        ),
        isTrue,
      );
      expect(
        BookingDateConflict.matches(StateError('date_has_accepted_booking')),
        isTrue,
      );
      expect(BookingDateConflict.matches(StateError('event_date_past')), isFalse);
      expect(BookingDateConflict.matches('quoted_amount_required'), isFalse);
    });
  });

  group('AcceptBookingPayload', () {
    test('requires a quote greater than zero', () {
      expect(
        const AcceptBookingPayload(bookingId: 'b1', quotedAmountLyd: 0)
            .validate(),
        'quoted_amount_required',
      );
      expect(
        const AcceptBookingPayload(bookingId: 'b1', quotedAmountLyd: -10)
            .validate(),
        'quoted_amount_required',
      );
      expect(
        const AcceptBookingPayload(
          bookingId: 'b1',
          quotedAmountLyd: double.nan,
        ).validate(),
        'quoted_amount_required',
      );
      expect(
        const AcceptBookingPayload(bookingId: '', quotedAmountLyd: 100)
            .validate(),
        'booking_required',
      );
    });

    test('accepts a positive quote and exposes 10% commission', () {
      const payload = AcceptBookingPayload(
        bookingId: 'b1',
        quotedAmountLyd: 2500,
      );
      expect(payload.validate(), isNull);
      expect(payload.commissionAmountLyd, 250.0);
      expect(payload.toRpcParams()['p_booking_id'], 'b1');
      expect(payload.toRpcParams()['p_quoted_amount_lyd'], 2500);
    });

    test('fromInput rejects blank and non-numeric quotes', () {
      expect(
        AcceptBookingPayload.fromInput(
          bookingId: 'b1',
          quotedAmountRaw: '',
        ).validate(),
        'quoted_amount_required',
      );
      expect(
        AcceptBookingPayload.fromInput(
          bookingId: 'b1',
          quotedAmountRaw: 'abc',
        ).validate(),
        'quoted_amount_required',
      );
      expect(
        AcceptBookingPayload.fromInput(
          bookingId: 'b1',
          quotedAmountRaw: '1250,50',
        ).validate(),
        isNull,
      );
      expect(
        AcceptBookingPayload.fromInput(
          bookingId: 'b1',
          quotedAmountRaw: '1,250.50',
        ).quotedAmountLyd,
        1250.50,
      );
    });

    test('status update path cannot accept without a quote', () {
      expect(
        () => AcceptBookingPayload.assertNotBareAccept(BookingStatus.accepted),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            'quoted_amount_required',
          ),
        ),
      );
      expect(
        () => AcceptBookingPayload.assertNotBareAccept(BookingStatus.declined),
        returnsNormally,
      );
      expect(
        () => AcceptBookingPayload.assertNotBareAccept(BookingStatus.completed),
        returnsNormally,
      );
    });
  });

  group('BookingRequest commission json', () {
    test('reads quote and unpaid commission after accept', () {
      final booking = BookingRequest.fromJson({
        'id': 'b1',
        'vendor_id': 'v1',
        'consumer_id': 'c1',
        'event_date': '2030-06-15',
        'status': 'accepted',
        'quoted_amount_lyd': '4500.00',
        'commission_rate': '0.1000',
        'commission_amount_lyd': '450.00',
        'commission_status': 'unpaid',
      });
      expect(booking.status, BookingStatus.accepted);
      expect(booking.quotedAmountLyd, 4500);
      expect(booking.commissionAmountLyd, 450);
      expect(booking.commissionStatus, CommissionStatus.unpaid);
      expect(booking.isCommissionUnpaid, isTrue);
      expect(booking.showsCouplePlatformFee, isTrue);
    });

    test('quoted guest_count parses instead of throwing', () {
      final booking = BookingRequest.fromJson({
        'id': 'b1',
        'vendor_id': 'v1',
        'consumer_id': 'c1',
        'event_date': '2030-06-15',
        'status': 'pending',
        'guest_count': '120',
      });
      expect(booking.guestCount, 120);
    });

    test('quoted review rating on an embed does not throw', () {
      final booking = BookingRequest.fromJson({
        'id': 'b1',
        'vendor_id': 'v1',
        'consumer_id': 'c1',
        'event_date': '2030-06-15',
        'status': 'completed',
        'reviews': {
          'id': 'r1',
          'vendor_id': 'v1',
          'consumer_id': 'c1',
          'booking_request_id': 'b1',
          'rating': '5',
        },
      });
      expect(booking.review?.rating, 5);
      expect(booking.canLeaveReview, isFalse);
    });

    test('pending booking has no quote or commission', () {
      final booking = BookingRequest.fromJson({
        'id': 'b1',
        'vendor_id': 'v1',
        'consumer_id': 'c1',
        'event_date': '2030-06-15',
        'status': 'pending',
      });
      expect(booking.quotedAmountLyd, isNull);
      expect(booking.commissionStatus, isNull);
      expect(booking.isCommissionUnpaid, isFalse);
      expect(booking.canLeaveReview, isFalse);
    });

    test('completed booking without a review can be reviewed', () {
      final booking = BookingRequest.fromJson({
        'id': 'b1',
        'vendor_id': 'v1',
        'consumer_id': 'c1',
        'event_date': '2030-06-15',
        'status': 'completed',
        'quoted_amount_lyd': '1000.00',
        'commission_rate': '0.1000',
        'commission_amount_lyd': '100.00',
        'commission_status': 'unpaid',
      });
      expect(booking.canLeaveReview, isTrue);
    });

    test('completed booking with a review cannot be reviewed again', () {
      final booking = BookingRequest.fromJson({
        'id': 'b1',
        'vendor_id': 'v1',
        'consumer_id': 'c1',
        'event_date': '2030-06-15',
        'status': 'completed',
        'reviews': {
          'id': 'r1',
          'vendor_id': 'v1',
          'consumer_id': 'c1',
          'booking_request_id': 'b1',
          'rating': 5,
        },
      });
      expect(booking.review, isNotNull);
      expect(booking.canLeaveReview, isFalse);
    });

    test('review embed is read whatever Map type the client decodes', () {
      // Regression: only Map<String, dynamic> was parsed, so a plain Map left
      // review null and re-offered the review to a couple who already left one.
      for (final embed in <Map>[
        <String, dynamic>{
          'id': 'r1',
          'vendor_id': 'v1',
          'consumer_id': 'c1',
          'booking_request_id': 'b1',
          'rating': 5,
        },
        <dynamic, dynamic>{
          'id': 'r1',
          'vendor_id': 'v1',
          'consumer_id': 'c1',
          'booking_request_id': 'b1',
          'rating': 5,
        },
      ]) {
        final booking = BookingRequest.fromJson({
          'id': 'b1',
          'vendor_id': 'v1',
          'consumer_id': 'c1',
          'event_date': '2030-06-15',
          'status': 'completed',
          'reviews': embed,
        });
        expect(booking.review, isNotNull, reason: '${embed.runtimeType}');
        expect(booking.canLeaveReview, isFalse, reason: '${embed.runtimeType}');
      }
    });
  });
}
