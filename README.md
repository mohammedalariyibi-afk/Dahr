# Dahr — Wedding Booking & Vendor Discovery (Libya)

Cross-platform Flutter marketplace connecting couples with wedding vendors in Libya, plus a Next.js admin dashboard. Backend is **Supabase** (Auth, Postgres, Storage, RLS).

> **Important:** Do **not** reuse the existing Zeen Supabase project. Use local `supabase start`, or the dedicated **Dahr LY** cloud project (never Zeen).

## Repo layout

```
dahr/
  lib/                 # Flutter app (feature-first)
  test/
  android/ ios/        # Platform stubs (applicationId / bundle id com.dahr.dahr)
  admin/               # Next.js admin (App Router + Tailwind)
  supabase/
    migrations/        # Schema + RLS + storage + commission
    seed.sql           # Demo vendors (Tripoli & Benghazi)
    config.toml
  docs/store-listing.md
  STORE.md             # App Store + Google Play submit checklist
  .env.example         # Flutter env names (copy to gitignored .env)
  admin/.env.example   # Admin NEXT_PUBLIC_* names (copy to .env.local)
  README.md
```

## Prerequisites

- Flutter SDK 3.47+ ([install](https://docs.flutter.dev/get-started/install)) — Dart `>=3.5.0 <4.0.0`; photo reorder uses `onReorderItem` (3.44+)
- Node.js 20+ (admin)
- [Supabase CLI](https://supabase.com/docs/guides/cli) (local backend)
- Docker (for local Supabase)

CI runs `flutter analyze lib test` and `flutter test` on pull requests and pushes to `main` (no secrets, no live Dahr LY).

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
- `supabase/migrations/20260903120000_revoke_anon_definer_rpcs.sql` — split public-read RLS; revoke anon EXECUTE on admin/vendor helpers (already applied on live Dahr LY)
- `supabase/migrations/20260903140000_delete_own_account.sql` — `delete_own_account` RPC (self-serve account deletion)

**Security note:** Guest browse still works (approved vendors, photos, availability, and `increment_vendor_views`). Admin/vendor helpers (`is_admin`, `owns_vendor`, accept/commission RPCs, trigger functions) are not anon RPCs — `authenticated` only, or no client EXECUTE.

### Local (`supabase start`)

```bash
# From repo root
supabase start
supabase status          # API URL + anon (publishable) key
supabase db reset        # applies all migrations + seed.sql
```

Copy the printed **API URL** (`http://127.0.0.1:54321`) and **anon/publishable** key into `.env` and `admin/.env.local`.

Local Email OTP: Inbucket at http://127.0.0.1:54324 (`enable_confirmations = false` in `supabase/config.toml`). **Product auth is Email OTP only** (store listings and Saturday ship). That login UI lands with [PR #11](https://github.com/mohammedalariyibi-afk/Dahr/pull/11). Until #11 merges, `main` still shows phone-first + **Continue with email**. Do not enable Twilio/SMS for store submit.

Seeded local admin: `admin@dahr.ly` (password `password123` only if you enable password auth). Prefer Email OTP via Inbucket. Couple demo: `couple@dahr.ly`.

### Cloud: Dahr LY

Live project: **Dahr LY**, ref `cccusktgxrizfwpixddu`, region `eu-west-1`.  
URL: `https://cccusktgxrizfwpixddu.supabase.co`

```bash
supabase link --project-ref cccusktgxrizfwpixddu
supabase db push         # applies delete_own_account if init + booking_commission + revoke_anon_definer_rpcs are already on Dahr LY
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

flutter pub get
flutter run --dart-define-from-file=.env
```

Arabic is the default locale (RTL). Switch language on the first screen. Android allows HTTP **only** to `10.0.2.2` / `127.0.0.1` / `localhost` (local `supabase start`); production Dahr LY is HTTPS.

Identifiers: Android `applicationId` and iOS bundle id are **`com.dahr.dahr`** (org `com.dahr` + project name `dahr`). See **Store packaging** below.

## Try the vendor product flow

Guest browse of Discover stays open (approved listings only; admin/vendor helpers are not anon RPCs). Favorites, booking requests, and reviews still require sign-in (router redirects to login and returns afterward).

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

## Store packaging (Apple / Google Play)

Full checklist: **[STORE.md](STORE.md)**. Placeholder AR+EN listing copy: **[docs/store-listing.md](docs/store-listing.md)**.

Ship target: Saturday 5 September 2026. Mohammed signs and uploads; this repo does not contain keystores, `.p12`, or `key.properties`.

| Field | Value |
|-------|--------|
| Org / bundle root | `com.dahr` |
| Android `applicationId` | `com.dahr.dahr` |
| iOS bundle identifier | `com.dahr.dahr` |
| Privacy | `{ADMIN_ORIGIN}/privacy` |
| Terms | `{ADMIN_ORIGIN}/terms` |
| Account deletion | Profile → Delete account |
| Auth to declare | Email OTP only (see PR #11) |
| IAP / payments | None |
| Contact | WhatsApp + `mohammedalariyibi@gmail.com` |
| Languages | Arabic + English |
| Currency | LYD |

In the Flutter app the legal documents are also under Profile → Privacy policy / Terms of use (`/legal/privacy`, `/legal/terms`). Those **web routes are on `main`** (they do not depend on PR #11). Email OTP-only login **does** live in PR #11 — merge it before the store binary if the listing says Email OTP only.

**Account deletion (guideline 5.1.1(v)):** signed-in users delete from **Profile → Delete account** (confirm dialog). The app calls `delete_own_account` (`auth.uid()` only). Fallback: email `mohammedalariyibi@gmail.com` from the same address as the account.

Copy on the legal pages is a **starting policy**, not law-firm work. Operator: Mohammed Alariyibi. Backend: Dahr LY, `eu-west-1`. No card data is stored.

Screenshots to capture: Discover, vendor detail, booking request, vendor inbox/dashboard, login.

### Refresh `android/` and `ios/` without wiping Dart

Platform folders are complete Flutter 3.47 stubs (Kotlin DSL, Xcode project, default icons). **Never delete `lib/` or `test/`.** Do not pass `--overwrite` unless you have just backed up the Dahr customizations listed in step 3.

```bash
# From repo root. Flutter 3.47+ (CI pins 3.47.2).

# 1. Back up files this repo customizes (safe even if create skips them):
mkdir -p /tmp/dahr-platform-custom
cp android/app/src/main/AndroidManifest.xml /tmp/dahr-platform-custom/
cp android/app/src/main/res/xml/network_security_config.xml /tmp/dahr-platform-custom/
cp android/app/build.gradle.kts /tmp/dahr-platform-custom/
cp ios/Runner/Info.plist /tmp/dahr-platform-custom/

# 2. Fill in any missing template files. Leaves lib/, test/ (except a dummy
#    test/widget_test.dart), and pubspec.yaml alone:
flutter create . --project-name dahr --org com.dahr --platforms=android,ios

#    If create added test/widget_test.dart (counter smoke test), delete it.
#    This repo's tests are test/unit/ and test/widget/. Do not pass --overwrite.

# 3. If a template reset your customizations, restore them. Required Dahr bits:
#    - applicationId / namespace / PRODUCT_BUNDLE_IDENTIFIER = com.dahr.dahr
#    - Android label "Dahr"; INTERNET on the main manifest
#    - res/xml/network_security_config.xml (cleartext only for local Supabase)
#    - queries: https, http, com.whatsapp
#    - Info.plist: CFBundleDevelopmentRegion=ar, iPhone portrait, dahr URL scheme,
#      LSApplicationQueriesSchemes (whatsapp, https, http), camera/photo usage strings
#    - release signing stays debug in git; Mohammed adds a local key.properties to upload

# 4. Confirm identifiers:
grep applicationId android/app/build.gradle.kts
grep PRODUCT_BUNDLE_IDENTIFIER ios/Runner.xcodeproj/project.pbxproj
```

If `flutter create .` errors with “unable to detect the type of project”, `.metadata` is broken (`project_type: app` is required). Recover by creating a sibling project and copying platforms only:

```bash
flutter create /tmp/dahr-platform --project-name dahr --org com.dahr --platforms=android,ios
# Copy /tmp/dahr-platform/android and .../ios into the repo (not lib/ or pubspec.yaml).
# Copy /tmp/dahr-platform/.metadata over the repo .metadata.
# Re-apply the customizations in step 3.
```

Do **not** run `flutter create` without `--platforms=android,ios` if you want to avoid extra desktop/web folders.

### Build artifacts (Mohammed uploads)

```bash
# Play (AAB) — requires local signing for a store upload
flutter build appbundle --dart-define-from-file=.env

# App Store (IPA) — Xcode Team on Mohammed’s Mac
flutter build ipa --dart-define-from-file=.env
```

Use Dahr LY keys in `.env`. Never Zeen. Never `service_role`.

## Demo seed

14 approved vendors across categories in Tripoli and Benghazi, one **pending** vendor (`قاعة الياسمين`) for the approve flow, sample photos, one completed booking + review (with unpaid 10% commission), one accepted booking with unpaid commission, one pending booking, two open reports (vendor + review), and an admin profile. See `supabase/seed.sql`.
