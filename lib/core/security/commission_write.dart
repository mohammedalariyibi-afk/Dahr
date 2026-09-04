import '../models/enums.dart';

/// Fail-closed writes around the 10% Dahr platform fee.
///
/// Couples may INSERT a transfer reference on [notesTable]. They must not
/// UPDATE `booking_requests` or set [CommissionStatus.paid] / waived.
abstract final class CommissionTransferWrite {
  static const String notesTable = 'commission_transfer_notes';
  static const String settingsTable = 'platform_settings';
  static const String setStatusRpc = 'set_booking_commission_status';

  static const int maxNoteLength = 500;

  /// Live product: only admin RPC marks the fee paid/waived.
  static const bool consumerMaySetCommissionPaid = false;
  static const bool consumerMayUpdateBooking = false;

  static Map<String, dynamic> consumerInsert({
    required String bookingId,
    required String consumerId,
    required String referenceNote,
  }) {
    if (bookingId.isEmpty || consumerId.isEmpty) {
      throw StateError('write_rejected');
    }
    final note = referenceNote.trim();
    if (note.isEmpty || note.length > maxNoteLength) {
      throw StateError('transfer_note_invalid');
    }
    return {
      'booking_id': bookingId,
      'consumer_id': consumerId,
      'reference_note': note,
    };
  }

  /// Couples never UPDATE transfer notes or bookings.
  static Map<String, dynamic> consumerUpdate([
    Map<String, dynamic>? _,
  ]) {
    throw StateError('write_rejected');
  }

  /// Couples cannot patch [commission_status], including to paid.
  static Map<String, dynamic> consumerCommissionStatusPatch(
    CommissionStatus status,
  ) {
    throw StateError('write_rejected');
  }

  static bool insertContainsMoneyStatus(Map<String, dynamic> json) {
    return json.containsKey('commission_status') ||
        json.containsKey('commission_paid_at') ||
        json.containsKey('commission_amount_lyd');
  }
}
