Saturday operator runbook: [`docs/store-submit-checklist.md`](docs/store-submit-checklist.md).

# Dahr store packaging — App Store & Google Play

Ship target: **Saturday 5 September 2026**. Operator: Mohammed Alariyibi.

This file is the submit checklist. Listing copy lives in [`docs/store-listing.md`](docs/store-listing.md). Platform refresh commands are in the README **Store packaging** section.

**Do not** put signing secrets, keystores, or `service_role` keys in git. **Do not** add payment SDKs, IAP, or Google Play Billing. **Do not** use the Zeen Supabase project.

## Identifiers

| Item | Value |
|------|--------|
| Organization (`flutter create --org`) | `com.dahr` |
| Flutter project name | `dahr` |
| Android `applicationId` / `namespace` | `com.dahr.dahr` |
| iOS `PRODUCT_BUNDLE_IDENTIFIER` | `com.dahr.dahr` |
| iOS test target | `com.dahr.dahr.RunnerTests` |
| Display name | Dahr / دهر |
| Version (today) | `0.1.0+1` (`pubspec.yaml` → `versionName` / `CFBundleShortVersionString` + `versionCode` / `CFBundleVersion`) |

`com.dahr` is the reverse-DNS **org**. Flutter concatenates org + project name, so the store bundle id / application id to register is **`com.dahr.dahr`**. Keep Android and iOS on that same id.

## Public URLs (reviewers)

Use the GitHub Pages copies (same AR+EN starting policy as the app / admin). **Do not** put `dahr.ly` or Vercel in the store consoles — those origins 404 today.

| Field | URL |
|-------|-----|
| Privacy policy | `https://mohammedalariyibi-afk.github.io/Dahr/privacy` |
| Terms of use | `https://mohammedalariyibi-afk.github.io/Dahr/terms` |

Static files live in `legal-pages/`. Merge to `main` runs [`.github/workflows/pages.yml`](.github/workflows/pages.yml). After merge, if Pages is still 404: GitHub → **Settings → Pages → Source: GitHub Actions**.

In-app copies stay at Profile → Privacy policy / Terms of use (`/legal/privacy`, `/legal/terms`). Those do **not** satisfy Play / App Store public-URL fields.

Admin App Router `/privacy` and `/terms` still work locally (`http://localhost:3000/privacy`). They are not the store URLs.

## Auth (what to declare)

Product decision: **Email OTP only**. No phone-first login, no SMS/Twilio, no passwords in the consumer app, no Sign in with Apple required (Email OTP is not a third-party social login).

Login on `main` is Email OTP only (merged [PR #11](https://github.com/mohammedalariyibi-afk/Dahr/pull/11)). Privacy/terms and Profile account deletion are also on `main`.

Reviewer sign-in: create a Dahr LY user whose inbox you control. In App Review / Play notes, say a one-time code is emailed. Stay reachable during review. Do not add an OTP backdoor.

## Account deletion (App Store 5.1.1(v) + Play)

Signed-in users: **Profile → Delete account** (confirm dialog). Calls `delete_own_account` (auth user + cascaded profile/listing data). No support ticket required.

Fallback if the in-app flow fails: email `mohammedalariyibi@gmail.com` from the same address as the account.

Declare this in App Store Connect (App Privacy + review notes) and Play Console (Data safety + account deletion URL if asked). The public privacy page describes the same flow.

## Contact

| Channel | Use |
|---------|-----|
| WhatsApp | Vendor contact in-app (`wa.me` from the listing). Store **support** contact should also be WhatsApp — paste Mohammed’s business number in App Store Connect and Play Console (not committed here). |
| Email | `mohammedalariyibi@gmail.com` (deletion fallback + legal pages) |

No in-app chat. No IAP support URL required.

## What the app does **not** include

- In-app purchases, subscriptions, Stripe, Apple IAP, Google Play Billing
- Card collection UI or payment SDKs
- Advertising / third-party analytics / crash SDKs
- Push notifications, maps, SMS login

Couples pay vendors **off-platform** (often WhatsApp) for the rest of the quote. Currency shown in-app is **LYD**. Couples pay Dahr a **10% platform fee by online bank transfer** (recorded as unpaid until admin “Mark paid” / “Waive”). That is not an IAP. Mohammed pastes real bank details in admin Settings.

## Languages, locale, devices

- Languages: **Arabic** (default, RTL) and **English**
- Prices: **LYD**
- iOS orientations: iPhone **portrait**
- iOS target is **iPhone only** (`TARGETED_DEVICE_FAMILY = 1` in `ios/Runner.xcodeproj/project.pbxproj`). App Store will not ask for 13″ iPad screenshots.

## Packaged screenshots

Play phones: `docs/store-shots/play-1080x1920/`. App Store 6.9″: `docs/store-shots/ios-1320x2868/`.


Ready-to-upload phone frames live in `docs/store-shots/` (full-color Ice Blue UI + vivid venue photos):

1. `01-email-otp.png`
2. `02-otp-verify.png`
3. `03-discover.png`
4. `04-vendor-detail.png`
5. `05-booking-request.png`
6. `06-vendor-inbox.png`

See `docs/store-shots/README.md` for MD5s. Play feature graphic is already in that folder.

## Screenshots to capture (both stores)

Use a real device or simulator with Arabic default, then repeat key screens in English if you localize the listing.

Minimum scenes (phone, 6.7″ / 6.9″ plus Play phone):

1. **Discover** — vendor grid/list (Tripoli or Benghazi, approved listings)
2. **Vendor detail** — photos, price range in LYD, WhatsApp button
3. **Booking request** — date + message form
4. **Vendor inbox / dashboard** — pending requests and/or dashboard stats
5. **Login** — Email OTP

Play also wants a **1024×500** feature graphic — packaged as `docs/store-shots/play-feature-graphic-1024x500.png`. App Store wants the current required iPhone sizes (check Connect — they change). Optional: short preview video of Discover → vendor → WhatsApp.

Do not screenshot debug banners, `.env` URLs, or `127.0.0.1`.

## Google Play Console

1. Create app **Dahr**. Package name **`com.dahr.dahr`** (must match `applicationId`; cannot change later).
2. Default language: Arabic. Add English listing (copy in `docs/store-listing.md`).
3. Category: **Events** or **Lifestyle**. Tags: wedding, booking, Libya.
4. Privacy policy URL: `https://mohammedalariyibi-afk.github.io/Dahr/privacy`.
5. Contact: WhatsApp number + `mohammedalariyibi@gmail.com`.
6. **Data safety** (declare; do not invent extra trackers):
   - Account: email (Email OTP)
   - User-generated content: vendor photos, booking messages, reviews
   - App activity: bookings, favorites, listing view counts
   - Encrypted in transit (HTTPS to Dahr LY)
   - Not sold
   - Users can delete the account in-app
7. Content rating questionnaire (wedding marketplace, no user-to-user chat inside the app; WhatsApp is external).
8. Target audience: **18+** (adults arranging a wedding).
9. Ads: **No**. In-app products: **No**.
10. Photos/videos permission: vendors upload listing photos (`image_picker`).
11. Sign the **upload** AAB with Mohammed’s upload keystore (see Signing). Gradle is **fail-closed**: `flutter build appbundle --release` / `assembleRelease` will not debug-sign. They fail if `android/key.properties` is missing, a required key is empty, or `storeFile` does not exist. Build with `./tool/release.sh` (never pass `-PallowDebugReleaseSigning=true`).
12. Production track → submit. Mohammed must accept Play policies and pay the developer fee if not already done.

```bash
./tool/release.sh
# Output: build/app/outputs/bundle/release/app-release.aab
```

`.env` must use `SUPABASE_URL=https://cccusktgxrizfwpixddu.supabase.co` and the Dahr LY **anon / publishable** key (`SUPABASE_ANON_KEY`, alias `SUPABASE_PUBLISHABLE_KEY`). The preflight fails on a missing file, `.env.example` placeholders, the wrong project, or a `service_role` key. Never Zeen.

## App Store Connect

1. Register bundle id **`com.dahr.dahr`** in the Apple Developer account (Identifiers).
2. Create app **Dahr**. Bundle id `com.dahr.dahr`. SKU e.g. `dahr-ios`. Primary language Arabic; add English.
3. Privacy policy URL: `https://mohammedalariyibi-afk.github.io/Dahr/privacy`. Terms: `https://mohammedalariyibi-afk.github.io/Dahr/terms` (App Store Review Information and/or EULA / license URL).
4. App Privacy nutrition labels — same facts as Play Data safety. Account deletion: in-app Profile path.
5. Age rating: 18+ / the questionnaire equivalent for a wedding marketplace.
6. Pricing: **Free**. In-app purchases: **none**.
7. Review notes:
   - Demo: guest Discover works without login; bookings need Email OTP
   - Demo account email + “code is emailed; operator is available”
   - WhatsApp opens an external app
   - No IAP; off-platform payment
   - **Email OTP only** — Sign in with Apple is **not** required
8. Export compliance: HTTPS only, no custom encryption. `ITSAppUsesNonExemptEncryption = false` is already in `ios/Runner/Info.plist` (Organizer / Transporter will not ask again).
9. Sign in with Apple: **not required** for Email OTP-only.
10. Archive + upload: follow **iOS archive** below. Do not paste a team id into git.

## iOS archive (Mohammed — App Developer)

Saturday App Store submit. Do this on Mohammed’s Mac. Flutter **3.47** uses **Swift Package Manager** — there is **no** `Podfile`; do not run `pod install`.

1. Open **`ios/Runner.xcworkspace`**. Do not open `ios/Runner.xcodeproj` alone (SPM packages will be missing).
2. Select the **Runner** target → **Signing & Capabilities**:
   - **Team** = Mohammed’s Apple Developer team (the one that owns this Apple ID / `com.dahr.dahr`). Pick it in the Xcode UI; do not type a team id into the repo.
   - **Bundle Identifier** = `com.dahr.dahr`
   - **Automatically manage signing** = **ON**
3. Confirm **iPhone only**. `TARGETED_DEVICE_FAMILY = 1` is already on `main` (Debug / Release / Profile). Do **not** switch the destination to iPad or “iPhone + iPad” — App Store would then require 13″ iPad screenshots.
4. Release must use `--dart-define-from-file=.env` with **Dahr LY anon only** (same rule as the Play AAB). From the repo root:

   ```bash
   dart run tool/check_store_env.dart
   flutter build ipa --dart-define-from-file=.env
   ```

   `.env` must be `SUPABASE_URL=https://cccusktgxrizfwpixddu.supabase.co` plus the Dahr LY **anon / publishable** key. Never Zeen. Never `service_role`.

   **If you Archive in Xcode instead of `flutter build ipa`:** write the same defines into the iOS config first, then archive. Otherwise the IPA ships **without** Dahr LY dart-defines:

   ```bash
   dart run tool/check_store_env.dart
   flutter build ios --release --dart-define-from-file=.env --config-only
   # then Xcode: Product → Archive
   ```

5. Upload with **Organizer** (Window → Organizer → Distribute App) or **Transporter**. Export compliance is already `ITSAppUsesNonExemptEncryption = false`.
6. **Do not commit** `DEVELOPMENT_TEAM`, any Apple team id, `.p12`, or provisioning profiles. Leave Team **unset** in `ios/Runner.xcodeproj/project.pbxproj` so Xcode fills it on this Mac only. If Signing & Capabilities dirties that pbxproj, revert the file before you push. `.p12` / `.mobileprovision` are gitignored.

Reviewer notes (Connect): Email OTP only; a one-time code is emailed; operator reachable. Sign in with Apple is not required.

## Signing (Mohammed only)

Android (Play):

1. Generate an upload keystore **on Mohammed’s machine** (not in this repo):

   ```bash
   keytool -genkey -v -keystore ~/dahr-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias dahr
   ```

2. Copy `android/key.properties.example` to `android/key.properties` (gitignored) and fill real values:

   ```
   storePassword=...
   keyPassword=...
   keyAlias=dahr
   storeFile=/absolute/path/to/dahr-upload.jks
   ```

   `storeFile` must be an **absolute** path (Gradle does not expand `~`).

3. Gradle reads that file and signs release with `signingConfigs.release`. It is **fail-closed**: if the file is missing, `storeFile` / `storePassword` / `keyAlias` / `keyPassword` is empty, or `storeFile` does not exist, `flutter build appbundle` / `assembleRelease` **fails** (it does **not** fall back to debug). The error points at `android/key.properties.example` and this section. **Do not commit** `key.properties` or the `.jks`.

   Play AAB (requires `android/key.properties`, runs `dart run tool/check_store_env.dart`, then `flutter build appbundle --release --dart-define-from-file=.env`; never passes the debug hatch):

   ```bash
   ./tool/release.sh
   ```

   Local `flutter run --release` without an upload keystore **only** (never for Play / never in `tool/release.sh`):

   ```bash
   ORG_GRADLE_PROJECT_allowDebugReleaseSigning=true flutter run --release --dart-define-from-file=.env
   # same hatch: -PallowDebugReleaseSigning=true
   ```

iOS: Team, Automatic signing, and certificates stay on Mohammed’s Mac. Follow **iOS archive** above. **Never** commit `DEVELOPMENT_TEAM`, a team id, `.p12`, or provisioning profiles.

## Privacy / permissions the stores will ask about

| Permission / API | Why |
|------------------|-----|
| Internet | Supabase Auth, listings, photos |
| Photo library / camera | Vendor listing photos (`image_picker`). Purpose strings are in `ios/Runner/Info.plist`. |
| Queries WhatsApp / https | `url_launcher` + `wa.me` |
| Local cleartext | Android `network_security_config.xml` allows HTTP **only** to `10.0.2.2`, `127.0.0.1`, `localhost` for emulator → local `supabase start`. Production Dahr LY is HTTPS. |

## PR / branch notes

- Packaging PR targets **`main`**.
- Privacy, terms, and Profile account deletion: **`main`** (merged #10).
- Email OTP-only login: **`main`** (merged #11). Store listing copy matches the app.
