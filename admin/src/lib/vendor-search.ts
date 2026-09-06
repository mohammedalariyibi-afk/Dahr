import { CATEGORY_LABELS, CITY_LABELS } from "@/lib/admin";

export type VendorApprovalFilter = "all" | "pending" | "approved";

/**
 * Same allowlist as Flutter `VendorFilters.sanitizeSearch`: letters (incl.
 * Arabic), digits, spaces, hyphen. Strips PostgREST `.or()` metacharacters.
 */
export function sanitizeAdminSearch(raw: string): string {
  return raw
    .replace(/[^\p{L}\p{N}\s-]/gu, " ")
    .replace(/\s+/g, " ")
    .trim()
    .slice(0, 80);
}

export function parseVendorFilter(raw: string | undefined): VendorApprovalFilter {
  return raw === "pending" || raw === "approved" ? raw : "all";
}

/**
 * PostgREST `or=` clause. `q` must already be sanitized.
 * Owner matches are `profile_id.in.(...)` so we never need `profiles!inner`.
 */
export function vendorSearchOr(
  q: string,
  matchingProfileIds: string[] = [],
): string | null {
  if (!q) return null;
  const needle = q.toLowerCase();
  const clauses = [
    `business_name.ilike.%${q}%`,
    `description.ilike.%${q}%`,
    `whatsapp_number.ilike.%${q}%`,
  ];
  for (const [key, label] of Object.entries(CATEGORY_LABELS)) {
    if (key.includes(needle) || label.toLowerCase().includes(needle)) {
      clauses.push(`category.eq.${key}`);
    }
  }
  for (const [key, label] of Object.entries(CITY_LABELS)) {
    if (key.includes(needle) || label.toLowerCase().includes(needle)) {
      clauses.push(`city.eq.${key}`);
    }
  }
  if (matchingProfileIds.length > 0) {
    clauses.push(`profile_id.in.(${matchingProfileIds.join(",")})`);
  }
  return clauses.join(",");
}

export const VENDOR_LIST_SELECT =
  "id, business_name, category, city, description, price_min, price_max, whatsapp_number, is_approved, is_verified, created_at, profiles(full_name, phone)";

/** Keep the `in=()` URL short; owner-only hits beyond this still match via vendor columns. */
export const VENDOR_OWNER_SEARCH_CAP = 200;
