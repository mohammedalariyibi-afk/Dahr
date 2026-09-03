# Saturday store submit — Dahr

Ship target: **Saturday 5 Sep 2026** (Africa/Tripoli). Screenshots and listing copy are on `main`; this is the operator runbook.

## Before you open the consoles

1. Pull latest `main`.
2. Confirm `.env` / `admin/.env.local` point at **Dahr LY** (`https://cccusktgxrizfwpixddu.supabase.co`) with **anon key only** (never commit; never put `service_role` in the app). Run `dart run tool/check_store_env.dart` before the Play AAB.
3. Preferred: one **quoted-booking smoke** (accept with amount → commission fields). Do not block the whole submit on this if time is tight — note result in the room.
4. Privacy / terms public URLs must resolve (GitHub Pages, not Vercel / not dahr.ly):
   - `https://mohammedalariyibi-afk.github.io/Dahr/privacy`
   - `https://mohammedalariyibi-afk.github.io/Dahr/terms`
   - After merge: if those 404, set **Settings → Pages → Source: GitHub Actions**. In-app `/legal/privacy` and `/legal/terms` do **not** satisfy the store fields.
5. Have WhatsApp business number + email `mohammedalariyibi@gmail.com` for store support / contact fields.
6. Optional for 10% collection path: bank / WhatsApp details for offline commission (not required for store listing).

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
7. Build the AAB on Mohammed’s machine: local `android/key.properties` + `dart run tool/check_store_env.dart` + `flutter build appbundle --dart-define-from-file=.env`.

## App Store Connect

1. Bundle id matching iOS target; Arabic primary + English localization.
2. Paste subtitle / keywords / description from `docs/store-listing.md`.
3. Upload iPhone shots from `docs/store-shots/`. The Xcode target is **iPhone only** (`TARGETED_DEVICE_FAMILY = 1`) — no 13″ iPad screenshots.
4. Privacy `https://mohammedalariyibi-afk.github.io/Dahr/privacy`, Terms `https://mohammedalariyibi-afk.github.io/Dahr/terms`.
5. Review notes: Email OTP only; WhatsApp for vendor contact; no IAP; LYD; account deletion in Profile.
6. Sign & archive release build when privacy URLs are live.

## Do not

- Commit `.env` / service role keys
- `db push` migrations already live on Dahr LY (e.g. booking/review scope from #16)
- Use Sidra LY or the paused older `dahr` Supabase project

## Room signal

When listing is submitted (or blocked), ping **App launch** with: consoles used, privacy URL used, and smoke pass/fail.
