import { hideReview, updateReportStatus } from "@/app/(admin)/actions";
import { createClient } from "@/lib/supabase/server";

export default async function ReportsPage() {
  const supabase = await createClient();
  const { data: reports, error } = await supabase
    .from("reports")
    .select(
      "id, target_type, target_id, reason, status, created_at, profiles!reports_reported_by_fkey(full_name, phone)",
    )
    .eq("status", "open")
    .order("created_at", { ascending: false });

  if (error) {
    return (
      <p className="text-sm text-red-700">Failed to load reports: {error.message}</p>
    );
  }

  const reviewIds = (reports ?? [])
    .filter((r) => r.target_type === "review")
    .map((r) => r.target_id);

  let reviewsById = new Map<
    string,
    { id: string; comment: string; rating: number; is_hidden: boolean }
  >();

  if (reviewIds.length > 0) {
    const { data: reviews } = await supabase
      .from("reviews")
      .select("id, comment, rating, is_hidden")
      .in("id", reviewIds);
    reviewsById = new Map((reviews ?? []).map((r) => [r.id, r]));
  }

  return (
    <div className="space-y-8">
      <div>
        <h1 className="font-display text-3xl text-[var(--ink)]">Reports</h1>
        <p className="mt-1 text-sm text-[var(--muted)]">
          Open moderation queue — dismiss or take action
        </p>
      </div>

      <div className="overflow-hidden rounded-xl border border-[var(--border)] bg-[var(--surface)]">
        {(reports ?? []).length === 0 ? (
          <p className="px-4 py-10 text-center text-sm text-[var(--muted)]">
            No open reports. Queue is clear.
          </p>
        ) : (
          <ul className="divide-y divide-[var(--border)]">
            {(reports ?? []).map((report) => {
              const reporter = Array.isArray(report.profiles)
                ? report.profiles[0]
                : report.profiles;
              const review =
                report.target_type === "review"
                  ? reviewsById.get(report.target_id)
                  : undefined;

              return (
                <li key={report.id} className="px-4 py-5 sm:px-5">
                  <div className="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
                    <div className="space-y-2">
                      <div className="flex flex-wrap items-center gap-2">
                        <span className="rounded-full bg-[var(--burgundy-soft)] px-2 py-0.5 text-xs font-medium capitalize text-[var(--burgundy)]">
                          {report.target_type}
                        </span>
                        <span className="text-xs text-[var(--muted)]">
                          {new Date(report.created_at).toLocaleString()}
                        </span>
                      </div>
                      <p className="text-sm text-[var(--ink)]">{report.reason}</p>
                      <p className="text-xs text-[var(--muted)]">
                        Reported by{" "}
                        {reporter?.full_name || reporter?.phone || "unknown"} ·
                        target{" "}
                        <code className="rounded bg-[var(--cream-deep)] px-1 py-0.5 text-[11px]">
                          {report.target_id.slice(0, 8)}…
                        </code>
                      </p>
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
                          <form action={hideReview.bind(null, review.id)}>
                            <button
                              type="submit"
                              className="rounded-md border border-red-200 px-3 py-1.5 text-xs text-red-800 hover:bg-red-50"
                            >
                              Hide review
                            </button>
                          </form>
                        )}
                    </div>
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
