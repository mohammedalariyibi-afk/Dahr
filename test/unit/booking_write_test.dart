import 'package:flutter_test/flutter_test.dart';
import 'package:dahr/core/models/booking.dart';
import 'package:dahr/core/models/enums.dart';
import 'package:dahr/core/security/booking_write.dart';

Matcher _writeRejected() => isA<StateError>().having(
      (e) => e.message,
      'message',
      'write_rejected',
    );

void main() {
  group('BookingStatusWrite', () {
    test('couples cannot UPDATE bookings at all', () {
      expect(BookingStatusWrite.consumerMayUpdate, isFalse);
      expect(BookingStatusWrite.consumerMayCancel, isFalse);
      expect(BookingStatusWrite.canUpdate(actor: UserRole.consumer), isFalse);
      for (final status in BookingStatus.values) {
        expect(
          BookingStatusWrite.canUpdateStatus(
            actor: UserRole.consumer,
            status: status,
          ),
          isFalse,
        );
        expect(
          () => BookingStatusWrite.consumerStatusPatch(status),
          throwsA(_writeRejected()),
        );
      }
      expect(
        () => BookingStatusWrite.consumerUpdate({'status': 'declined'}),
        throwsA(_writeRejected()),
      );
      expect(
        () => BookingStatusWrite.consumerUpdate({'message': 'cancel please'}),
        throwsA(_writeRejected()),
      );
    });

    test('consumer insert is pending only', () {
      expect(
        BookingStatusWrite.canInsert(
          actor: UserRole.consumer,
          status: BookingStatus.pending,
        ),
        isTrue,
      );
      expect(
        BookingStatusWrite.consumerInsert({'status': 'pending'})['status'],
        'pending',
      );
      for (final status in [
        BookingStatus.accepted,
        BookingStatus.declined,
        BookingStatus.completed,
      ]) {
        expect(
          BookingStatusWrite.canInsert(
            actor: UserRole.consumer,
            status: status,
          ),
          isFalse,
        );
        expect(
          () => BookingStatusWrite.consumerInsert({'status': status.name}),
          throwsA(_writeRejected()),
        );
      }
    });

    test('vendor may decline or complete, not accept via row update', () {
      expect(BookingStatusWrite.canUpdate(actor: UserRole.vendor), isTrue);
      expect(
        BookingStatusWrite.vendorDirectPatch(BookingStatus.declined),
        {'status': 'declined'},
      );
      expect(
        BookingStatusWrite.vendorDirectPatch(BookingStatus.completed),
        {'status': 'completed'},
      );
      expect(
        () => BookingStatusWrite.vendorDirectPatch(BookingStatus.accepted),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            'quoted_amount_required',
          ),
        ),
      );
      expect(
        () => BookingStatusWrite.vendorDirectPatch(BookingStatus.pending),
        throwsA(_writeRejected()),
      );
    });

    test('admin may moderate any status', () {
      expect(BookingStatusWrite.canUpdate(actor: UserRole.admin), isTrue);
      for (final status in BookingStatus.values) {
        expect(
          BookingStatusWrite.adminModeratePatch(status),
          {'status': status.name},
        );
      }
    });

    test('accept stays on the quoted RPC name', () {
      expect(BookingStatusWrite.acceptRpcName, 'accept_booking_request');
    });
  });

  group('BookingRequestPayload write guard', () {
    test('toJson stays pending and never accepted', () {
      final json = BookingRequestPayload(
        vendorId: 'v1',
        consumerId: 'c1',
        eventDate: DateTime(2030, 6, 15),
      ).toJson();
      expect(json['status'], 'pending');
      expect(json.containsKey('quoted_amount_lyd'), isFalse);
    });

    test('toInsertJson rejects a couple skipping vendor accept', () {
      final accepted = BookingRequest.fromJson({
        'id': 'b1',
        'vendor_id': 'v1',
        'consumer_id': 'c1',
        'event_date': '2030-06-15',
        'status': 'accepted',
      });
      expect(
        () => accepted.toInsertJson(),
        throwsA(_writeRejected()),
      );
    });
  });
}
