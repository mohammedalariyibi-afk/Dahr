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

### Guest browse

Anyone can open Discover and vendor details. Favorites, booking requests, and reviews require sign-in (router redirects to login and returns afterward).

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

Open http://localhost:3000 — only users with `profiles.role = 'admin'` can access Dashboard / Vendors / Reports.

Add Auth redirect URL: `http://localhost:3000/auth/callback`.

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

**In:** discovery, filters, favorites, booking requests, vendor dashboard/inbox/availability/photos, reviews after completed bookings, admin approve/verify/moderate.

**Out:** in-app payments, chat, push notifications, maps, package bundling.

Payments can attach later to `booking_requests` without restructuring the app.

## Demo seed

14 approved vendors across categories in Tripoli and Benghazi, sample photos, one completed booking + review, one pending booking, and an admin profile. See `supabase/seed.sql`.
