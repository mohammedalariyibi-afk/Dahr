/** PostgREST `max_rows` is 1000. Admin lists stay well under that cap. */
export const ADMIN_PAGE_SIZE = 50;

export function parsePage(raw: string | undefined): number {
  const n = Number.parseInt(raw ?? "1", 10);
  if (!Number.isFinite(n) || n < 1) return 1;
  return Math.min(n, 10_000);
}

export function pageRange(page: number, pageSize = ADMIN_PAGE_SIZE) {
  const from = (page - 1) * pageSize;
  return { from, to: from + pageSize - 1 };
}

export function lastPage(total: number, pageSize = ADMIN_PAGE_SIZE): number {
  if (total <= 0) return 1;
  return Math.ceil(total / pageSize);
}

export function clampPage(
  page: number,
  total: number,
  pageSize = ADMIN_PAGE_SIZE,
): number {
  return Math.min(page, lastPage(total, pageSize));
}

export function showingRange(
  page: number,
  total: number,
  pageSize = ADMIN_PAGE_SIZE,
): { from: number; to: number } {
  if (total <= 0) return { from: 0, to: 0 };
  const from = (page - 1) * pageSize + 1;
  return { from, to: Math.min(page * pageSize, total) };
}

export function withSearchParams(
  pathname: string,
  params: URLSearchParams,
  patch: Record<string, string | null | undefined>,
): string {
  const next = new URLSearchParams(params);
  next.delete("error");
  for (const [key, value] of Object.entries(patch)) {
    if (value === null || value === undefined || value === "") {
      next.delete(key);
    } else {
      next.set(key, value);
    }
  }
  const s = next.toString();
  return s ? `${pathname}?${s}` : pathname;
}

export function pageHrefs(
  pathname: string,
  params: URLSearchParams,
  page: number,
  total: number,
  pageSize = ADMIN_PAGE_SIZE,
): { prevHref: string | null; nextHref: string | null } {
  const last = lastPage(total, pageSize);
  return {
    prevHref:
      page > 1
        ? withSearchParams(pathname, params, {
            page: page - 1 > 1 ? String(page - 1) : null,
          })
        : null,
    nextHref:
      page < last
        ? withSearchParams(pathname, params, { page: String(page + 1) })
        : null,
  };
}
