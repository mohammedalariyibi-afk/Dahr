import '../models/enums.dart';

/// Fail-closed review writes. Matches live Dahr LY:
///
/// * **Consumer** — INSERT only. Payload must not set `is_hidden`.
/// * **Admin** — hide via `{is_hidden: true}` only. Flutter has no hide UI.
abstract final class ReviewWrite {
  static const String hiddenColumn = 'is_hidden';

  static bool canInsert(UserRole actor) =>
      actor == UserRole.consumer || actor == UserRole.admin;

  /// Consumers never UPDATE reviews (`is_hidden` is admin-only).
  static bool canUpdate(UserRole actor) => actor == UserRole.admin;

  static bool touchesHidden(Map<String, dynamic> payload) =>
      payload.containsKey(hiddenColumn);

  /// Leave-review insert body. Throws if [hiddenColumn] is present.
  static Map<String, dynamic> consumerInsert(Map<String, dynamic> payload) {
    if (touchesHidden(payload)) {
      throw StateError('write_rejected');
    }
    return payload;
  }

  /// Any consumer UPDATE (including hide) is rejected.
  static Map<String, dynamic> consumerUpdate([
    Map<String, dynamic>? _,
  ]) {
    throw StateError('write_rejected');
  }

  /// Admin hide patch — the only review UPDATE the clients may send.
  static Map<String, dynamic> adminHidePatch() => {hiddenColumn: true};
}
