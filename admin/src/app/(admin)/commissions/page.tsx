import { setCommissionStatus } from "@/app/(admin)/actions";
import { ActionError } from "@/components/action-error";
import { createClient } from "@/lib/supabase/server";
import Link from "next/link";

type CommissionFilter = "all" | "unpaid" | "paid" | "waived";

type VendorEmbed =
  | { business_name: string; category: string; city: string }
  | { business_name: string; category: string; city: string }[]
  | null;

type CommissionRow = {
  id: string;
  event_date: string;
  status: string;
  quoted_amount_lyd: number | string | null;
  commission_rate: number | string | null;
  commission_amount_lyd: number | string | null;
  commission_status: "unpaid" | "paid" | "waived" | null;
  commission_paid_at: string | null;
  created_at: string;
  vendor_profiles: VendorEmbed;
};

type TransferNoteRow = {
  booking_id: string;
  reference_note: string;
  created_at: string;
};

function money(value: number | string | null | undefined): string {
  if (value === null || value === undefined || value === "") return "—";
  const n = typeof value === "number" ? value : Number(value);
  if (Number.isNaN(n)) return "—";
  return `${n.toFixed(2)} LYD`;
}

function vendorName(embed: VendorEmbed): string {
  const v = Array.isArray(embed) ? embed[0] : embed;
  return v?.business_name || "Unknown vendor";
}

function statusBadgeClass(status: CommissionRow["commission_status"]): string {
  switch (status) {
    case "paid":
      return "bg-emerald-50 text-emerald-800";
    case "waived":
      return "bg-[var(--cream-deep)] text-[var(--muted)]";
    case "unpaid":
      return "bg-amber-50 text-amber-900";
    default:
      return "bg-[var(--cream-deep)] text-[var(--muted)]";
  }
}

export default async function CommissionsPage({
  searchParams,
}: {
  searchParams: Promise<{ status?: string; error?: string }>;
}) {
  const { status: rawStatus, error: actionError } = await searchParams;
  const filter: CommissionFilter =
    rawStatus === "unpaid" || rawStatus === "paid" || rawStatus === "waived"
      ? rawStatus
      : "all";

  const supabase = await createClient();
  let query = supabase
    .from("booking_requests")
    .select(
      "id, event_date, status, quoted_amount_lyd, commission_rate, commission_amount_lyd, commission_status, commission_paid_at, created_at, vendor_profiles(business_name, category, city)",
    )
    .not("quoted_amount_lyd", "is", null)
    .order("created_at", { ascending: false });

  if (filter !== "all") {
    query = query.eq("commission_status", filter);
  }

  const { data, error } = await query;

  if (error) {
    return (
      <p className="text-sm text-red-700">
        Could not load commissions. Try again.
      </p>
    );
  }

  const rows = (data ?? []) as CommissionRow[];
  const notesByBooking = new Map<string, TransferNoteRow>();
  if (rows.length > 0) {
    const notesResult = await supabase
      .from("commission_transfer_notes")
      .select("booking_id, reference_note, created_at")
      .in(
        "booking_id",
        rows.map((r) => r.id),
      )
      .order("created_at", { ascending: false });
    for (const note of (notesResult.data ?? []) as TransferNoteRow[]) {
      if (!notesByBooking.has(note.booking_id)) {
        notesByBooking.set(note.booking_id, note);
      }
    }
  }
  const unpaidTotal = rows
    .filter((r) => r.commission_status === "unpaid")
    .reduce((sum, r) => sum + Number(r.commission_amount_lyd ?? 0), 0);

  const filters: { id: CommissionFilter; label: string }[] = [
    { id: "all", label: "All" },
    { id: "unpaid", label: "Unpaid" },
    { id: "paid", label: "Paid" },
    { id: "waived", label: "Waived" },
  ];

  return (
    <div className="space-y-8">
      <div>
        <h1 className="font-display text-3xl text-[var(--ink)]">Commissions</h1>
        <p className="mt-1 text-sm text-[var(--muted)]">
          10% of each accepted quote, paid by the couple to Dahr by online bank
          transfer. Mark paid after you confirm the transfer, or waive. Couples
          cannot mark the fee paid themselves.
        </p>
      </div>

      <ActionError message={actionError} />

      <div className="rounded-xl border border-[var(--border)] bg-[var(--surface)] p-5">
        <p className="text-sm text-[var(--muted)]">Unpaid on this list</p>
        <p className="mt-2 font-display text-4xl text-[var(--burgundy)] tabular-nums">
          {unpaidTotal.toFixed(2)} LYD
        </p>
      </div>

      <div className="flex flex-wrap gap-2">
        {filters.map((f) => {
          const href =
            f.id === "all" ? "/commissions" : `/commissions?status=${f.id}`;
          const active = filter === f.id;
          return (
            <Link
              key={f.id}
              href={href}
              className={`rounded-lg px-3 py-1.5 text-sm transition ${
                active
                  ? "bg-[var(--burgundy-soft)] font-medium text-[var(--burgundy)]"
                  : "border border-[var(--border)] text-[var(--muted)] hover:text-[var(--ink)]"
              }`}
            >
              {f.label}
            </Link>
          );
        })}
      </div>

      <div className="overflow-hidden rounded-xl border border-[var(--border)] bg-[var(--surface)]">
        {rows.length === 0 ? (
          <p className="px-4 py-10 text-center text-sm text-[var(--muted)]">
            No commission rows for this filter.
          </p>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left text-sm">
              <thead className="border-b border-[var(--border)] bg-[var(--cream-deep)]/60 text-[var(--muted)]">
                <tr>
                  <th className="px-4 py-3 font-medium">Vendor</th>
                  <th className="px-4 py-3 font-medium">Event</th>
                  <th className="px-4 py-3 font-medium text-right">Quote</th>
                  <th className="px-4 py-3 font-medium text-right">10% due</th>
                  <th className="px-4 py-3 font-medium">Booking</th>
                  <th className="px-4 py-3 font-medium">Commission</th>
                  <th className="px-4 py-3 font-medium">Paid at</th>
                  <th className="px-4 py-3 font-medium">Transfer note</th>
                  <th className="px-4 py-3 font-medium text-right">Record</th>
                </tr>
              </thead>
              <tbody>
                {rows.map((row) => (
                  <tr
                    key={row.id}
                    className="border-b border-[var(--border)] last:border-0"
                  >
                    <td className="px-4 py-3 text-[var(--ink)]">
                      {vendorName(row.vendor_profiles)}
                    </td>
                    <td className="px-4 py-3 tabular-nums text-[var(--ink)]">
                      {row.event_date}
                    </td>
                    <td className="px-4 py-3 text-right tabular-nums text-[var(--ink)]">
                      {money(row.quoted_amount_lyd)}
                    </td>
                    <td className="px-4 py-3 text-right tabular-nums text-[var(--ink)]">
                      {money(row.commission_amount_lyd)}
                    </td>
                    <td className="px-4 py-3 capitalize text-[var(--muted)]">
                      {row.status}
                    </td>
                    <td className="px-4 py-3">
                      <span
                        className={`rounded-full px-2 py-0.5 text-xs font-medium capitalize ${statusBadgeClass(
                          row.commission_status,
                        )}`}
                      >
                        {row.commission_status ?? "—"}
                      </span>
                    </td>
                    <td className="px-4 py-3 text-xs tabular-nums text-[var(--muted)]">
                      {row.commission_paid_at
                        ? new Date(row.commission_paid_at).toLocaleString()
                        : "—"}
                    </td>
                    <td className="max-w-[14rem] px-4 py-3 text-xs text-[var(--muted)]">
                      {notesByBooking.get(row.id)?.reference_note ?? "—"}
                    </td>
                    <td className="px-4 py-3">
                      {row.commission_status === "unpaid" ? (
                        <div className="flex flex-wrap justify-end gap-2">
                          <form
                            action={setCommissionStatus.bind(
                              null,
                              row.id,
                              "paid",
                            )}
                          >
                            <button
                              type="submit"
                              className="rounded-md bg-[var(--burgundy)] px-3 py-1.5 text-xs font-medium text-[var(--cream)] hover:bg-[var(--burgundy-deep)]"
                            >
                              Mark paid
                            </button>
                          </form>
                          <form
                            action={setCommissionStatus.bind(
                              null,
                              row.id,
                              "waived",
                            )}
                          >
                            <button
                              type="submit"
                              className="rounded-md border border-[var(--border)] px-3 py-1.5 text-xs text-[var(--muted)] hover:border-[var(--burgundy)] hover:text-[var(--burgundy)]"
                            >
                              Waive
                            </button>
                          </form>
                        </div>
                      ) : (
                        <p className="text-right text-xs text-[var(--muted)]">
                          Recorded
                        </p>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  );
}
