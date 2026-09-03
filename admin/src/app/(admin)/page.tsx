import { createClient } from "@/lib/supabase/server";
import { CATEGORY_LABELS, firstEmbed, formatLyd } from "@/lib/admin";
import Link from "next/link";

const BOOKING_STATUSES = ["pending", "accepted", "declined", "completed"] as const;

export default async function DashboardPage() {
  const supabase = await createClient();

  const [
    vendorsTotal,
    vendorsPending,
    usersTotal,
    bookingsResult,
    commissionResult,
    reportsOpen,
  ] = await Promise.all([
    supabase.from("vendor_profiles").select("*", { count: "exact", head: true }),
    supabase
      .from("vendor_profiles")
      .select("*", { count: "exact", head: true })
      .eq("is_approved", false),
    supabase.from("profiles").select("*", { count: "exact", head: true }),
    supabase
      .from("booking_requests")
      .select("id, status, vendor_profiles(category)"),
    supabase
      .from("booking_requests")
      .select("commission_status, commission_amount_lyd")
      .eq("commission_status", "unpaid"),
    supabase
      .from("reports")
      .select("*", { count: "exact", head: true })
      .eq("status", "open"),
  ]);

  const queryError =
    vendorsTotal.error?.message ||
    vendorsPending.error?.message ||
    usersTotal.error?.message ||
    bookingsResult.error?.message ||
    commissionResult.error?.message ||
    reportsOpen.error?.message;

  const byCategory = new Map<string, number>();
  const byStatus = new Map<string, number>();
  for (const row of bookingsResult.data ?? []) {
    const status = typeof row.status === "string" ? row.status : "pending";
    byStatus.set(status, (byStatus.get(status) ?? 0) + 1);

    const vendor = firstEmbed(
      row.vendor_profiles as { category: string } | { category: string }[] | null,
    );
    if (!vendor?.category) continue;
    byCategory.set(vendor.category, (byCategory.get(vendor.category) ?? 0) + 1);
  }

  const categoryStats = Object.keys(CATEGORY_LABELS).map((key) => ({
    key,
    label: CATEGORY_LABELS[key],
    count: byCategory.get(key) ?? 0,
  }));

  const unpaidCommission = (commissionResult.data ?? []).reduce((sum, row) => {
    return sum + Number(row.commission_amount_lyd ?? 0);
  }, 0);

  const bookingCount = bookingsResult.data?.length ?? 0;

  return (
    <div className="space-y-8">
      <div>
        <h1 className="font-display text-3xl text-[var(--ink)]">Dashboard</h1>
        <p className="mt-1 text-sm text-[var(--muted)]">
          Marketplace overview — vendors, bookings, reports, and unpaid
          commission
        </p>
      </div>

      {queryError ? (
        <p className="rounded-lg border border-red-200 bg-red-50 px-3 py-2 text-sm text-red-800">
          Some stats failed to load: {queryError}
        </p>
      ) : null}

      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
        <StatCard
          label="Total vendors"
          value={vendorsTotal.count ?? 0}
          href="/vendors"
        />
        <StatCard
          label="Pending approval"
          value={vendorsPending.count ?? 0}
          href="/vendors?filter=pending"
          highlight={(vendorsPending.count ?? 0) > 0}
        />
        <StatCard
          label="Open reports"
          value={reportsOpen.count ?? 0}
          href="/reports"
          highlight={(reportsOpen.count ?? 0) > 0}
        />
        <StatCard label="Total users" value={usersTotal.count ?? 0} />
        <StatCard label="Booking requests" value={bookingCount} />
        <StatCard
          label="Unpaid commission"
          value={formatLyd(unpaidCommission)}
          href="/commissions?status=unpaid"
        />
      </div>

      <div className="grid gap-8 lg:grid-cols-2">
        <section>
          <h2 className="text-lg font-medium text-[var(--ink)]">
            Booking requests by category
          </h2>
          <div className="mt-4 overflow-hidden rounded-xl border border-[var(--border)] bg-[var(--surface)]">
            <table className="w-full text-left text-sm">
              <thead className="border-b border-[var(--border)] bg-[var(--cream-deep)]/60 text-[var(--muted)]">
                <tr>
                  <th className="px-4 py-3 font-medium">Category</th>
                  <th className="px-4 py-3 font-medium text-right">Requests</th>
                </tr>
              </thead>
              <tbody>
                {categoryStats.map((row) => (
                  <tr
                    key={row.key}
                    className="border-b border-[var(--border)] last:border-0"
                  >
                    <td className="px-4 py-3 text-[var(--ink)]">{row.label}</td>
                    <td className="px-4 py-3 text-right tabular-nums text-[var(--ink)]">
                      {row.count}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </section>

        <section>
          <h2 className="text-lg font-medium text-[var(--ink)]">
            Bookings by status
          </h2>
          <div className="mt-4 overflow-hidden rounded-xl border border-[var(--border)] bg-[var(--surface)]">
            <table className="w-full text-left text-sm">
              <thead className="border-b border-[var(--border)] bg-[var(--cream-deep)]/60 text-[var(--muted)]">
                <tr>
                  <th className="px-4 py-3 font-medium">Status</th>
                  <th className="px-4 py-3 font-medium text-right">Count</th>
                </tr>
              </thead>
              <tbody>
                {BOOKING_STATUSES.map((status) => (
                  <tr
                    key={status}
                    className="border-b border-[var(--border)] last:border-0"
                  >
                    <td className="px-4 py-3 capitalize text-[var(--ink)]">
                      {status}
                    </td>
                    <td className="px-4 py-3 text-right tabular-nums text-[var(--ink)]">
                      {byStatus.get(status) ?? 0}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
            {bookingCount === 0 ? (
              <p className="border-t border-[var(--border)] px-4 py-6 text-sm text-[var(--muted)]">
                No booking requests yet.
              </p>
            ) : null}
          </div>
        </section>
      </div>
    </div>
  );
}

function StatCard({
  label,
  value,
  href,
  highlight,
}: {
  label: string;
  value: number | string;
  href?: string;
  highlight?: boolean;
}) {
  const inner = (
    <>
      <p className="text-sm text-[var(--muted)]">{label}</p>
      <p
        className={`mt-2 font-display text-3xl tabular-nums sm:text-4xl ${
          highlight ? "text-amber-800" : "text-[var(--burgundy)]"
        }`}
      >
        {value}
      </p>
    </>
  );

  const className = `rounded-xl border bg-[var(--surface)] p-5 ${
    highlight
      ? "border-amber-200"
      : "border-[var(--border)]"
  }${href ? " transition hover:border-[var(--burgundy)]" : ""}`;

  if (href) {
    return (
      <Link href={href} className={className}>
        {inner}
      </Link>
    );
  }

  return <div className={className}>{inner}</div>;
}
