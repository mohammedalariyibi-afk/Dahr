import '../models/enums.dart';

/// Fail-closed booking writes. Matches live Dahr LY:
///
/// * **Consumer** — INSERT a pending request only. No `.update()` at all
///   (cancel is not a product path).
/// * **Vendor / admin** — may UPDATE. Vendor accept-with-quote stays on
///   [acceptRpcName]; decline / complete are direct status patches.
abstract final class BookingStatusWrite {
  static const String acceptRpcName = 'accept_booking_request';

  static const Set<BookingStatus> vendorDirectStatuses = {
    BookingStatus.declined,
    BookingStatus.completed,
  };

  /// Live RLS: couples cannot UPDATE `booking_requests`.
  static const bool consumerMayUpdate = false;

  /// Cancel was never a couple write. Do not add a consumer `.update()`.
  static const bool consumerMayCancel = false;

  static bool canInsert({
    required UserRole actor,
    required BookingStatus status,
  }) {
    if (actor == UserRole.consumer) {
      return status == BookingStatus.pending;
    }
    if (actor == UserRole.admin) return true;
    return false;
  }

  /// Any booking row UPDATE. Couples: never.
  static bool canUpdate({required UserRole actor}) {
    switch (actor) {
      case UserRole.consumer:
        return false;
      case UserRole.vendor:
      case UserRole.admin:
        return true;
    }
  }

  static bool canUpdateStatus({
    required UserRole actor,
    required BookingStatus status,
  }) {
    if (!canUpdate(actor: actor)) return false;
    switch (actor) {
      case UserRole.consumer:
        return false;
      case UserRole.vendor:
        return vendorDirectStatuses.contains(status);
      case UserRole.admin:
        return true;
    }
  }

  /// Consumer insert body. Rejects accepted/completed (or any non-pending).
  static Map<String, dynamic> consumerInsert(Map<String, dynamic> json) {
    final status = BookingStatus.fromString(json['status'] as String?);
    if (!canInsert(actor: UserRole.consumer, status: status)) {
      throw StateError('write_rejected');
    }
    return json;
  }

  /// Any couple UPDATE (status, cancel, quote, message) is rejected.
  static Map<String, dynamic> consumerUpdate([
    Map<String, dynamic>? _,
  ]) {
    throw StateError('write_rejected');
  }

  /// Status-only patch. Couples never get a map; vendors cannot accept here.
  static Map<String, dynamic> statusPatch({
    required UserRole actor,
    required BookingStatus status,
  }) {
    if (actor == UserRole.vendor && status == BookingStatus.accepted) {
      throw StateError('quoted_amount_required');
    }
    if (!canUpdateStatus(actor: actor, status: status)) {
      throw StateError('write_rejected');
    }
    return {'status': status.name};
  }

  static Map<String, dynamic> vendorDirectPatch(BookingStatus status) =>
      statusPatch(actor: UserRole.vendor, status: status);

  static Map<String, dynamic> adminModeratePatch(BookingStatus status) =>
      statusPatch(actor: UserRole.admin, status: status);

  static Map<String, dynamic> consumerStatusPatch(BookingStatus status) =>
      consumerUpdate({'status': status.name});
}
