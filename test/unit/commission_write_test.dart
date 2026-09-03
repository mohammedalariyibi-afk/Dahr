import 'package:flutter_test/flutter_test.dart';
import 'package:dahr/core/models/enums.dart';
import 'package:dahr/core/security/booking_write.dart';
import 'package:dahr/core/security/commission_write.dart';

void main() {
  group('CommissionTransferWrite', () {
    test('couple insert is a note only — no commission_status', () {
      final json = CommissionTransferWrite.consumerInsert(
        bookingId: 'b1',
        consumerId: 'c1',
        referenceNote: '  Ref 123  ',
      );
      expect(json, {
        'booking_id': 'b1',
        'consumer_id': 'c1',
        'reference_note': 'Ref 123',
      });
      expect(CommissionTransferWrite.insertContainsMoneyStatus(json), isFalse);
      expect(json.containsKey('commission_status'), isFalse);
      expect(CommissionTransferWrite.consumerMaySetCommissionPaid, isFalse);
    });

    test('rejects empty or oversized notes', () {
      expect(
        () => CommissionTransferWrite.consumerInsert(
          bookingId: 'b1',
          consumerId: 'c1',
          referenceNote: '   ',
        ),
        throwsA(isA<StateError>()),
      );
      expect(
        () => CommissionTransferWrite.consumerInsert(
          bookingId: 'b1',
          consumerId: 'c1',
          referenceNote: 'x' * 501,
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('couple cannot set commission_status to paid', () {
      expect(
        () => CommissionTransferWrite.consumerCommissionStatusPatch(
          CommissionStatus.paid,
        ),
        throwsA(
          isA<StateError>().having((e) => e.message, 'message', 'write_rejected'),
        ),
      );
      expect(
        () => CommissionTransferWrite.consumerCommissionStatusPatch(
          CommissionStatus.waived,
        ),
        throwsA(isA<StateError>()),
      );
      expect(
        () => CommissionTransferWrite.consumerUpdate({
          'commission_status': 'paid',
        }),
        throwsA(isA<StateError>()),
      );
      expect(
        () => BookingStatusWrite.consumerUpdate({
          'commission_status': 'paid',
        }),
        throwsA(isA<StateError>()),
      );
    });
  });
}
