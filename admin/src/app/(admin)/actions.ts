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
  if (error) throw new Error(error.message);
  revalidatePath("/vendors");
  revalidatePath("/");
}

export async function toggleVendorVerified(vendorId: string, verified: boolean) {
  const supabase = await requireAdmin();
  const { error } = await supabase
    .from("vendor_profiles")
    .update({ is_verified: verified })
    .eq("id", vendorId);
  if (error) throw new Error(error.message);
  revalidatePath("/vendors");
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
  if (error) throw new Error(error.message);
  revalidatePath("/reports");
}

export async function hideReview(reviewId: string) {
  const supabase = await requireAdmin();
  const { error } = await supabase
    .from("reviews")
    .update({ is_hidden: true })
    .eq("id", reviewId);
  if (error) throw new Error(error.message);
  revalidatePath("/reports");
}
