# Dahr — Wedding Booking & Vendor Discovery (Libya)

Cross-platform Flutter marketplace connecting couples with wedding vendors in Libya, plus a Next.js admin dashboard. Backend is **Supabase** (Auth, Postgres, Storage, RLS).

> **Important:** Do **not** reuse the existing Zeen Supabase project. Create a **new** Supabase project for Dahr (or use local `supabase start`).

## Repo layout

```
dahr/
  lib/                 # Flutter app (feature-first)
  test/
  android/ ios/        # Minimal platform stubs — refresh with flutter create
  admin/               # Next.js admin (App Router + Tailwind)
  supabase/
    migrations/        # Schema + RLS + storage
    seed.sql           # Demo vendors (Tripoli & Benghazi)
    config.toml
  .env.example
  README.md
```

## Prerequisites

- Flutter SDK 3.24+ ([install](https://docs.flutter.dev/get-started/install))
- Node.js 20+ (admin)
- [Supabase CLI](https://supabase.com/docs/guides/cli) (local backend)
- Docker (for local Supabase)

## 1. Supabase (local recommended)

```bash
# From repo root
supabase start
# Copy API URL + anon key printed by the CLI into .env and admin/.env.local
supabase db reset   # applies migrations + seed.sql
```

Or create a **new** cloud project, then:

```bash
supabase link --project-ref <your-new-project-ref>
supabase db push
# Run seed.sql in the SQL editor (optional for cloud)
```

Enable **Email OTP** in Auth settings for day-one login. Phone OTP (+218) needs an SMS provider (Twilio, etc.) — the Flutter app exposes phone first and **Continue with email** as fallback.

### Promote an admin

```sql
UPDATE public.profiles SET role = 'admin' WHERE id = '<auth-user-uuid>';
```

Seeded local admin email: `admin@dahr.ly` (password `password123` only if you enable password auth; prefer email OTP in local Inbucket at http://127.0.0.1:54324).

## 2. Flutter app

```bash
cp .env.example .env
# Set SUPABASE_URL and SUPABASE_ANON_KEY

# Refresh full Android/iOS tooling if needed:
flutter create . --project-name dahr --org com.dahr

flutter pub get
flutter run
```

Arabic is the default locale (RTL). Switch language on the first screen.

## Try the vendor product flow

Guest browse of Discover stays open. Favorites, booking requests, and reviews still require sign-in.

1. **Onboarding** — Sign in, choose **I'm a vendor** (or **Become a vendor** on Profile). Fill business name, category, city, WhatsApp, description, and price range (LYD). Submit. The listing waits for admin approval (`is_approved`).
2. **Photos** — Profile → Vendor tools → **Manage photos**, or Dashboard → **Manage photos**. Upload to the `vendor-photos` bucket, drag to reorder (first photo is the cover), delete.
3. **Calendar** — **Manage availability**. Tap a date to mark it booked or available. Booked dates show on the couple booking screen and cannot be selected.
4. **Inbox accept with quote** — A couple opens a vendor → **Request booking**, picks a free date. On the vendor Inbox (**Pending**), **Accept** and enter a LYD quote. The existing `accept_booking_request` RPC records 10% unpaid commission. Decline/complete stay on the other filters.
5. **Complete → review** — Vendor marks the request **Complete**. The couple sees **Leave a review** only then. Hidden reviews stay off the public vendor page.

Vendor dashboard overview: pending requests, unpaid commission owed, photo count, next booked dates.

### Tests

```bash
flutter test
flutter analyze
```

## 3. Admin (Next.js)

```bash
cd admin
cp .env.example .env.local
# Same SUPABASE URL + anon key as Flutter (NEXT_PUBLIC_*)

npm install
npm run dev
```

Open http://localhost:3000 — only users with `profiles.role = 'admin'` can access Dashboard / Vendors / Commissions / Reports.

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

## Demo seed

14 approved vendors across categories in Tripoli and Benghazi, one **pending** vendor (`قاعة الياسمين`) for the approve flow, sample photos, one completed booking + review (with unpaid 10% commission), one accepted booking with unpaid commission, one pending booking, two open reports (vendor + review), and an admin profile. See `supabase/seed.sql`.
