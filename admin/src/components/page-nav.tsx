import Link from "next/link";
import { ADMIN_PAGE_SIZE, showingRange } from "@/lib/admin-page";

export function PageNav({
  page,
  total,
  pageSize = ADMIN_PAGE_SIZE,
  prevHref,
  nextHref,
  noun,
}: {
  page: number;
  total: number;
  pageSize?: number;
  prevHref: string | null;
  nextHref: string | null;
  noun: string;
}) {
  if (total <= 0) return null;
  const { from, to } = showingRange(page, total, pageSize);
  const needsButtons = total > pageSize;

  return (
    <nav
      aria-label="Pagination"
      className="flex flex-wrap items-center justify-between gap-3 text-sm text-[var(--muted)]"
    >
      <p>
        Showing{" "}
        <span className="tabular-nums text-[var(--ink)]">
          {from}–{to}
        </span>{" "}
        of <span className="tabular-nums text-[var(--ink)]">{total}</span> {noun}
      </p>
      {needsButtons ? (
        <div className="flex gap-2">
          {prevHref ? (
            <Link
              href={prevHref}
              className="rounded-lg border border-[var(--border)] px-3 py-1.5 text-[var(--ink)] hover:border-[var(--burgundy)] hover:text-[var(--burgundy)]"
            >
              Previous
            </Link>
          ) : (
            <span
              aria-disabled="true"
              className="rounded-lg border border-[var(--border)] px-3 py-1.5 opacity-40 select-none cursor-not-allowed"
            >
              Previous
            </span>
          )}
          {nextHref ? (
            <Link
              href={nextHref}
              className="rounded-lg border border-[var(--border)] px-3 py-1.5 text-[var(--ink)] hover:border-[var(--burgundy)] hover:text-[var(--burgundy)]"
            >
              Next
            </Link>
          ) : (
            <span
              aria-disabled="true"
              className="rounded-lg border border-[var(--border)] px-3 py-1.5 opacity-40 select-none cursor-not-allowed"
            >
              Next
            </span>
          )}
        </div>
      ) : null}
    </nav>
  );
}
