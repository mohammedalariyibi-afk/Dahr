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

Replace `{ADMIN_ORIGIN}` with the deployed Next.js admin origin (no trailing slash):

| Field | URL |
|-------|-----|
| Privacy policy | `{ADMIN_ORIGIN}/privacy` |
| Terms of use | `{ADMIN_ORIGIN}/terms` |

Those routes are **already on `main`** (admin App Router pages). In-app copies: Profile → Privacy policy / Terms of use (`/legal/privacy`, `/legal/terms`).

Local check: `http://localhost:3000/privacy` and `http://localhost:3000/terms`.

## Auth (what to declare)

Product decision: **Email OTP only**. No phone-first login, no SMS/Twilio, no passwords in the consumer app, no Sign in with Apple required (Email OTP is not a third-party social login).

| Branch | What reviewers will see |
|--------|-------------------------|
| This PR / current `main` | Legal URLs + in-app account deletion are present. Flutter login on `main` still has phone-first + “Continue with email” until **[PR #11](https://github.com/mohammedalariyibi-afk/Dahr/pull/11)** merges. |
| After PR #11 | Login is Email OTP only, matching this store copy. |

**Legal routes do not need PR #11.** Merge #11 before the Saturday binary if the listing says Email OTP only.

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

Couples pay vendors **off-platform** (often WhatsApp). Currency shown in-app is **LYD**. Vendors owe a 10% commission recorded in the database and collected **offline** by the operator (admin “Mark paid” / “Waive”). That is not an IAP.

## Languages, locale, devices

- Languages: **Arabic** (default, RTL) and **English**
- Prices: **LYD**
- iOS orientations: iPhone **portrait**; iPad all orientations (Flutter default is universal `TARGETED_DEVICE_FAMILY = 1,2`)
- For Saturday: either capture **iPad 13″** screenshots too, or set the Xcode target to **iPhone only** (`TARGETED_DEVICE_FAMILY = 1`) before archive so iPad screenshots are not required

## Screenshots to capture (both stores)

Use a real device or simulator with Arabic default, then repeat key screens in English if you localize the listing.

Minimum scenes (phone, 6.7″ / 6.9″ plus Play phone):

1. **Discover** — vendor grid/list (Tripoli or Benghazi, approved listings)
2. **Vendor detail** — photos, price range in LYD, WhatsApp button
3. **Booking request** — date + message form
4. **Vendor inbox / dashboard** — pending requests and/or dashboard stats
5. **Login** — Email OTP (after PR #11) or current login screen

Play also wants a **1024×500** feature graphic. App Store wants the current required iPhone sizes (check Connect — they change). Optional: short preview video of Discover → vendor → WhatsApp.

Do not screenshot debug banners, `.env` URLs, or `127.0.0.1`.

## Google Play Console

1. Create app **Dahr**. Package name **`com.dahr.dahr`** (must match `applicationId`; cannot change later).
2. Default language: Arabic. Add English listing (copy in `docs/store-listing.md`).
3. Category: **Events** or **Lifestyle**. Tags: wedding, booking, Libya.
4. Privacy policy URL: `{ADMIN_ORIGIN}/privacy`.
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
11. Sign the **upload** AAB with Mohammed’s upload keystore (see Signing). This repo uses debug signing only so `flutter run --release` works locally.
12. Production track → submit. Mohammed must accept Play policies and pay the developer fee if not already done.

```bash
flutter build appbundle --dart-define-from-file=.env
# Output: build/app/outputs/bundle/release/app-release.aab
```

Use Dahr LY `SUPABASE_URL` / `SUPABASE_ANON_KEY` in that `.env` (never Zeen, never `service_role`).

## App Store Connect

1. Register bundle id **`com.dahr.dahr`** in the Apple Developer account (Identifiers).
2. Create app **Dahr**. Bundle id `com.dahr.dahr`. SKU e.g. `dahr-ios`. Primary language Arabic; add English.
3. Privacy policy URL: `{ADMIN_ORIGIN}/privacy`. Terms: `{ADMIN_ORIGIN}/terms` (App Store Review Information and/or EULA / license URL).
4. App Privacy nutrition labels — same facts as Play Data safety. Account deletion: in-app Profile path.
5. Age rating: 18+ / the questionnaire equivalent for a wedding marketplace.
6. Pricing: **Free**. In-app purchases: **none**.
7. Review notes:
   - Demo: guest Discover works without login; bookings need Email OTP
   - Demo account email + “code is emailed; operator is available”
   - WhatsApp opens an external app
   - No IAP; off-platform payment
8. Export compliance: HTTPS only, no custom encryption. `ITSAppUsesNonExemptEncryption = false` is already in `ios/Runner/Info.plist`.
9. Sign in with Apple: **not required** for Email OTP-only.
10. Archive in Xcode with Mohammed’s **Team** (Automatic signing). No team id or `.p12` belongs in git.

Flutter 3.47 iOS stubs use **Swift Package Manager** (there is no `Podfile`). Open `ios/Runner.xcworkspace`, not a `.xcodeproj` alone.

```bash
flutter build ipa --dart-define-from-file=.env
# or: open ios/Runner.xcworkspace in Xcode → Product → Archive
```

## Signing (Mohammed only)

Android (Play):

1. Generate an upload keystore **on Mohammed’s machine** (not in this repo):

   ```bash
   keytool -genkey -v -keystore ~/dahr-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias dahr
   ```

2. Create `android/key.properties` locally (gitignored):

   ```
   storePassword=...
   keyPassword=...
   keyAlias=dahr
   storeFile=/absolute/path/to/dahr-upload.jks
   ```

3. Wire `signingConfigs.release` in `android/app/build.gradle.kts` to that file when you are ready to upload. Until then the template uses **debug** signing on the release build type so local `flutter run --release` still works. **Do not commit** `key.properties` or the `.jks`.

iOS:

1. Open `ios/Runner.xcworkspace` in Xcode.
2. Signing & Capabilities → Team = Mohammed’s Apple Developer team. Bundle Identifier `com.dahr.dahr`.
3. Archive and upload with Transporter or Organizer. No certificates in git.

## Privacy / permissions the stores will ask about

| Permission / API | Why |
|------------------|-----|
| Internet | Supabase Auth, listings, photos |
| Photo library / camera | Vendor listing photos (`image_picker`). Purpose strings are in `ios/Runner/Info.plist`. |
| Queries WhatsApp / https | `url_launcher` + `wa.me` |
| Local cleartext | Android `network_security_config.xml` allows HTTP **only** to `10.0.2.2`, `127.0.0.1`, `localhost` for emulator → local `supabase start`. Production Dahr LY is HTTPS. |

## PR / branch notes

- Packaging PR targets **`main`**.
- Privacy, terms, and Profile account deletion: **`main`** (merged #10). No need to base this work on #11 for legal URLs.
- Email OTP-only login + legal copy that drops phone OTP: **open PR #11**. Prefer merging #11 before the store binary if the listing claims Email OTP only.
