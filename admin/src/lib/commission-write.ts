/** Fail-closed commission writes. Mirrors Flutter `CommissionTransferWrite`. */

export const COMMISSION_TRANSFER_NOTES_TABLE = "commission_transfer_notes";
export const PLATFORM_SETTINGS_TABLE = "platform_settings";
export const SET_COMMISSION_STATUS_RPC = "set_booking_commission_status";

export const CONSUMER_MAY_SET_COMMISSION_PAID = false;
export const CONSUMER_MAY_UPDATE_BOOKING = false;
export const MAX_TRANSFER_NOTE_LENGTH = 500;

export function consumerTransferNoteInsert(input: {
  bookingId: string;
  consumerId: string;
  referenceNote: string;
}): {
  booking_id: string;
  consumer_id: string;
  reference_note: string;
} {
  const note = input.referenceNote.trim();
  if (!input.bookingId || !input.consumerId) {
    throw new Error("write_rejected");
  }
  if (!note || note.length > MAX_TRANSFER_NOTE_LENGTH) {
    throw new Error("transfer_note_invalid");
  }
  return {
    booking_id: input.bookingId,
    consumer_id: input.consumerId,
    reference_note: note,
  };
}

export function consumerCommissionStatusPatch(): never {
  throw new Error("write_rejected");
}

export function consumerBookingCommissionUpdate(): never {
  throw new Error("write_rejected");
}
