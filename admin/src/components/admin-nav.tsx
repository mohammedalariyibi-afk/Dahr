"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";

const links = [
  { href: "/", label: "Dashboard" },
  { href: "/vendors", label: "Vendors", badge: "pendingVendors" as const },
  { href: "/commissions", label: "Commissions" },
  { href: "/reports", label: "Reports", badge: "openReports" as const },
];

export function AdminNav({
  pendingVendors = 0,
  openReports = 0,
}: {
  pendingVendors?: number;
  openReports?: number;
}) {
  const pathname = usePathname();
  const badges = { pendingVendors, openReports };

  return (
    <nav className="flex items-center gap-1">
      {links.map((link) => {
        const active =
          link.href === "/"
            ? pathname === "/"
            : pathname.startsWith(link.href);
        const count = link.badge ? badges[link.badge] : 0;
        return (
          <Link
            key={link.href}
            href={link.href}
            className={`inline-flex items-center gap-1.5 rounded-lg px-3 py-1.5 text-sm transition ${
              active
                ? "bg-[var(--burgundy-soft)] font-medium text-[var(--burgundy)]"
                : "text-[var(--muted)] hover:text-[var(--ink)]"
            }`}
          >
            {link.label}
            {count > 0 ? (
              <span className="rounded-full bg-[var(--burgundy)] px-1.5 py-0.5 text-[10px] font-medium leading-none text-[var(--cream)] tabular-nums">
                {count}
              </span>
            ) : null}
          </Link>
        );
      })}
    </nav>
  );
}
