/** Fail-closed booking writes. Mirrors Flutter `BookingStatusWrite`. Live Dahr LY:
 * couples cannot UPDATE bookings at all. Vendor and admin still can.
 * Vendor accept-with-quote stays on `accept_booking_request`.
 */

export const BOOKING_STATUSES = [
  "pending",
  "accepted",
  "declined",
  "completed",
] as const;

export type BookingStatus = (typeof BOOKING_STATUSES)[number];
export type BookingWriteActor = "consumer" | "vendor" | "admin";

export const ACCEPT_BOOKING_RPC = "accept_booking_request";
export const VENDOR_DIRECT_STATUSES = ["declined", "completed"] as const;

/** Live RLS: couples cannot UPDATE `booking_requests`. */
export const CONSUMER_MAY_UPDATE = false;

/** Cancel is not a couple write. Do not add a consumer `.update()`. */
export const CONSUMER_MAY_CANCEL = false;

export function canInsertBooking(
  actor: BookingWriteActor,
  status: BookingStatus,
): boolean {
  if (actor === "consumer") return status === "pending";
  if (actor === "admin") return true;
  return false;
}

/** Any booking row UPDATE. Couples: never. */
export function canUpdateBooking(actor: BookingWriteActor): boolean {
  return actor === "vendor" || actor === "admin";
}

export function canUpdateBookingStatus(
  actor: BookingWriteActor,
  status: BookingStatus,
): boolean {
  if (!canUpdateBooking(actor)) return false;
  if (actor === "vendor") {
    return status === "declined" || status === "completed";
  }
  if (actor === "admin") return BOOKING_STATUSES.includes(status);
  return false;
}

export function consumerInsertStatus(status: BookingStatus): BookingStatus {
  if (!canInsertBooking("consumer", status)) {
    throw new Error("write_rejected");
  }
  return status;
}

/** Any couple UPDATE (status, cancel, quote, message) is rejected. */
export function consumerBookingUpdate(): never {
  throw new Error("write_rejected");
}

/**
 * Status-only patch. Couples never get a map. Vendor accept is the RPC, not
 * a row update. Admin may moderate any known status.
 */
export function bookingStatusPatch(
  actor: BookingWriteActor,
  status: BookingStatus,
): { status: BookingStatus } {
  if (actor === "consumer") {
    return consumerBookingUpdate();
  }
  if (actor === "vendor" && status === "accepted") {
    throw new Error("quoted_amount_required");
  }
  if (!canUpdateBookingStatus(actor, status)) {
    throw new Error("write_rejected");
  }
  return { status };
}

export function vendorDirectBookingPatch(status: BookingStatus) {
  return bookingStatusPatch("vendor", status);
}

export function adminModerateBookingPatch(status: BookingStatus) {
  return bookingStatusPatch("admin", status);
}
