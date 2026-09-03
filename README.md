# Dahr

Dahr is a wedding-vendor marketplace for Libya. Couples browse venues, photographers, and planners; vendors manage listings and quote requests. The Flutter app is the customer and vendor product. `admin/` is the Next.js operations console.

## What is in this repo

| Path | What it is |
| --- | --- |
| `lib/` | Flutter app (couples, vendors, listings, bookings) |
| `admin/` | Next.js admin console (vendor queue, listings, bookings) |
| `supabase/migrations/` | Schema and RLS for the live Dahr LY project |
| `docs/` | Architecture, admin runbook, and the Saturday ship checklist |

## How sign-in works

Both the Flutter app and the admin console use **Email OTP only**. Supabase Auth sends a one-time code to the user's email. There is no phone OTP, no Twilio, and no WhatsApp sign-in.

WhatsApp is **vendor contact after booking**, not a login method. The Flutter app opens `https://wa.me/<libya-digits>` only for validated Libya numbers.

## Saturday 5 Sep 2026 ship

The ship target is a Libya-only marketplace with:

- Email OTP login (no phone OTP, no payments)
- WhatsApp contact for booked vendors
- Arabic / English
- LYD prices
- Admin console for vendor, listing, and booking operations

See `docs/saturday-ship.md` for the checklist.

## Run locally

### Flutter app

```bash
flutter pub get
flutter test
flutter run
```

The app reads `DAHR_SUPABASE_URL` and `DAHR_SUPABASE_ANON_KEY` from `--dart-define` or `dart_defines.json`. Cloud URLs must use HTTPS. The Android debug cleartext policy allows only `localhost`, `127.0.0.1`, and `10.0.2.2`.

### Admin console

```bash
cd admin
npm install
npm run dev
```

Admin env vars live in `admin/.env.local`. Required: `NEXT_PUBLIC_SUPABASE_URL`, `NEXT_PUBLIC_SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY`.

## Tests

```bash
flutter test
cd admin && npm test
```
