import { hideReview, updateReportStatus } from "@/app/(admin)/actions";
import { ActionError } from "@/components/action-error";
import { ConfirmSubmitButton } from "@/components/confirm-submit-button";
import { FilterTabs } from "@/components/filter-tabs";
import { firstEmbed } from "@/lib/admin";
import { createClient } from "@/lib/supabase/server";
import Link from "next/link";

type ReportFilter = "open" | "actioned" | "dismissed" | "all";

type ProfileEmbed = { full_name: string | null; phone: string | null };

type ReportRow = {
  id: string;
  target_type: "vendor" | "review";
  target_id: string;
  reason: string;
  status: "open" | "dismissed" | "actioned";
  created_at: string;
  profiles: ProfileEmbed | ProfileEmbed[] | null;
};

export default async function ReportsPage({
  searchParams,
}: {
  searchParams: Promise<{ status?: string; error?: string }>;
}) {
  const params = await searchParams;
  const filter: ReportFilter =
    params.status === "actioned" ||
    params.status === "dismissed" ||
    params.status === "all"
      ? params.status
      : "open";

  const supabase = await createClient();
  let query = supabase
    .from("reports")
    .select(
      "id, target_type, target_id, reason, status, created_at, profiles!reports_reported_by_fkey(full_name, phone)",
    )
    .order("created_at", { ascending: false });

  if (filter !== "all") {
    query = query.eq("status", filter);
  }

  const { data: reports, error } = await query;

  if (error) {
    return (
      <p className="text-sm text-red-700">
        Failed to load reports: {error.message}
      </p>
    );
  }

  const rows = (reports ?? []) as ReportRow[];

  const [{ count: openCount }, { count: actionedCount }, { count: dismissedCount }] =
    await Promise.all([
      supabase
        .from("reports")
        .select("*", { count: "exact", head: true })
        .eq("status", "open"),
      supabase
        .from("reports")
        .select("*", { count: "exact", head: true })
        .eq("status", "actioned"),
      supabase
        .from("reports")
        .select("*", { count: "exact", head: true })
        .eq("status", "dismissed"),
    ]);

  const reviewIds = rows
    .filter((r) => r.target_type === "review")
    .map((r) => r.target_id);
  const vendorIdsFromReports = rows
    .filter((r) => r.target_type === "vendor")
    .map((r) => r.target_id);

  type ReviewInfo = {
    id: string;
    comment: string;
    rating: number;
    is_hidden: boolean;
    vendor_id: string;
  };
  type VendorInfo = { id: string; business_name: string; city: string };

  let reviewsById = new Map<string, ReviewInfo>();
  let vendorsById = new Map<string, VendorInfo>();

  if (reviewIds.length > 0) {
    const { data: reviews } = await supabase
      .from("reviews")
      .select("id, comment, rating, is_hidden, vendor_id")
      .in("id", reviewIds);
    reviewsById = new Map((reviews ?? []).map((r) => [r.id, r as ReviewInfo]));
  }

  const vendorIds = [
    ...vendorIdsFromReports,
    ...[...reviewsById.values()].map((r) => r.vendor_id),
  ];
  const uniqueVendorIds = [...new Set(vendorIds)];

  if (uniqueVendorIds.length > 0) {
    const { data: vendors } = await supabase
      .from("vendor_profiles")
      .select("id, business_name, city")
      .in("id", uniqueVendorIds);
    vendorsById = new Map(
      (vendors ?? []).map((v) => [v.id, v as VendorInfo]),
    );
  }

  const emptyCopy: Record<ReportFilter, string> = {
    open: "No open reports. Queue is clear.",
    actioned: "No actioned reports yet.",
    dismissed: "No dismissed reports yet.",
    all: "No reports yet.",
  };

  return (
    <div className="space-y-8">
      <div>
        <h1 className="font-display text-3xl text-[var(--ink)]">Reports</h1>
        <p className="mt-1 text-sm text-[var(--muted)]">
          Moderation queue — dismiss, mark actioned, or hide a reported review
        </p>
      </div>

      <ActionError message={params.error} />

      <FilterTabs
        items={[
          {
            href: "/reports",
            label: "Open",
            active: filter === "open",
            count: openCount ?? 0,
          },
          {
            href: "/reports?status=actioned",
            label: "Actioned",
            active: filter === "actioned",
            count: actionedCount ?? 0,
          },
          {
            href: "/reports?status=dismissed",
            label: "Dismissed",
            active: filter === "dismissed",
            count: dismissedCount ?? 0,
          },
          {
            href: "/reports?status=all",
            label: "All",
            active: filter === "all",
            count:
              (openCount ?? 0) + (actionedCount ?? 0) + (dismissedCount ?? 0),
          },
        ]}
      />

      <div className="overflow-hidden rounded-xl border border-[var(--border)] bg-[var(--surface)]">
        {rows.length === 0 ? (
          <p className="px-4 py-10 text-center text-sm text-[var(--muted)]">
            {emptyCopy[filter]}
          </p>
        ) : (
          <ul className="divide-y divide-[var(--border)]">
            {rows.map((report) => {
              const reporter = firstEmbed(report.profiles);
              const review =
                report.target_type === "review"
                  ? reviewsById.get(report.target_id)
                  : undefined;
              const vendorId =
                report.target_type === "vendor"
                  ? report.target_id
                  : review?.vendor_id;
              const vendor = vendorId ? vendorsById.get(vendorId) : undefined;

              return (
                <li key={report.id} className="px-4 py-5 sm:px-5">
                  <div className="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
                    <div className="space-y-2">
                      <div className="flex flex-wrap items-center gap-2">
                        <span className="rounded-full bg-[var(--burgundy-soft)] px-2 py-0.5 text-xs font-medium capitalize text-[var(--burgundy)]">
                          {report.target_type}
                        </span>
                        <span
                          className={`rounded-full px-2 py-0.5 text-xs font-medium capitalize ${
                            report.status === "open"
                              ? "bg-amber-100 text-amber-900"
                              : report.status === "actioned"
                                ? "bg-emerald-50 text-emerald-800"
                                : "bg-[var(--cream-deep)] text-[var(--muted)]"
                          }`}
                        >
                          {report.status}
                        </span>
                        <span className="text-xs text-[var(--muted)]">
                          {new Date(report.created_at).toLocaleString()}
                        </span>
                      </div>
                      <p className="text-sm text-[var(--ink)]">{report.reason}</p>
                      <p className="text-xs text-[var(--muted)]">
                        Reported by{" "}
                        {reporter?.full_name || reporter?.phone || "unknown"}
                        {reporter?.full_name && reporter?.phone
                          ? ` · ${reporter.phone}`
                          : ""}
                      </p>
                      {vendor ? (
                        <p className="text-xs text-[var(--ink)]">
                          Vendor:{" "}
                          <Link
                            href={`/vendors?q=${encodeURIComponent(vendor.business_name)}`}
                            className="font-medium text-[var(--burgundy)] hover:underline"
                          >
                            {vendor.business_name}
                          </Link>{" "}
                          <span className="capitalize text-[var(--muted)]">
                            ({vendor.city})
                          </span>
                        </p>
                      ) : (
                        <p className="text-xs text-[var(--muted)]">
                          Target{" "}
                          <code className="rounded bg-[var(--cream-deep)] px-1 py-0.5 text-[11px]">
                            {report.target_id.slice(0, 8)}…
                          </code>
                        </p>
                      )}
                      {review && (
                        <div className="mt-2 rounded-lg border border-[var(--border)] bg-[var(--cream)] px-3 py-2 text-sm">
                          <p className="text-xs text-[var(--muted)]">
                            Review · {review.rating}/5
                            {review.is_hidden ? " · already hidden" : ""}
                          </p>
                          <p className="mt-1 text-[var(--ink)]">
                            {review.comment || "(no comment)"}
                          </p>
                        </div>
                      )}
                    </div>

                    {report.status === "open" ? (
                      <div className="flex flex-wrap gap-2 sm:justify-end">
                        <form
                          action={updateReportStatus.bind(
                            null,
                            report.id,
                            "dismissed",
                          )}
                        >
                          <button
                            type="submit"
                            className="rounded-md border border-[var(--border)] px-3 py-1.5 text-xs text-[var(--muted)] hover:border-[var(--burgundy)] hover:text-[var(--burgundy)]"
                          >
                            Dismiss
                          </button>
                        </form>
                        <form
                          action={updateReportStatus.bind(
                            null,
                            report.id,
                            "actioned",
                          )}
                        >
                          <button
                            type="submit"
                            className="rounded-md bg-[var(--burgundy)] px-3 py-1.5 text-xs font-medium text-[var(--cream)] hover:bg-[var(--burgundy-deep)]"
                          >
                            Mark actioned
                          </button>
                        </form>
                        {report.target_type === "review" &&
                          review &&
                          !review.is_hidden && (
                            <form
                              action={hideReview.bind(
                                null,
                                review.id,
                                report.id,
                              )}
                            >
                              <ConfirmSubmitButton
                                message="Hide this review from the marketplace and mark the report as actioned?"
                                className="rounded-md border border-red-200 px-3 py-1.5 text-xs text-red-800 hover:bg-red-50"
                              >
                                Hide review
                              </ConfirmSubmitButton>
                            </form>
                          )}
                      </div>
                    ) : (
                      <p className="text-xs text-[var(--muted)] sm:text-right">
                        Closed
                      </p>
                    )}
                  </div>
                </li>
              );
            })}
          </ul>
        )}
      </div>
    </div>
  );
}
