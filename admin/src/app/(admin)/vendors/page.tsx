import Link from "next/link";
import {
  setVendorApproved,
  toggleVendorVerified,
} from "@/app/(admin)/actions";
import { ActionError } from "@/components/action-error";
import { ConfirmSubmitButton } from "@/components/confirm-submit-button";
import { FilterTabs } from "@/components/filter-tabs";
import { PageNav } from "@/components/page-nav";
import {
  CATEGORY_LABELS,
  CITY_LABELS,
  firstEmbed,
  formatPriceRange,
} from "@/lib/admin";
import {
  clampPage,
  pageHrefs,
  pageRange,
  parsePage,
  withSearchParams,
} from "@/lib/admin-page";
import {
  VENDOR_LIST_SELECT,
  VENDOR_OWNER_SEARCH_CAP,
  parseVendorFilter,
  sanitizeAdminSearch,
  vendorSearchOr,
  type VendorApprovalFilter,
} from "@/lib/vendor-search";
import { createClient } from "@/lib/supabase/server";

type ProfileEmbed = {
  full_name: string | null;
  phone: string | null;
};

type VendorRow = {
  id: string;
  business_name: string;
  category: string;
  city: string;
  description: string | null;
  price_min: number | string | null;
  price_max: number | string | null;
  whatsapp_number: string | null;
  is_approved: boolean;
  is_verified: boolean;
  created_at: string;
  profiles: ProfileEmbed | ProfileEmbed[] | null;
};

function applyVendorConstraints(
  // PostgREST filter builder — kept loose so `select()` string unions stay finite.
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  query: any,
  filter: VendorApprovalFilter,
  orClause: string | null,
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
): any {
  if (filter === "pending") query = query.eq("is_approved", false);
  if (filter === "approved") query = query.eq("is_approved", true);
  if (orClause) query = query.or(orClause);
  return query;
}

export default async function VendorsPage({
  searchParams,
}: {
  searchParams: Promise<{
    q?: string;
    filter?: string;
    page?: string;
    error?: string;
  }>;
}) {
  const params = await searchParams;
  const qRaw = (params.q ?? "").trim();
  const q = sanitizeAdminSearch(qRaw);
  const filter = parseVendorFilter(params.filter);
  const requestedPage = parsePage(params.page);

  const supabase = await createClient();
  let ownerIds: string[] = [];
  if (q) {
    const { data: owners } = await supabase
      .from("profiles")
      .select("id")
      .or(`full_name.ilike.%${q}%,phone.ilike.%${q}%`)
      .limit(VENDOR_OWNER_SEARCH_CAP);
    ownerIds = (owners ?? []).map((row) => row.id);
  }
  const orClause = vendorSearchOr(q, ownerIds);

  const [allCount, pendingCount, approvedCount] = await Promise.all(
    (["all", "pending", "approved"] as const).map(async (tab) => {
      const result = (await applyVendorConstraints(
        supabase
          .from("vendor_profiles")
          .select("id", { count: "exact", head: true }),
        tab,
        orClause,
      )) as { count: number | null; error: { message: string } | null };
      return { tab, count: result.count, error: result.error };
    }),
  );

  if (allCount.error || pendingCount.error || approvedCount.error) {
    return (
      <p className="text-sm text-red-700">Could not load vendors. Try again.</p>
    );
  }

  const tabTotal =
    filter === "pending"
      ? (pendingCount.count ?? 0)
      : filter === "approved"
        ? (approvedCount.count ?? 0)
        : (allCount.count ?? 0);
  const page = clampPage(requestedPage, tabTotal);
  const { from, to } = pageRange(page);

  let listQuery = applyVendorConstraints(
    supabase
      .from("vendor_profiles")
      .select(VENDOR_LIST_SELECT, { count: "exact" }),
    filter,
    orClause,
  );
  if (filter === "all") {
    listQuery = listQuery.order("is_approved", { ascending: true });
  }
  const { data: vendors, error } = await listQuery
    .order("created_at", { ascending: false })
    .range(from, to);

  if (error) {
    return (
      <p className="text-sm text-red-700">Could not load vendors. Try again.</p>
    );
  }

  const rows = (vendors ?? []) as unknown as VendorRow[];
  const pending = rows.filter((v) => !v.is_approved);
  const approved = rows.filter((v) => v.is_approved);

  const query = new URLSearchParams();
  if (qRaw) query.set("q", qRaw);
  if (filter !== "all") query.set("filter", filter);

  const tabHref = (nextFilter: VendorApprovalFilter) =>
    withSearchParams("/vendors", query, {
      filter: nextFilter === "all" ? null : nextFilter,
      page: null,
    });

  const { prevHref, nextHref } = pageHrefs("/vendors", query, page, tabTotal);

  return (
    <div className="space-y-8">
      <div>
        <h1 className="font-display text-3xl text-[var(--ink)]">Vendors</h1>
        <p className="mt-1 text-sm text-[var(--muted)]">
          Approve pending applications, revoke marketplace listing, and toggle
          the verified badge
        </p>
      </div>

      <ActionError message={params.error} />

      <form className="flex flex-wrap gap-2" action="/vendors" method="get">
        {filter !== "all" ? (
          <input type="hidden" name="filter" value={filter} />
        ) : null}
        <input
          type="search"
          name="q"
          defaultValue={qRaw}
          aria-label="Search vendors"
          placeholder="Search business, city, owner, WhatsApp…"
          className="min-w-[220px] flex-1 rounded-lg border border-[var(--border)] bg-[var(--surface)] px-3 py-2 text-sm text-[var(--ink)] outline-none focus:border-[var(--burgundy)] focus:ring-2 focus:ring-[var(--burgundy-soft)]"
        />
        <button
          type="submit"
          className="rounded-lg bg-[var(--burgundy)] px-4 py-2 text-sm font-medium text-[var(--cream)] hover:bg-[var(--burgundy-deep)]"
        >
          Search
        </button>
        {qRaw ? (
          <Link
            href={tabHref(filter)}
            className="rounded-lg border border-[var(--border)] bg-[var(--surface)] px-4 py-2 text-sm text-[var(--muted)] hover:border-[var(--burgundy)] hover:text-[var(--ink)]"
          >
            Clear
          </Link>
        ) : null}
      </form>

      <FilterTabs
        ariaLabel="Filter vendors by status"
        items={[
          {
            href: tabHref("all"),
            label: "All",
            active: filter === "all",
            count: allCount.count ?? 0,
          },
          {
            href: tabHref("pending"),
            label: "Pending",
            active: filter === "pending",
            count: pendingCount.count ?? 0,
          },
          {
            href: tabHref("approved"),
            label: "Approved",
            active: filter === "approved",
            count: approvedCount.count ?? 0,
          },
        ]}
      />

      {filter !== "approved" &&
      (pending.length > 0 || (pendingCount.count ?? 0) === 0) ? (
        <VendorSection
          title="Pending approval"
          vendors={pending}
          total={pendingCount.count ?? 0}
          empty={
            q
              ? "No pending vendors match this search."
              : "No pending vendors. New applications will appear here."
          }
        />
      ) : null}
      {filter !== "pending" &&
      (approved.length > 0 || (approvedCount.count ?? 0) === 0) ? (
        <VendorSection
          title="Approved"
          vendors={approved}
          total={approvedCount.count ?? 0}
          empty={
            q
              ? "No approved vendors match this search."
              : "No approved vendors yet."
          }
        />
      ) : null}

      <PageNav
        page={page}
        total={tabTotal}
        prevHref={prevHref}
        nextHref={nextHref}
        noun={tabTotal === 1 ? "vendor" : "vendors"}
      />
    </div>
  );
}

function VendorSection({
  title,
  vendors,
  total,
  empty,
}: {
  title: string;
  vendors: VendorRow[];
  total: number;
  empty: string;
}) {
  return (
    <section>
      <h2 className="text-lg font-medium text-[var(--ink)]">
        {title}{" "}
        <span className="text-sm font-normal text-[var(--muted)]">
          ({total})
        </span>
      </h2>
      <div className="mt-4 overflow-x-auto rounded-xl border border-[var(--border)] bg-[var(--surface)]">
        {vendors.length === 0 ? (
          <p className="px-4 py-8 text-sm text-[var(--muted)]">{empty}</p>
        ) : (
          <table className="w-full min-w-[880px] text-left text-sm">
            <thead className="border-b border-[var(--border)] bg-[var(--cream-deep)]/60 text-[var(--muted)]">
              <tr>
                <th className="px-4 py-3 font-medium">Business</th>
                <th className="px-4 py-3 font-medium">Category</th>
                <th className="px-4 py-3 font-medium">City</th>
                <th className="px-4 py-3 font-medium">Owner</th>
                <th className="px-4 py-3 font-medium">Applied</th>
                <th className="px-4 py-3 font-medium">Status</th>
                <th className="px-4 py-3 font-medium text-right">Actions</th>
              </tr>
            </thead>
            <tbody>
              {vendors.map((vendor) => {
                const profile = firstEmbed(vendor.profiles);
                const prices = formatPriceRange(
                  vendor.price_min,
                  vendor.price_max,
                );
                return (
                  <tr
                    key={vendor.id}
                    className="border-b border-[var(--border)] last:border-0 align-top"
                  >
                    <td className="px-4 py-3">
                      <p className="font-medium text-[var(--ink)]">
                        {vendor.business_name}
                      </p>
                      {vendor.description ? (
                        <p className="mt-1 max-w-xs text-xs text-[var(--muted)] line-clamp-2">
                          {vendor.description}
                        </p>
                      ) : null}
                      <p className="mt-1 text-xs text-[var(--muted)]">
                        {[
                          vendor.whatsapp_number
                            ? `WhatsApp ${vendor.whatsapp_number}`
                            : null,
                          prices,
                        ]
                          .filter(Boolean)
                          .join(" · ") || "—"}
                      </p>
                    </td>
                    <td className="px-4 py-3 text-[var(--ink)]">
                      {CATEGORY_LABELS[vendor.category] ?? vendor.category}
                    </td>
                    <td className="px-4 py-3 text-[var(--ink)]">
                      {CITY_LABELS[vendor.city] ?? vendor.city}
                    </td>
                    <td className="px-4 py-3 text-[var(--muted)]">
                      <p>{profile?.full_name || "—"}</p>
                      {profile?.phone ? (
                        <p className="text-xs tabular-nums">{profile.phone}</p>
                      ) : null}
                    </td>
                    <td className="px-4 py-3 text-xs tabular-nums text-[var(--muted)]">
                      {new Date(vendor.created_at).toLocaleDateString()}
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
                        ) : (
                          <form
                            action={setVendorApproved.bind(
                              null,
                              vendor.id,
                              false,
                            )}
                          >
                            <ConfirmSubmitButton
                              message={`Revoke approval for ${vendor.business_name}? They will disappear from Discover until you approve them again.`}
                              className="rounded-md border border-[var(--border)] px-2.5 py-1 text-xs text-[var(--muted)] hover:border-red-300 hover:text-red-700"
                            >
                              Revoke
                            </ConfirmSubmitButton>
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
