export const CATEGORY_LABELS: Record<string, string> = {
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

export const CITY_LABELS: Record<string, string> = {
  tripoli: "Tripoli",
  benghazi: "Benghazi",
};

/** Supabase embeds can be an object, an array, or null depending on the relationship. */
export function firstEmbed<T>(value: T | T[] | null | undefined): T | null {
  if (!value) return null;
  return Array.isArray(value) ? (value[0] ?? null) : value;
}

export function formatLyd(value: number | string | null | undefined): string {
  if (value === null || value === undefined || value === "") return "0.00 LYD";
  const n = typeof value === "number" ? value : Number(value);
  if (Number.isNaN(n)) return "0.00 LYD";
  return `${n.toFixed(2)} LYD`;
}

export function formatPriceRange(
  min: number | string | null | undefined,
  max: number | string | null | undefined,
): string | null {
  const lo = min === null || min === undefined || min === "" ? null : Number(min);
  const hi = max === null || max === undefined || max === "" ? null : Number(max);
  if (lo === null && hi === null) return null;
  if (lo !== null && hi !== null && !Number.isNaN(lo) && !Number.isNaN(hi)) {
    return `${lo.toFixed(0)}–${hi.toFixed(0)} LYD`;
  }
  const n = lo ?? hi;
  if (n === null || Number.isNaN(n)) return null;
  return `${n.toFixed(0)} LYD`;
}
