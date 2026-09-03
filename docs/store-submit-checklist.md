# Saturday store submit — Dahr

Ship target: **Saturday 5 Sep 2026** (Africa/Tripoli). Screenshots and listing copy are on `main`; this is the operator runbook.

## Before you open the consoles

1. Pull latest `main`.
2. Confirm `.env` / `admin/.env.local` point at **Dahr LY** (`cccusktgxrizfwpixddu`) with **anon key only** (never commit; never put `service_role` in the app).
3. Preferred: one **quoted-booking smoke** (accept with amount → commission fields). Do not block the whole submit on this if time is tight — note result in the room.
4. Privacy / terms public URLs must resolve:
   - `{ADMIN_ORIGIN}/privacy`
   - `{ADMIN_ORIGIN}/terms`
   - Routes exist on `main`; hosting still needs a deploy (Vercel or equivalent). In-app `/legal/privacy` and `/legal/terms` cover Profile links meanwhile.
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
3. Upload phone shots from `docs/store-shots/`. Upload Play **1024×500** feature graphic: `docs/store-shots/play-feature-graphic-1024x500.png`.
4. Privacy URL `{ADMIN_ORIGIN}/privacy`. Data safety: account deletion in-app (Profile).
5. Contact: WhatsApp + `mohammedalariyibi@gmail.com`.
6. No IAP / no ads SDKs.

## App Store Connect

1. Bundle id matching iOS target; Arabic primary + English localization.
2. Paste subtitle / keywords / description from `docs/store-listing.md`.
3. Upload iPhone shots from `docs/store-shots/`. If universal iPad: capture iPad 13″ **or** set `TARGETED_DEVICE_FAMILY = 1` (iPhone only) before archive.
4. Privacy `{ADMIN_ORIGIN}/privacy`, Terms `{ADMIN_ORIGIN}/terms`.
5. Review notes: Email OTP only; WhatsApp for vendor contact; no IAP; LYD; account deletion in Profile.
6. Sign & archive release build when privacy URLs are live.

## Do not

- Commit `.env` / service role keys
- `db push` migrations already live on Dahr LY (e.g. booking/review scope from #16)
- Use Sidra LY or the paused older `dahr` Supabase project

## Room signal

When listing is submitted (or blocked), ping **App launch** with: consoles used, privacy URL used, and smoke pass/fail.
