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
    });
  });
}
