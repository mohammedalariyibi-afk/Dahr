# Saturday store submit — Dahr

Ship target: **Saturday 5 Sep 2026** (Africa/Tripoli). Screenshots and listing copy are on `main`; this is the operator runbook.

## Before you open the consoles

1. Pull latest `main`.
2. Confirm `.env` / `admin/.env.local` point at **Dahr LY** (`cccusktgxrizfwpixddu`) with **anon key only** (never commit; never put `service_role` in the app).
3. **Push the pending migrations** — `supabase link --project-ref cccusktgxrizfwpixddu && supabase db push`. Three files are not on live yet (booking integrity, admin audit log, guest read policies). The guest-read one is required: without it a signed-out user gets an error instead of Discover. Do **not** re-push the already-live overnight / freeze-admin files.
4. **Smoke the signed-out app** — open Discover without signing in and confirm listings, a vendor page, its photos, and its reviews (with author names) all load. This is the first screen a store reviewer sees.
5. Preferred: one **quoted-booking smoke** (accept with amount → commission fields). Do not block the whole submit on this if time is tight — note result in the room.
6. Privacy / terms public URLs must resolve:
   - `{ADMIN_ORIGIN}/privacy`
   - `{ADMIN_ORIGIN}/terms`
   - Routes exist on `main`; hosting still needs a deploy (Vercel or equivalent). In-app `/legal/privacy` and `/legal/terms` cover Profile links meanwhile.
7. Have WhatsApp business number + email `mohammedalariyibi@gmail.com` for store support / contact fields.
8. Optional for 10% collection path: bank / WhatsApp details for offline commission (not required for store listing).
2. Confirm `.env` / `admin/.env.local` point at **Dahr LY** (`https://cccusktgxrizfwpixddu.supabase.co`) with **anon key only** (never commit; never put `service_role` in the app). Run `dart run tool/check_store_env.dart` before the Play AAB.
3. Preferred: one **quoted-booking smoke** (accept with amount → commission fields). Do not block the whole submit on this if time is tight — note result in the room.
4. Privacy / terms public URLs must resolve (GitHub Pages, not Vercel / not dahr.ly):
   - `https://mohammedalariyibi-afk.github.io/Dahr/privacy`
   - `https://mohammedalariyibi-afk.github.io/Dahr/terms`
   - After merge: if those 404, set **Settings → Pages → Source: GitHub Actions**. In-app `/legal/privacy` and `/legal/terms` do **not** satisfy the store fields.
5. Have WhatsApp business number + email `mohammedalariyibi@gmail.com` for store support / contact fields.
6. Optional for 10% collection path: paste real Dahr bank details in admin Settings after Syber applies `20260904005000_customer_pays_dahr_fee.sql` (not required for store listing).

## Assets already in repo

| Asset | Path |
|-------|------|
| Phone screenshots (6) | `docs/store-shots/01` … `06` |
| MD5s | `docs/store-shots/README.md` |
| Listing copy AR+EN | `docs/store-listing.md` |
| Full store checklist | `STORE.md` |

Upload order suggestion: email OTP → OTP verify → Discover → vendor detail → booking request → vendor inbox.

## Google Play

1. App **Dahr**, package `com.dahr.dahr`, Arabic default + English listing.
2. Paste short/long descriptions from `docs/store-listing.md`.
3. Upload phone shots from `docs/store-shots/play-1080x1920/` (Play) or `docs/store-shots/ios-1320x2868/` (App Store 6.9″). Upload Play **1024×500** feature graphic: `docs/store-shots/play-feature-graphic-1024x500.png`.
4. Privacy URL `https://mohammedalariyibi-afk.github.io/Dahr/privacy`. Data safety: account deletion in-app (Profile).
5. Contact: WhatsApp + `mohammedalariyibi@gmail.com`.
6. No IAP / no ads SDKs.
7. Build the AAB on Mohammed’s machine with `./tool/release.sh` (requires `android/key.properties`, store env preflight, `flutter build appbundle --release --dart-define-from-file=.env`). Release signing is fail-closed — it will not debug-sign. Do not pass `-PallowDebugReleaseSigning=true`.

## App Store Connect

1. Bundle id **`com.dahr.dahr`**; Arabic primary + English localization.
2. Paste subtitle / keywords / description from `docs/store-listing.md`.
3. Upload iPhone shots from `docs/store-shots/ios-1320x2868/`. Target is **iPhone only** (`TARGETED_DEVICE_FAMILY = 1` on `main`) — do not enable iPad; no 13″ iPad screenshots.
4. Privacy `https://mohammedalariyibi-afk.github.io/Dahr/privacy`, Terms `https://mohammedalariyibi-afk.github.io/Dahr/terms`.
5. Review notes: **Email OTP only** (code is emailed; operator reachable). Sign in with Apple is **not** required. WhatsApp for vendor contact; no IAP; LYD; account deletion in Profile.
6. Archive (full runbook: `STORE.md` → **iOS archive**):
   - Open **`ios/Runner.xcworkspace`** (not `.xcodeproj` alone). Flutter 3.47 uses SPM — no `Podfile`, no `pod install`.
   - Runner → Signing & Capabilities: Team = Mohammed’s Apple Developer team, bundle `com.dahr.dahr`, **Automatically manage signing ON**. Pick Team in Xcode; do not put a team id in git.
   - Confirm iPhone only (`TARGETED_DEVICE_FAMILY = 1`). Do not flip back to iPad.
   - Same dart-defines as Play: `dart run tool/check_store_env.dart` then `flutter build ipa --dart-define-from-file=.env` (Dahr LY anon only). To Archive in Xcode, run `flutter build ios --release --dart-define-from-file=.env --config-only` first so `Generated.xcconfig` has the defines.
   - Upload via **Organizer** or **Transporter**. Export compliance is already `ITSAppUsesNonExemptEncryption = false`.
   - Do **not** commit `DEVELOPMENT_TEAM`, team ids, `.p12`, or provisioning profiles. If Xcode dirties `project.pbxproj`, revert it.

## Do not

- Commit `.env` / service role keys
- Commit `DEVELOPMENT_TEAM`, Apple team ids, `.p12`, or provisioning profiles (leave Team unset in the pbxproj)
- `db push` migrations already live on Dahr LY (e.g. booking/review scope from #16)
- Re-grant `is_admin` / `owns_vendor` to `anon` to "fix" a guest read — that is what the guest-read migration avoids. **Do** push `20260903230000_booking_integrity_guards.sql` once if it is not on Dahr LY yet.
- Use Sidra LY or the paused older `dahr` Supabase project

## Room signal

When listing is submitted (or blocked), ping **App launch** with: consoles used, privacy URL used, and smoke pass/fail.
