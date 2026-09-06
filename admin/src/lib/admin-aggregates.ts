import type { PostgrestError, SupabaseClient } from "@supabase/supabase-js";

/** Matches PostgREST `max_rows` so an amount-only fallback never truncates. */
const AMOUNT_PAGE = 1000;

function asNumber(value: unknown): number {
  const n = typeof value === "number" ? value : Number(value ?? 0);
  return Number.isFinite(n) ? n : 0;
}

function sumField(row: unknown): number | null {
  if (!row || typeof row !== "object") return null;
  const record = row as Record<string, unknown>;
  if ("sum" in record) return asNumber(record.sum);
  if ("commission_amount_lyd" in record) return asNumber(record.commission_amount_lyd);
  return null;
}

/**
 * Unpaid 10% total without loading booking rows into memory.
 * Prefers a one-row PostgREST `sum()` (when aggregates are enabled);
 * otherwise pages `commission_amount_lyd` only until the table is exhausted.
 */
export async function sumUnpaidCommission(
  supabase: SupabaseClient,
): Promise<{ sum: number; error: PostgrestError | null }> {
  const aggregated = await supabase
    .from("booking_requests")
    .select("total:commission_amount_lyd.sum()")
    .eq("commission_status", "unpaid")
    .maybeSingle();

  if (!aggregated.error) {
    const fromAlias = (aggregated.data as { total?: unknown } | null)?.total;
    if (fromAlias !== undefined && fromAlias !== null) {
      return { sum: asNumber(fromAlias), error: null };
    }
    const fromSum = sumField(aggregated.data);
    if (fromSum !== null) return { sum: fromSum, error: null };
    return { sum: 0, error: null };
  }

  let sum = 0;
  let from = 0;
  for (;;) {
    const { data, error } = await supabase
      .from("booking_requests")
      .select("commission_amount_lyd")
      .eq("commission_status", "unpaid")
      .range(from, from + AMOUNT_PAGE - 1);
    if (error) return { sum: 0, error };
    const rows = data ?? [];
    for (const row of rows) {
      sum += asNumber(row.commission_amount_lyd);
    }
    if (rows.length < AMOUNT_PAGE) break;
    from += AMOUNT_PAGE;
  }
  return { sum, error: null };
}

export function bookingsByCategoryQuery(
  supabase: SupabaseClient,
  category: string,
) {
  return supabase
    .from("booking_requests")
    .select("id, vendor_profiles!inner(category)", {
      count: "exact",
      head: true,
    })
    .eq("vendor_profiles.category", category);
}
