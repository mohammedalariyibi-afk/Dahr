import { createClient } from "@/lib/supabase/server";

const CATEGORY_LABELS: Record<string, string> = {
  venues: "Venues",
  photography: "Photography",
  catering: "Catering",
  dresses: "Dresses",
  beauty: "Beauty",
  music: "Music",
  cars: "Cars",
  decor: "Decor",
  other: "Other",
};

export default async function DashboardPage() {
  const supabase = await createClient();

  const [
    { count: vendorCount },
    { count: userCount },
    { data: bookingRows },
  ] = await Promise.all([
    supabase
      .from("vendor_profiles")
      .select("*", { count: "exact", head: true }),
    supabase.from("profiles").select("*", { count: "exact", head: true }),
    supabase.from("booking_requests").select("id, vendor_profiles(category)"),
  ]);

  const byCategory = new Map<string, number>();
  for (const row of bookingRows ?? []) {
    const vendor = row.vendor_profiles as
      | { category: string }
      | { category: string }[]
      | null;
    const category = Array.isArray(vendor)
      ? vendor[0]?.category
      : vendor?.category;
    if (!category) continue;
    byCategory.set(category, (byCategory.get(category) ?? 0) + 1);
  }

  const categoryStats = Object.keys(CATEGORY_LABELS).map((key) => ({
    key,
    label: CATEGORY_LABELS[key],
    count: byCategory.get(key) ?? 0,
  }));

  return (
    <div className="space-y-8">
      <div>
        <h1 className="font-display text-3xl text-[var(--ink)]">Dashboard</h1>
        <p className="mt-1 text-sm text-[var(--muted)]">
          Overview of vendors, users, and booking demand
        </p>
      </div>

      <div className="grid gap-4 sm:grid-cols-2">
        <StatCard label="Total vendors" value={vendorCount ?? 0} />
        <StatCard label="Total users" value={userCount ?? 0} />
      </div>

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
    </div>
  );
}

function StatCard({ label, value }: { label: string; value: number }) {
  return (
    <div className="rounded-xl border border-[var(--border)] bg-[var(--surface)] p-5">
      <p className="text-sm text-[var(--muted)]">{label}</p>
      <p className="mt-2 font-display text-4xl text-[var(--burgundy)] tabular-nums">
        {value}
      </p>
    </div>
  );
}
