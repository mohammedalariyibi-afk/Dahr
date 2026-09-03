import {
  setVendorApproved,
  toggleVendorVerified,
} from "@/app/(admin)/actions";
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

export default async function VendorsPage() {
  const supabase = await createClient();
  const { data: vendors, error } = await supabase
    .from("vendor_profiles")
    .select(
      "id, business_name, category, city, is_approved, is_verified, created_at, profiles(full_name, phone)",
    )
    .order("created_at", { ascending: false });

  if (error) {
    return (
      <p className="text-sm text-red-700">Failed to load vendors: {error.message}</p>
    );
  }

  const pending = (vendors ?? []).filter((v) => !v.is_approved);
  const approved = (vendors ?? []).filter((v) => v.is_approved);

  return (
    <div className="space-y-8">
      <div>
        <h1 className="font-display text-3xl text-[var(--ink)]">Vendors</h1>
        <p className="mt-1 text-sm text-[var(--muted)]">
          Approve pending applications and manage verification
        </p>
      </div>

      <VendorSection title="Pending approval" vendors={pending} empty="No pending vendors." />
      <VendorSection title="Approved" vendors={approved} empty="No approved vendors yet." />
    </div>
  );
}

type VendorRow = {
  id: string;
  business_name: string;
  category: string;
  city: string;
  is_approved: boolean;
  is_verified: boolean;
  created_at: string;
  profiles:
    | { full_name: string | null; phone: string | null }
    | { full_name: string | null; phone: string | null }[]
    | null;
};

function VendorSection({
  title,
  vendors,
  empty,
}: {
  title: string;
  vendors: VendorRow[];
  empty: string;
}) {
  return (
    <section>
      <h2 className="text-lg font-medium text-[var(--ink)]">
        {title}{" "}
        <span className="text-sm font-normal text-[var(--muted)]">
          ({vendors.length})
        </span>
      </h2>
      <div className="mt-4 overflow-x-auto rounded-xl border border-[var(--border)] bg-[var(--surface)]">
        {vendors.length === 0 ? (
          <p className="px-4 py-8 text-sm text-[var(--muted)]">{empty}</p>
        ) : (
          <table className="w-full min-w-[720px] text-left text-sm">
            <thead className="border-b border-[var(--border)] bg-[var(--cream-deep)]/60 text-[var(--muted)]">
              <tr>
                <th className="px-4 py-3 font-medium">Business</th>
                <th className="px-4 py-3 font-medium">Category</th>
                <th className="px-4 py-3 font-medium">City</th>
                <th className="px-4 py-3 font-medium">Owner</th>
                <th className="px-4 py-3 font-medium">Status</th>
                <th className="px-4 py-3 font-medium text-right">Actions</th>
              </tr>
            </thead>
            <tbody>
              {vendors.map((vendor) => {
                const profile = Array.isArray(vendor.profiles)
                  ? vendor.profiles[0]
                  : vendor.profiles;
                return (
                  <tr
                    key={vendor.id}
                    className="border-b border-[var(--border)] last:border-0"
                  >
                    <td className="px-4 py-3 font-medium text-[var(--ink)]">
                      {vendor.business_name}
                    </td>
                    <td className="px-4 py-3 capitalize text-[var(--ink)]">
                      {CATEGORY_LABELS[vendor.category] ?? vendor.category}
                    </td>
                    <td className="px-4 py-3 capitalize text-[var(--ink)]">
                      {vendor.city}
                    </td>
                    <td className="px-4 py-3 text-[var(--muted)]">
                      {profile?.full_name || profile?.phone || "—"}
                    </td>
                    <td className="px-4 py-3">
                      <div className="flex flex-wrap gap-1.5">
                        <Badge tone={vendor.is_approved ? "ok" : "warn"}>
                          {vendor.is_approved ? "Approved" : "Pending"}
                        </Badge>
                        {vendor.is_verified && <Badge tone="ok">Verified</Badge>}
                      </div>
                    </td>
                    <td className="px-4 py-3">
                      <div className="flex flex-wrap justify-end gap-2">
                        {!vendor.is_approved ? (
                          <>
                            <form
                              action={setVendorApproved.bind(null, vendor.id, true)}
                            >
                              <button
                                type="submit"
                                className="rounded-md bg-[var(--burgundy)] px-2.5 py-1 text-xs font-medium text-[var(--cream)] hover:bg-[var(--burgundy-deep)]"
                              >
                                Approve
                              </button>
                            </form>
                            <form
                              action={setVendorApproved.bind(null, vendor.id, false)}
                            >
                              <button
                                type="submit"
                                className="rounded-md border border-[var(--border)] px-2.5 py-1 text-xs text-[var(--muted)] hover:border-red-300 hover:text-red-700"
                              >
                                Reject
                              </button>
                            </form>
                          </>
                        ) : (
                          <form
                            action={setVendorApproved.bind(null, vendor.id, false)}
                          >
                            <button
                              type="submit"
                              className="rounded-md border border-[var(--border)] px-2.5 py-1 text-xs text-[var(--muted)] hover:border-red-300 hover:text-red-700"
                            >
                              Revoke
                            </button>
                          </form>
                        )}
                        <form
                          action={toggleVendorVerified.bind(
                            null,
                            vendor.id,
                            !vendor.is_verified,
                          )}
                        >
                          <button
                            type="submit"
                            className="rounded-md border border-[var(--border)] px-2.5 py-1 text-xs text-[var(--ink)] hover:border-[var(--burgundy)] hover:text-[var(--burgundy)]"
                          >
                            {vendor.is_verified ? "Unverify" : "Verify"}
                          </button>
                        </form>
                      </div>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        )}
      </div>
    </section>
  );
}

function Badge({
  children,
  tone,
}: {
  children: React.ReactNode;
  tone: "ok" | "warn";
}) {
  const styles =
    tone === "ok"
      ? "bg-[var(--burgundy-soft)] text-[var(--burgundy)]"
      : "bg-amber-100 text-amber-900";
  return (
    <span className={`rounded-full px-2 py-0.5 text-xs font-medium ${styles}`}>
      {children}
    </span>
  );
}
