"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { PUBLIC_ERROR } from "@/lib/public-error";
import { adminHideReviewPatch } from "@/lib/review-write";
import { createClient } from "@/lib/supabase/server";

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
  revalidatePath("/reports");
  revalidatePath("/");
}

export async function hideReview(reviewId: string, reportId?: string) {
  const supabase = await requireAdmin();
  const { data, error } = await supabase
    .from("reviews")
    .update(adminHideReviewPatch())
    .eq("id", reviewId)
    .select("id");
  if (error || !data?.length) fail("/reports");

  if (reportId) {
    const { data: reportRow, error: reportError } = await supabase
      .from("reports")
      .update({ status: "actioned" })
      .eq("id", reportId)
      .select("id");
    if (reportError || !reportRow?.length) fail("/reports");
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
  revalidatePath("/commissions");
  revalidatePath("/");
}
