# Dahr admin dashboard (Next.js)

See the **repo root README** for setup: copy `.env.example` to `.env.local`, use `NEXT_PUBLIC_SUPABASE_URL` and `NEXT_PUBLIC_SUPABASE_ANON_KEY` (same values as Flutter’s `SUPABASE_*`, different names), Email OTP, and Dahr LY vs local `supabase start`. Do not use the Zeen project.

```bash
cp .env.example .env.local
npm install
npm run dev
```

Open http://localhost:3000. Only `profiles.role = 'admin'` can access Dashboard / Vendors / Commissions / Reports. Add Auth redirect URL `http://localhost:3000/auth/callback`.
