/** Fail-closed review writes. Mirrors Flutter `ReviewWrite`. Live Dahr LY:
 * reviews are insert-only; `is_hidden` is admin-only.
 */

export const REVIEW_HIDDEN_COLUMN = "is_hidden";

export function touchesHidden(
  payload: Record<string, unknown>,
): boolean {
  return Object.prototype.hasOwnProperty.call(payload, REVIEW_HIDDEN_COLUMN);
}

/** Leave-review insert body. Consumers must not send `is_hidden`. */
export function consumerReviewInsert<T extends Record<string, unknown>>(
  payload: T,
): T {
  if (touchesHidden(payload)) {
    throw new Error("write_rejected");
  }
  return payload;
}

/** Consumers never UPDATE reviews, including hide. */
export function consumerReviewUpdate(): never {
  throw new Error("write_rejected");
}

/** Admin hide patch — the only review UPDATE this dashboard may send. */
export function adminHideReviewPatch(): { is_hidden: true } {
  return { is_hidden: true };
}
