/** Admin audit trail. Mirrors the allowlists in
 * `supabase/migrations/20260904000000_admin_audit_log_and_atomic_moderation.sql`.
 *
 * `admin_audit_log` has no client INSERT policy: every write goes through the
 * `log_admin_action` RPC, and UPDATE / DELETE are rejected by trigger.
 */

export const LOG_ADMIN_ACTION_RPC = "log_admin_action";

export const AUDIT_ACTIONS = [
  "vendor_approved",
  "vendor_revoked",
  "vendor_verified",
  "vendor_unverified",
  "review_hidden",
  "report_dismissed",
  "report_actioned",
  "commission_paid",
  "commission_waived",
] as const;

export const AUDIT_TARGETS = [
  "vendor",
  "review",
  "report",
  "booking",
] as const;

export type AuditAction = (typeof AUDIT_ACTIONS)[number];
export type AuditTarget = (typeof AUDIT_TARGETS)[number];

export type AuditEntry = {
  action: AuditAction;
  targetType: AuditTarget;
  targetId: string;
  detail?: Record<string, unknown>;
};

export type LogAdminActionArgs = {
  p_action: string;
  p_target_type: string;
  p_target_id: string;
  p_detail: Record<string, unknown>;
};

/** Rejects anything the SQL allowlist would also reject. */
export function auditRpcArgs(entry: AuditEntry): LogAdminActionArgs {
  if (!(AUDIT_ACTIONS as readonly string[]).includes(entry.action)) {
    throw new Error("unknown_audit_action");
  }
  if (!(AUDIT_TARGETS as readonly string[]).includes(entry.targetType)) {
    throw new Error("unknown_audit_target");
  }
  return {
    p_action: entry.action,
    p_target_type: entry.targetType,
    p_target_id: entry.targetId,
    p_detail: entry.detail ?? {},
  };
}

export function vendorApprovalAction(approved: boolean): AuditAction {
  return approved ? "vendor_approved" : "vendor_revoked";
}

export function vendorVerificationAction(verified: boolean): AuditAction {
  return verified ? "vendor_verified" : "vendor_unverified";
}

export function reportStatusAction(
  status: "dismissed" | "actioned",
): AuditAction {
  return status === "dismissed" ? "report_dismissed" : "report_actioned";
}

export function commissionAction(status: "paid" | "waived"): AuditAction {
  return status === "paid" ? "commission_paid" : "commission_waived";
}
