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
  legal-pages/         # Public privacy/terms for GitHub Pages (store URLs)
  tool/check_store_env.dart
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

CI runs `flutter analyze lib test` and `flutter test` on pull requests and pushes to `main` (no secrets, no live Dahr LY). Latest security/integrity notes: [`docs/AUDIT.md`](docs/AUDIT.md).

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

`.env` is not a Flutter asset (it is gitignored, so bundling it would break `flutter test` on a fresh clone). Pass real keys with `--dart-define-from-file=.env`. Store / Play builds must fail closed if that file is missing, still has placeholders, points at the wrong project, or looks like `service_role` — run `dart run tool/check_store_env.dart` first.

`supabase_flutter` `initialize()` uses `url` + `publishableKey` (the anon/publishable key, not `service_role`).

## 1. Supabase

Migrations (applied in filename order):

- `supabase/migrations/20260328000001_init_schema.sql` — core schema, RLS, `vendor-photos` bucket
- `supabase/migrations/20260903000001_booking_commission.sql` — `quoted_amount_lyd`, 10% platform fee, `accept_booking_request` RPC
- `supabase/migrations/20260904010000_customer_pays_dahr_fee.sql` — couple pays Dahr 10% by bank transfer; `platform_settings` + `commission_transfer_notes`. **Git-only — Syber applies live. Do not `db push` from the app PR.**
- `supabase/migrations/20260903120000_revoke_anon_definer_rpcs.sql` — split public-read RLS; revoke anon EXECUTE on admin/vendor helpers (already applied on live Dahr LY)
- `supabase/migrations/20260903140000_delete_own_account.sql` — `delete_own_account` RPC (self-serve account deletion)
- `supabase/migrations/20260903184000_overnight_security_hardening.sql` — revoke `reject_booking_if_date_booked` (trigger only); replace `profile_public` with `security_invoker=true` view of `id,full_name`; `profiles_select_public_names` for review/vendor/booking display names (already applied on live Dahr LY)
- `supabase/migrations/20260903190000_freeze_admin_role_and_private_profile_rows.sql` — freeze `profiles.role` (non-admins cannot self-promote); drop `profiles_select_public_names`; display names via `private.public_profile_rows()` + `profile_public` invoker/barrier view. **Already on live** (Syber’s two migrations); this repo file is combined so local `db reset` matches. Do **not** re-apply on Dahr LY. Does not touch `vendor-photos`.
- `supabase/migrations/20260903210000_scope_booking_updates_and_insert_only_reviews.sql` — consumers cannot UPDATE bookings; reviews are insert-only for authors (admin hide only)
- `supabase/migrations/20260903230000_booking_integrity_guards.sql` — booking status machine, one held date per vendor, accept marks availability, approved-vendor insert, `is_hidden`/`view_count` locks. **Not yet on live** — apply with `supabase db push` (do not re-push the already-live files above).
- `supabase/migrations/20260904000000_admin_audit_log_and_atomic_moderation.sql` — append-only `admin_audit_log` + `log_admin_action`; `hide_review_and_close_report` does both moderation writes in one transaction. **Not yet on live.**
- `supabase/migrations/20260904010000_guest_read_policies_without_helper_execute.sql` — limits every `is_admin()` / `owns_vendor()` policy to the `authenticated` role. **Not yet on live — this one unbreaks guest browse.**

**Security note:** Admin/vendor helpers (`is_admin`, `owns_vendor`, accept/commission RPCs, trigger functions including `reject_booking_if_date_booked`) are not anon RPCs — `authenticated` only, or no client EXECUTE. Do **not** re-grant `is_admin` / `owns_vendor` to anon (live once had `grant_rls_helpers_to_anon`; that must stay revoked).

Because anon has no EXECUTE on those helpers, no policy a **guest** is planned against may call them: the privilege is checked while the query is prepared, before any row or any `OR` branch is considered, so one such policy makes the whole table unreadable for guests. Keep guest-readable policies helper-free (`is_approved = true`, `NOT is_hidden`) and put owner/admin reads in a separate `TO authenticated` policy. Guest browse (approved vendors, photos, availability, review lists, display names via `profile_public`, and `increment_vendor_views`) is verified this way.

### Local (`supabase start`)

```bash
# From repo root
supabase start
supabase status          # API URL + anon (publishable) key
supabase db reset        # applies all migrations + seed.sql
```

Copy the printed **API URL** (`http://127.0.0.1:54321`) and **anon/publishable** key into `.env` and `admin/.env.local`.

Local Email OTP: Inbucket at http://127.0.0.1:54324 (`enable_confirmations = false` in `supabase/config.toml`). Flutter and admin sign-in are **Email OTP only** (no SMS / phone-first path). Do not enable SMS for store submit.

Seeded local admin: `admin@dahr.ly` (password `password123` only if you enable password auth). Prefer Email OTP via Inbucket. Couple demo: `couple@dahr.ly`.

### Cloud: Dahr LY

Live project: **Dahr LY**, ref `cccusktgxrizfwpixddu`, region `eu-west-1`.  
URL: `https://cccusktgxrizfwpixddu.supabase.co`

```bash
supabase link --project-ref cccusktgxrizfwpixddu
supabase db push         # do not re-push overnight_security_hardening or freeze_admin_role_and_private_profile_rows — already on Dahr LY
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

Arabic is the default locale (RTL). Switch language on the first screen. Sign-in is Email OTP (same as admin). Android allows HTTP **only** to `10.0.2.2` / `127.0.0.1` / `localhost` (local `supabase start`); production Dahr LY is HTTPS.

Identifiers: Android `applicationId` and iOS bundle id are **`com.dahr.dahr`** (org `com.dahr` + project name `dahr`). See **Store packaging** below.

## Try the vendor product flow

Guest browse of Discover stays open (approved listings only; admin/vendor helpers are not anon RPCs). Favorites, booking requests, and reviews still require sign-in (router redirects to login and returns afterward).

1. **Onboarding** — Sign in, choose **I'm a vendor** (or **Become a vendor** on Profile). Fill business name, category, city, WhatsApp, description, and price range (LYD). Submit. The listing waits for admin approval (`is_approved`).
2. **Photos** — Profile → Vendor tools → **Manage photos**, or Dashboard → **Manage photos**. Upload to the `vendor-photos` bucket, drag to reorder (first photo is the cover), delete.
3. **Calendar** — **Manage availability**. Tap a date to mark it booked or available. Booked dates show on the couple booking screen and cannot be selected.
4. **Inbox accept with quote** — A couple opens a vendor → **Request booking**, picks a free date. On the vendor Inbox (**Pending**), **Accept** and enter a LYD quote. The existing `accept_booking_request` RPC records 10% unpaid platform fee. The **couple** pays that fee to Dahr by bank transfer. Decline/complete stay on the other filters.
5. **Complete → review** — Vendor marks the request **Complete**. The couple sees **Leave a review** only then. Hidden reviews stay off the public vendor page.

Vendor dashboard overview: pending requests, Dahr fee status (not an amount the vendor owes), photo count, next booked dates.

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

- Privacy: `http://localhost:3000/privacy` (store URL: `https://mohammedalariyibi-afk.github.io/Dahr/privacy`)
- Terms: `http://localhost:3000/terms` (store URL: `https://mohammedalariyibi-afk.github.io/Dahr/terms`)

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
| Theme | Material 3 in `lib/core/theme` (Ice Blue glass on Slate 950, LYD) |
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
| Privacy | `https://mohammedalariyibi-afk.github.io/Dahr/privacy` |
| Terms | `https://mohammedalariyibi-afk.github.io/Dahr/terms` |
| Account deletion | Profile → Delete account |
| Auth to declare | Email OTP only |
| IAP / payments | None |
| Contact | WhatsApp + `mohammedalariyibi@gmail.com` |
| Languages | Arabic + English |
| Currency | LYD |

In the Flutter app the legal documents are also under Profile → Privacy policy / Terms of use (`/legal/privacy`, `/legal/terms`).

**Account deletion (guideline 5.1.1(v)):** signed-in users delete from **Profile → Delete account** (confirm dialog). The app calls `delete_own_account` (`auth.uid()` only; cascade `profiles`, vendor listing/photos as FKs allow). Fallback: email `mohammedalariyibi@gmail.com` from the same address as the account.

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
#    - release signing reads gitignored android/key.properties when present;
#      otherwise debug signing (local flutter run --release)

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
# Play (AAB) — drop android/key.properties locally, then:
dart run tool/check_store_env.dart
flutter build appbundle --dart-define-from-file=.env

# App Store (IPA) — Xcode Team on Mohammed’s Mac; iPhone only
dart run tool/check_store_env.dart
flutter build ipa --dart-define-from-file=.env
```

`.env` must be Dahr LY (`https://cccusktgxrizfwpixddu.supabase.co`) + anon/publishable key. Never Zeen. Never `service_role`. Gradle uses `signingConfigs.release` when `android/key.properties` exists; otherwise debug signing so `flutter run --release` still works.

## Demo seed

14 approved vendors across categories in Tripoli and Benghazi, one **pending** vendor (`قاعة الياسمين`) for the approve flow, sample photos, one completed booking + review (with unpaid 10% commission), one accepted booking with unpaid commission, one pending booking, two open reports (vendor + review), and an admin profile. See `supabase/seed.sql`.
