# Dahr — Wedding Booking & Vendor Discovery (Libya)

Cross-platform Flutter marketplace connecting couples with wedding vendors in Libya, plus a Next.js admin dashboard. Backend is **Supabase** (Auth, Postgres, Storage, RLS).

> **Important:** Do **not** reuse the existing Zeen Supabase project. Use local `supabase start`, or the dedicated **Dahr LY** cloud project (never Zeen).

## Repo layout

```
dahr/
  lib/                 # Flutter app (feature-first)
  test/
  android/ ios/        # Platform stubs (Android applicationId com.dahr.app)
  admin/               # Next.js admin (App Router + Tailwind)
  supabase/
    migrations/        # Schema + RLS + storage + commission
    seed.sql           # Demo vendors (Tripoli & Benghazi)
    config.toml
  .env.example         # Flutter env names (copy to gitignored .env)
  admin/.env.example   # Admin NEXT_PUBLIC_* names (copy to .env.local)
  README.md
```

## Prerequisites

- Flutter SDK 3.24+ ([install](https://docs.flutter.dev/get-started/install))
- Node.js 20+ (admin)
- [Supabase CLI](https://supabase.com/docs/guides/cli) (local backend)
- Docker (for local Supabase)

## Environment files

`.env` and `admin/.env.local` are gitignored. Copy the examples and fill placeholders — never commit the Dahr LY anon key or any `service_role` key.

| App | File to copy | Names the code reads |
|-----|----------------|----------------------|
| Flutter | `.env.example` → `.env` | `SUPABASE_URL`, `SUPABASE_ANON_KEY` (alias `SUPABASE_PUBLISHABLE_KEY`) |
| Admin | `admin/.env.example` → `admin/.env.local` | `NEXT_PUBLIC_SUPABASE_URL`, `NEXT_PUBLIC_SUPABASE_ANON_KEY` |

Flutter does **not** read `NEXT_PUBLIC_*`. The admin browser client **only** reads `NEXT_PUBLIC_*`. Same URL and anon/publishable key, different names.

How Flutter loads them (first non-empty wins):

1. `--dart-define` or `--dart-define-from-file=.env` (`SUPABASE_URL`, `SUPABASE_ANON_KEY`, optional `SUPABASE_PUBLISHABLE_KEY`)
2. `flutter_dotenv` from the bundled `.env.example` asset

`.env` is not a Flutter asset (it is gitignored, so bundling it would break `flutter test` on a fresh clone). Pass real keys with `--dart-define-from-file=.env`.

`supabase_flutter` `initialize()` uses `url` + `publishableKey` (the anon/publishable key, not `service_role`).

## 1. Supabase

Migrations (applied in filename order):

- `supabase/migrations/20260328000001_init_schema.sql` — core schema, RLS, `vendor-photos` bucket
- `supabase/migrations/20260903000001_booking_commission.sql` — `quoted_amount_lyd`, 10% vendor commission, `accept_booking_request` RPC
- `supabase/migrations/20260903120000_delete_own_account.sql` — `delete_own_account` RPC (self-serve account deletion)

### Local (`supabase start`)

```bash
# From repo root
supabase start
supabase status          # API URL + anon (publishable) key
supabase db reset        # applies both migrations + seed.sql
```

Copy the printed **API URL** (`http://127.0.0.1:54321`) and **anon/publishable** key into `.env` and `admin/.env.local`.

Local Email OTP: Inbucket at http://127.0.0.1:54324 (`enable_confirmations = false` in `supabase/config.toml`). Phone OTP (+218) needs an SMS provider; the Flutter login screen is phone-first with **Continue with email** as fallback.

Seeded local admin: `admin@dahr.ly` (password `password123` only if you enable password auth). Prefer Email OTP via Inbucket. Couple demo: `couple@dahr.ly`.

### Cloud: Dahr LY

Live project: **Dahr LY**, ref `cccusktgxrizfwpixddu`, region `eu-west-1`.  
URL: `https://cccusktgxrizfwpixddu.supabase.co`

```bash
supabase link --project-ref cccusktgxrizfwpixddu
supabase db push         # no-op if init + booking_commission are already applied
# seed.sql is optional on cloud (SQL editor); do not rewrite schema
```

Put that URL and the **anon / publishable** key (Project Settings → API) in `.env` / `admin/.env.local`. Do not put real keys in git.

Enable **Email OTP** (Authentication → Providers → Email) for day-one login. Add redirect URLs:

- `http://localhost:3000/auth/callback`
- production admin origin `/auth/callback` if you deploy the dashboard

### Promote an admin

```sql
UPDATE public.profiles SET role = 'admin' WHERE id = '<auth-user-uuid>';
```

Admin login uses Email OTP and `shouldCreateUser: false` — the user must already exist (seed or this SQL).

## 2. Flutter app

```bash
cp .env.example .env
# Set SUPABASE_URL and SUPABASE_ANON_KEY (local status output, or Dahr LY anon key)

# Platform folders already exist (Android applicationId com.dahr.app).
# Refresh tooling only if android/ or ios/ are missing:
# flutter create . --project-name dahr --org com.dahr --platforms=android,ios

flutter pub get
flutter run --dart-define-from-file=.env
```

Arabic is the default locale (RTL). Switch language on the first screen. Android cleartext is enabled so local `http://127.0.0.1:54321` works on device/emulator.

## Try the vendor product flow

Guest browse of Discover stays open. Favorites, booking requests, and reviews still require sign-in (router redirects to login and returns afterward).

1. **Onboarding** — Sign in, choose **I'm a vendor** (or **Become a vendor** on Profile). Fill business name, category, city, WhatsApp, description, and price range (LYD). Submit. The listing waits for admin approval (`is_approved`).
2. **Photos** — Profile → Vendor tools → **Manage photos**, or Dashboard → **Manage photos**. Upload to the `vendor-photos` bucket, drag to reorder (first photo is the cover), delete.
3. **Calendar** — **Manage availability**. Tap a date to mark it booked or available. Booked dates show on the couple booking screen and cannot be selected.
4. **Inbox accept with quote** — A couple opens a vendor → **Request booking**, picks a free date. On the vendor Inbox (**Pending**), **Accept** and enter a LYD quote. The existing `accept_booking_request` RPC records 10% unpaid commission. Decline/complete stay on the other filters.
5. **Complete → review** — Vendor marks the request **Complete**. The couple sees **Leave a review** only then. Hidden reviews stay off the public vendor page.

Vendor dashboard overview: pending requests, unpaid commission owed, photo count, next booked dates.

### Tests

```bash
flutter test
flutter analyze lib test
```

## 3. Admin (Next.js)

```bash
cd admin
cp .env.example .env.local
# Same Supabase URL + anon key as Flutter, with NEXT_PUBLIC_ prefix

npm install
npm run dev
```

Open http://localhost:3000 — only users with `profiles.role = 'admin'` can access Dashboard / Vendors / Commissions / Reports.

Public store URLs (no admin login):

- Privacy: `http://localhost:3000/privacy` (deployed: `{ADMIN_ORIGIN}/privacy`)
- Terms: `http://localhost:3000/terms` (deployed: `{ADMIN_ORIGIN}/terms`)

Add Auth redirect URL: `http://localhost:3000/auth/callback`.

### Admin flows

- **Dashboard** — live counts from Supabase: vendors, pending approvals, users, bookings, open reports, unpaid commission (LYD). Pending / reports / commission cards link to those pages.
- **Approve a vendor** — Vendors → **Pending**. Review business, city, owner, WhatsApp. **Approve** lists them on Discover. **Revoke** on an approved row hides them again (confirm first).
- **Verify a vendor** — same table, **Verify** / **Unverify**. Verification is a badge only; it does not replace approval.
- **Moderate a report** — Reports (open queue). **Dismiss** if no action, **Mark actioned** after you handled it. For a review target, **Hide review** hides it in the app and marks the report actioned.
- **Commissions** — record offline 10% collection with **Mark paid** or **Waive**.

## Stack choices

| Area | Choice |
|------|--------|
| State | Riverpod only |
| Navigation | go_router + auth guards |
| Theme | Material 3 in `lib/core/theme` (cream / burgundy / gold, LYD) |
| i18n | ARB + handwritten `lib/l10n/generated` fallback |
| Images | Supabase Storage bucket `vendor-photos` |
| Contact | WhatsApp deep link (`wa.me`) — no in-app chat |

## MVP scope

**In:** discovery, filters, favorites, booking requests, vendor dashboard/inbox/availability/photos, reviews after completed bookings, admin approve/verify/moderate, **10% booking commission tracking** (vendor-paid, recorded in LYD).

**Out:** in-app card payments, Stripe, Apple IAP, Google Play Billing, chat, push notifications, maps, package bundling.

Couples still settle with the vendor off-platform (WhatsApp). When a vendor **accepts** a request they must enter a quoted amount in LYD. The database stores `quoted_amount_lyd`, computes `commission_amount_lyd` at 10%, and sets `commission_status = unpaid`. Completing a booking does **not** mark the commission paid.

Admins record offline collection on **Commissions**: **Mark paid** or **Waive**. That is the only way a vendor’s 10% is marked paid in v1.

## Store listing (Apple / Google Play)

Use the **deployed admin origin** for the public URLs reviewers ask for:

| Field | URL / path |
|-------|-------------|
| Privacy policy | `{ADMIN_ORIGIN}/privacy` |
| Terms of use | `{ADMIN_ORIGIN}/terms` |

In the Flutter app the same documents are under Profile → Privacy policy / Terms of use (`/legal/privacy`, `/legal/terms`), Arabic default and English.

**Account deletion (guideline 5.1.1(v)):** signed-in users delete from **Profile → Delete account** (confirm dialog). No support email is required. The app calls the `delete_own_account` RPC, which deletes `auth.users` for `auth.uid()` only (cascade `profiles`, vendor listing/photos as FKs allow). Fallback if the in-app flow fails: email `mohammedalariyibi@gmail.com` from the same phone or email as the account.

Copy is a **starting policy**, not law-firm work. Operator: Mohammed Alariyibi. Backend: Dahr LY, `eu-west-1`. No card data is stored.

## Demo seed

14 approved vendors across categories in Tripoli and Benghazi, one **pending** vendor (`قاعة الياسمين`) for the approve flow, sample photos, one completed booking + review (with unpaid 10% commission), one accepted booking with unpaid commission, one pending booking, two open reports (vendor + review), and an admin profile. See `supabase/seed.sql`.
