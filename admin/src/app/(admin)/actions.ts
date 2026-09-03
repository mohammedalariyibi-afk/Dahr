"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
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
    redirect("/login?error=forbidden");
  }

  return supabase;
}

function fail(path: string, message: string): never {
  const sep = path.includes("?") ? "&" : "?";
  redirect(`${path}${sep}error=${encodeURIComponent(message)}`);
}

export async function signOut() {
  const supabase = await createClient();
  await supabase.auth.signOut();
  redirect("/login");
}

export async function setVendorApproved(vendorId: string, approved: boolean) {
  const supabase = await requireAdmin();
  const { error } = await supabase
    .from("vendor_profiles")
    .update({ is_approved: approved })
    .eq("id", vendorId);
  if (error) fail("/vendors", error.message);
  revalidatePath("/vendors");
  revalidatePath("/");
}

export async function toggleVendorVerified(vendorId: string, verified: boolean) {
  const supabase = await requireAdmin();
  const { error } = await supabase
    .from("vendor_profiles")
    .update({ is_verified: verified })
    .eq("id", vendorId);
  if (error) fail("/vendors", error.message);
  revalidatePath("/vendors");
  revalidatePath("/");
}

export async function updateReportStatus(
  reportId: string,
  status: "dismissed" | "actioned",
) {
  const supabase = await requireAdmin();
  const { error } = await supabase
    .from("reports")
    .update({ status })
    .eq("id", reportId);
  if (error) fail("/reports", error.message);
  revalidatePath("/reports");
  revalidatePath("/");
}

export async function hideReview(reviewId: string, reportId?: string) {
  const supabase = await requireAdmin();
  const { error } = await supabase
    .from("reviews")
    .update({ is_hidden: true })
    .eq("id", reviewId);
  if (error) fail("/reports", error.message);

  if (reportId) {
    const { error: reportError } = await supabase
      .from("reports")
      .update({ status: "actioned" })
      .eq("id", reportId);
    if (reportError) fail("/reports", reportError.message);
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
  if (error) fail("/commissions", error.message);
  revalidatePath("/commissions");
  revalidatePath("/");
}
