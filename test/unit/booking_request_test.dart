import 'package:flutter_test/flutter_test.dart';
import 'package:dahr/core/models/booking.dart';

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
}
