"use client";

import { useState } from "react";
import Link from "next/link";
import {
  getLegalDocument,
  type LegalKind,
  type LegalLang,
} from "@/lib/legal";

export function LegalPage({ kind }: { kind: LegalKind }) {
  const [lang, setLang] = useState<LegalLang>("ar");
  const doc = getLegalDocument(kind, lang);
  const other: LegalKind = kind === "privacy" ? "terms" : "privacy";
  const otherHref = other === "privacy" ? "/privacy" : "/terms";
  const otherLabel =
    lang === "ar"
      ? other === "privacy"
        ? "سياسة الخصوصية"
        : "شروط الاستخدام"
      : other === "privacy"
        ? "Privacy policy"
        : "Terms of use";

  return (
    <main
      dir={lang === "ar" ? "rtl" : "ltr"}
      className="min-h-screen px-4 py-10 sm:px-6"
    >
      <div className="mx-auto max-w-2xl">
        <p className="font-display text-3xl text-[var(--burgundy)]">Dahr</p>
        <p className="mt-1 text-sm text-[var(--muted)]">
          {lang === "ar" ? "سوق الزفاف في ليبيا" : "Libya wedding marketplace"}
        </p>
        <div className="mt-6 flex flex-wrap items-center gap-2">
          <button
            type="button"
            onClick={() => setLang("ar")}
            className={`rounded-lg px-3 py-1.5 text-sm ${
              lang === "ar"
                ? "bg-[var(--burgundy)] text-[var(--cream)]"
                : "border border-[var(--border)] text-[var(--ink)]"
            }`}
          >
            العربية
          </button>
          <button
            type="button"
            onClick={() => setLang("en")}
            className={`rounded-lg px-3 py-1.5 text-sm ${
              lang === "en"
                ? "bg-[var(--burgundy)] text-[var(--cream)]"
                : "border border-[var(--border)] text-[var(--ink)]"
            }`}
          >
            English
          </button>
        </div>
        <h1 className="mt-8 font-display text-3xl text-[var(--ink)]">
          {doc.title}
        </h1>
        <p className="mt-2 text-sm italic text-[var(--muted)]">{doc.updated}</p>
        <p className="mt-6 leading-relaxed text-[var(--ink)]">{doc.intro}</p>
        {doc.sections.map((section) => (
          <section key={section.heading} className="mt-8">
            <h2 className="text-lg font-semibold text-[var(--burgundy)]">
              {section.heading}
            </h2>
            <p className="mt-2 leading-relaxed text-[var(--ink)]">
              {section.body}
            </p>
          </section>
        ))}
        <p className="mt-12 text-sm text-[var(--muted)]">
          <Link
            href={otherHref}
            className="text-[var(--burgundy)] underline underline-offset-2"
          >
            {otherLabel}
          </Link>
        </p>
      </div>
    </main>
  );
}
