# Dahr admin dashboard (Next.js)

See the **repo root README** for setup: copy `.env.example` to `.env.local`, use `NEXT_PUBLIC_SUPABASE_URL` and `NEXT_PUBLIC_SUPABASE_ANON_KEY` (same values as Flutter’s `SUPABASE_*`, different names), Email OTP, and Dahr LY vs local `supabase start`. Do not use the Zeen project.

```bash
cp .env.example .env.local
npm install
npm run dev
```

Open http://localhost:3000. Only `profiles.role = 'admin'` can access Dashboard / Vendors / Commissions / Reports. Add Auth redirect URL `http://localhost:3000/auth/callback`.

Dashboard cards and breakdowns use PostgREST `count: "exact"` (and a `sum()` / amount-only fallback for unpaid commission) so they stay accurate past the 1000-row API cap. Vendors, reports, and commissions list 50 rows per page and show an exact total; vendor search runs in SQL, not over a capped in-memory table.

Public legal pages (no login): `/privacy` and `/terms`. Store consoles should use the GitHub Pages copies (`https://mohammedalariyibi-afk.github.io/Dahr/privacy` and `.../terms`), not a Vercel admin origin.
