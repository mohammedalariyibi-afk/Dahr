import Link from "next/link";

export type FilterTab = {
  href: string;
  label: string;
  active: boolean;
  count?: number;
};

export function FilterTabs({
  items,
  ariaLabel = "Filter navigation",
}: {
  items: FilterTab[];
  ariaLabel?: string;
}) {
  return (
    <nav aria-label={ariaLabel} className="flex flex-wrap gap-2">
      {items.map((item) => (
        <Link
          key={item.href}
          href={item.href}
          aria-current={item.active ? "page" : undefined}
          className={`rounded-lg px-3 py-1.5 text-sm transition ${
            item.active
              ? "bg-[var(--burgundy-soft)] font-medium text-[var(--burgundy)]"
              : "border border-[var(--border)] text-[var(--muted)] hover:text-[var(--ink)]"
          }`}
        >
          {item.label}
          {item.count !== undefined ? (
            <span className="ms-1 tabular-nums opacity-80">
              <span className="sr-only"> ({item.count})</span>
              <span aria-hidden="true">({item.count})</span>
            </span>
          ) : null}
        </Link>
      ))}
    </nav>
  );
}
