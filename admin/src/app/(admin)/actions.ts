"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import {
  AuditEntry,
  LOG_ADMIN_ACTION_RPC,
  auditRpcArgs,
  commissionAction,
  reportStatusAction,
  vendorApprovalAction,
  vendorVerificationAction,
} from "@/lib/audit-log";
import { PUBLIC_ERROR } from "@/lib/public-error";
import {
  HIDE_REVIEW_RPC,
  RPC_MISSING_CODE,
  adminHideReviewPatch,
} from "@/lib/review-write";
import { createClient } from "@/lib/supabase/server";

type AdminClient = Awaited<ReturnType<typeof createClient>>;

async function requireAdmin() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) redirect("/login");

  const { data: profile } = await supabase
    .from("profiles")
    .select("role")
    .eq("id", user.id)
    .maybeSingle();

  if (!profile || profile.role !== "admin") {
    redirect(`/login?error=${PUBLIC_ERROR.forbidden}`);
  }

  return supabase;
}

function fail(path: string, code: string = PUBLIC_ERROR.writeFailed): never {
  const sep = path.includes("?") ? "&" : "?";
  redirect(`${path}${sep}error=${encodeURIComponent(code)}`);
}

/**
 * The decision itself has already been committed, so a missing audit row must
 * not undo it or block the operator — the log is still append-only in SQL.
 */
async function logAdminAction(supabase: AdminClient, entry: AuditEntry) {
  try {
    await supabase.rpc(LOG_ADMIN_ACTION_RPC, auditRpcArgs(entry));
  } catch {
    // Ignored on purpose (see above).
  }
}

export async function signOut() {
  const supabase = await createClient();
  await supabase.auth.signOut();
  redirect("/login");
}

export async function setVendorApproved(vendorId: string, approved: boolean) {
  const supabase = await requireAdmin();
  const { data, error } = await supabase
    .from("vendor_profiles")
    .update({ is_approved: approved })
    .eq("id", vendorId)
    .select("id");
  if (error || !data?.length) fail("/vendors");
  await logAdminAction(supabase, {
    action: vendorApprovalAction(approved),
    targetType: "vendor",
    targetId: vendorId,
  });
  revalidatePath("/vendors");
  revalidatePath("/");
}

export async function toggleVendorVerified(vendorId: string, verified: boolean) {
  const supabase = await requireAdmin();
  const { data, error } = await supabase
    .from("vendor_profiles")
    .update({ is_verified: verified })
    .eq("id", vendorId)
    .select("id");
  if (error || !data?.length) fail("/vendors");
  await logAdminAction(supabase, {
    action: vendorVerificationAction(verified),
    targetType: "vendor",
    targetId: vendorId,
  });
  revalidatePath("/vendors");
  revalidatePath("/");
}

export async function updateReportStatus(
  reportId: string,
  status: "dismissed" | "actioned",
) {
  const supabase = await requireAdmin();
  const { data, error } = await supabase
    .from("reports")
    .update({ status })
    .eq("id", reportId)
    .select("id");
  if (error || !data?.length) fail("/reports");
  await logAdminAction(supabase, {
    action: reportStatusAction(status),
    targetType: "report",
    targetId: reportId,
  });
  revalidatePath("/reports");
  revalidatePath("/");
}

export async function hideReview(reviewId: string, reportId?: string) {
  const supabase = await requireAdmin();

  // One transaction, so a hidden review can never be left on an open report.
  const { error: rpcError } = await supabase.rpc(HIDE_REVIEW_RPC, {
    p_review_id: reviewId,
    p_report_id: reportId ?? null,
  });

  if (rpcError && rpcError.code !== RPC_MISSING_CODE) fail("/reports");

  // Dahr LY has not been migrated yet: fall back to the two sequential writes.
  if (rpcError) {
    const { data, error } = await supabase
      .from("reviews")
      .update(adminHideReviewPatch())
      .eq("id", reviewId)
      .select("id");
    if (error || !data?.length) fail("/reports");

    await logAdminAction(supabase, {
      action: "review_hidden",
      targetType: "review",
      targetId: reviewId,
      detail: { report_id: reportId ?? null },
    });

    if (reportId) {
      const { data: reportRow, error: reportError } = await supabase
        .from("reports")
        .update({ status: "actioned" })
        .eq("id", reportId)
        .select("id");
      if (reportError || !reportRow?.length) fail("/reports");
      await logAdminAction(supabase, {
        action: "report_actioned",
        targetType: "report",
        targetId: reportId,
        detail: { review_id: reviewId },
      });
    }
  }

  revalidatePath("/reports");
  revalidatePath("/");
}

export async function setCommissionStatus(
  bookingId: string,
  status: "paid" | "waived",
) {
  const supabase = await requireAdmin();
  const { error } = await supabase.rpc("set_booking_commission_status", {
    p_booking_id: bookingId,
    p_status: status,
  });
  if (error) fail("/commissions");
  await logAdminAction(supabase, {
    action: commissionAction(status),
    targetType: "booking",
    targetId: bookingId,
  });
  revalidatePath("/commissions");
  revalidatePath("/");
}

export async function updatePlatformBankDetails(formData: FormData) {
  const supabase = await requireAdmin();
  const bankName = String(formData.get("bank_name") ?? "").trim();
  const accountHolder = String(formData.get("account_holder") ?? "").trim();
  const accountNumber = String(formData.get("account_number") ?? "").trim();
  const bankNote = String(formData.get("bank_note") ?? "").trim();

  const { data, error } = await supabase
    .from("platform_settings")
    .update({
      bank_name: bankName,
      account_holder: accountHolder,
      account_number: accountNumber,
      bank_note: bankNote,
      updated_at: new Date().toISOString(),
    })
    .eq("id", "default")
    .select("id");

  if (error || !data?.length) fail("/settings");
  revalidatePath("/settings");
  revalidatePath("/commissions");
}
