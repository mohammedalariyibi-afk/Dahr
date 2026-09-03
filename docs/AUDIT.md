# Dahr application audit

**Date:** 3 September 2026  
**Scope:** Flutter app (`lib/`), Next.js admin (`admin/`), Supabase schema (`supabase/`), store packaging, tests/CI  
**Auditor:** Cursor Cloud Agent  
**Live backend:** Dahr LY (`cccusktgxrizfwpixddu`, `eu-west-1`)

This is a full-app audit, not only a diff review. Findings assume an attacker who has the published **anon / publishable** key (it ships in the Flutter and admin clients) and can call PostgREST / Auth directly, bypassing UI guards.

---

## Executive summary

Dahr is in good shape for a marketplace MVP: RLS on every public table, layered admin checks, fail-closed Flutter write guards, no `service_role` in clients, Email OTP only, privacy/terms and in-app account deletion on `main`. Previous hardening PRs (#11, #16, #18, overnight / admin-role freeze) closed the obvious privilege-escalation paths.

The remaining **ship-blocking** gap was **booking integrity at the database**. Flutter rejected fake completed bookings and skipped-quote completes, but anyone with the anon key could still:

1. Insert a `completed` booking as themselves and leave a review (skip vendor accept + 10% commission).
2. As a vendor, `UPDATE` `pending → completed` and skip the quote/commission path.
3. Accept two couples for the same date (date guard only checked the vendor calendar, and only on INSERT).
4. Reassign `consumer_id` / `vendor_id` / `event_date` after insert.

Those four are **fixed in this change** (`20260903230000_booking_integrity_guards.sql` plus matching Flutter guards). **Apply that migration to Dahr LY** (`supabase db push`) before Saturday store submit. Do **not** re-push the already-live overnight / freeze-admin files.

Nothing in this audit found a way for a couple to become `admin`, leak the service role, or bypass admin RLS from the dashboard.

---

## Architecture (what we audited)

| Layer | Stack | Authz model |
|-------|--------|-------------|
| Couple / vendor app | Flutter 3.47, Riverpod, go_router, `supabase_flutter` | Anon key + RLS + client write guards |
| Admin | Next.js 15 App Router, `@supabase/ssr` | Anon key, `getUser()`, `requireAdmin()`, RLS, RPCs |
| Backend | Supabase Auth (Email OTP), Postgres, Storage `vendor-photos` | RLS, triggers, `SECURITY INVOKER` accept/commission RPCs |
| Money | Offline 10% vendor commission in LYD | Quote on accept; admin marks paid/waived |

Out of scope for v1 (intentional): in-app payments, IAP, chat, push, maps, SMS login.

---

## What is already solid

1. **RLS on all eight public tables**; anon has no write policies.
2. **No `service_role` in Flutter or admin.** Startup rejects `sb_secret_*` and `service_role` JWTs (`dahr_env.dart`).
3. **Admin role freeze** — trigger downgrades unauthorized `admin` writes; UI never offers the role.
4. **Vendor `is_approved` / `is_verified`** cannot be self-granted (trigger).
5. **Consumers cannot UPDATE bookings** (policy + `BookingStatusWrite.consumerMayUpdate = false`).
6. **Reviews are insert-only for authors**; hide is admin-only (policy + trigger).
7. **Commission math** is constrained (`ROUND(quote * 0.10, 2)`); vendors cannot mark paid/waived.
8. **Accept RPC** is `SECURITY INVOKER`, pending-only, vendor-owned.
9. **`profile_public`** is `security_invoker` + barrier; public names are not full profile rows.
10. **Anon cannot EXECUTE** `is_admin`, `owns_vendor`, or trigger helpers.
11. **Admin dashboard** uses `getUser()` (not `getSession()`), `shouldCreateUser: false`, `safe-next` open-redirect hardening, whitelisted error codes, security headers.
12. **Account deletion** RPC takes no user-id argument; storage prefix cleanup + `auth.users` delete.
13. **WhatsApp** URLs are validated (Libya digits, `wa.me` host only).
14. **Guest browse** of approved listings is intentional and still works.
15. **CI** runs `flutter analyze` + `flutter test` on PRs/`main` with no secrets.

---

## Findings

Severity is for a published marketplace whose API key is in the client.

### Critical — remediating in this change

| ID | Finding | Why it matters | Fix |
|----|---------|----------------|-----|
| C1 | Consumer INSERT only blocked `status = accepted`. A direct insert with `status = completed` passed the commission trigger, then passed `enforce_review_on_completed_booking`. | Fake reviews + skipped commission. Flutter `BookingStatusWrite` does not protect PostgREST. | Trigger now raises `booking_must_be_pending` for non-pending consumer inserts. |
| C2 | Vendor UPDATE allowed `pending → completed` (quote path only ran for `pending → accepted`). | Vendor skips quote and 10% unpaid commission; couple can still review. | Status machine: `pending→accepted` (quote), `pending→declined`, `accepted→completed` only. |
| C3 | `consumer_id`, `vendor_id`, `event_date` were mutable after insert. | Vendor could reassign a booking or move the date; commission/review attribution breaks. | Non-admin UPDATE locks those three columns. |

### High — remediating in this change

| ID | Finding | Why it matters | Fix |
|----|---------|----------------|-----|
| H1 | Date guard ran **INSERT-only** and only looked at `availability`, not held bookings. Two pending requests could both be accepted. | Double-booked wedding date. | Unique index on `(vendor_id, event_date)` where status is accepted/completed; trigger also checks held rows on INSERT/UPDATE; accept RPC upserts `availability` in the same transaction. |
| H2 | Vendor could mark an accepted date `available` again. | Re-opens the date while a booking is held. | DB trigger `protect_availability_held_dates` + Flutter check before upsert. |
| H3 | Booking INSERT did not require `vendor_profiles.is_approved`. | Spam against pending listings. | Trigger raises `vendor_not_approved`. |
| H4 | Review INSERT did not force `is_hidden = false`. | Author could hide their own review from the public page while the vendor still saw it. | `enforce_review_on_completed_booking` forces `is_hidden = false` for non-admins. |
| H5 | Vendors could `UPDATE` their own `view_count`. | Popularity inflation. | `view_count` frozen unless `increment_vendor_views` sets `dahr.allow_view_increment`. |

### Medium — remediating in this change (client)

| ID | Finding | Fix |
|----|---------|-----|
| M1 | `/inbox` and `/vendor-tools/*` (except onboarding) were auth-gated but not role-gated. | `resolveAuthRedirect` sends non-vendors to `/profile`. |
| M2 | Discover search only stripped `% _ ,`. | `VendorFilters.sanitizeSearch` allowlists letters/digits/spaces/hyphen. |
| M3 | `bookingByIdProvider` did not filter `consumer_id`. | Query now requires the signed-in consumer. |
| M4 | Calendar `onDateChanged` swallowed toggle errors. | Await + `SafeUserError` snackbar. |
| M5 | Guest count had no upper bound. | Reject `guestCount > 10000`. |

### Medium — closed 4 September (see “Follow-up round”)

| ID | Finding | Fix |
|----|---------|-----|
| M6 | Admin Email OTP / callback has no app-level rate limit. | Send/verify moved to `/api/auth/otp*` routes with a per-address and per-e-mail fixed window applied before Supabase Auth. |
| M7 | Successful OTP then “not an admin” confirms the email exists. | Send always answers “sent”; a wrong code and a valid non-admin login share one answer. |
| M8 | No Content-Security-Policy on the admin Next.js app. | Nonce-based CSP from middleware (`strict-dynamic`, no script `unsafe-inline`, `frame-ancestors 'none'`). |
| M9 | `hideReview` then close-report is two updates (partial state if the second fails). | `hide_review_and_close_report` does both in one transaction. |
| M10 | `increment_vendor_views` is an anon SECURITY DEFINER RPC with no rate limit. | Still unlimited server-side, but the client now counts one view per vendor per app run. Ranking should still not trust this number. |

### Low / info — closed 4 September

| ID | Finding | Fix |
|----|---------|-----|
| L1 | Admin dashboard can render raw PostgREST `error.message` on stats failure. | Whitelisted load-failed copy. |
| L2 | No append-only `admin_audit_log`. | Added: trigger-enforced append-only, written only through the allowlisted `log_admin_action` RPC. |
| L3 | Admin CI is not in `.github/workflows` (Flutter only). | `Admin CI` runs typecheck, lint, and build. |
| L4 | `seed.sql` creates `admin@dahr.ly` / `password123`. | Local/Inbucket only. Comment added; never run seed on Dahr LY. |
| L5 | Onboarding `needsRole` fires when `full_name` is empty, not when role is unset (role defaults to `consumer`). | **Understated: this was a hard block, not a UX loop.** Fixed 4 September — see below. |
| L6 | Users can set `role = vendor` themselves. | Intentional “become a vendor” path; vendor **writes** still need a `vendor_profiles` row and approval for public listing. |
| L7 | Legal copy names “Dahr LY” and `eu-west-1`. | Appropriate for a privacy notice. |
| I1 | `config.toml` `enable_confirmations = false` is local-only. | Keep Email confirmations **on** in the Dahr LY dashboard. |
| I2 | Account deletion CASCADE wipes bookings/reviews. | Correct for store 5.1.1(v); archive commissions before delete if disputes matter later. |

---

## Store-submit readiness (Saturday 5 September 2026)

| Item | Status |
|------|--------|
| Bundle / application id `com.dahr.dahr` | On `main` |
| Email OTP only (no SMS / IAP / ads SDKs) | On `main` |
| Privacy / terms in-app + admin routes | On `main` — **hosted `{ADMIN_ORIGIN}` still needs a deploy** |
| Account deletion in Profile | On `main` |
| Listing copy + phone screenshots | `docs/store-listing.md`, `docs/store-shots/` |
| iPad 13″ shots **or** iPhone-only target | Operator choice (`STORE.md`) |
| Play feature graphic 1024×500 | Called out as optional/Designer |
| Flutter CI | Analyze + test, no secrets |
| **This integrity migration on Dahr LY** | **Required before submit** |
| Signing keystore / `.p12` | Local to Mohammed — correctly not in git |

Operator runbook: [`docs/store-submit-checklist.md`](store-submit-checklist.md).

---

## Apply on Dahr LY

```bash
supabase link --project-ref cccusktgxrizfwpixddu
supabase db push   # applies the three 2026090[34] files that are not on live yet
```

The three not yet on live: `20260903230000_booking_integrity_guards`,
`20260904000000_admin_audit_log_and_atomic_moderation`, and
`20260904010000_guest_read_policies_without_helper_execute`. The last one is
what makes signed-out Discover work at all (F1), so it is the one to push even
if time runs out.

If `CREATE UNIQUE INDEX booking_requests_one_held_date` fails, two accepted/completed rows already share a vendor date — inspect and decline/move one, then retry.

Do **not** re-apply `20260903184000_overnight_security_hardening` or `20260903190000_freeze_admin_role_and_private_profile_rows`.

---

## Follow-up round — 4 September 2026

Everything listed above as “still open” is now closed. Working through them
surfaced three functional bugs that the first pass missed, because that pass
reasoned about the SQL and the Dart instead of running them.

### Ship blockers found in this round

| ID | Finding | Why it was missed | Fix |
|----|---------|-------------------|-----|
| F1 | **Guest browse fails on every read.** As `anon`, `vendor_profiles`, `vendor_photos`, `availability`, and `reviews` all return `permission denied for function is_admin` / `owns_vendor`, so Discover, vendor detail, photos, the booking calendar, and review lists are empty errors for a signed-out user. | `revoke_anon_definer_rpcs` did revoke EXECUTE and did split the public-read policies, so reading the SQL suggests a guest is covered by a helper-free policy. But permissive policies are OR-ed into one qual and EXECUTE is checked while the query is **prepared** — before any row or any `OR` branch. Even `EXPLAIN` of a Discover query fails for `anon`. | `20260904010000_guest_read_policies_without_helper_execute.sql`: every helper-calling policy is limited to `TO authenticated`. |
| F2 | **New accounts could never finish onboarding.** After picking a role the router sent the user from `/auth/profile-setup` back to `/auth/role`, forever. | `AuthFlowStatus.needsRole` was derived from an empty `full_name`; `profiles.role` defaults to `consumer`, so `setRole` changed nothing the status could observe. Logged as cosmetic (L5). | `resolveAuthFlowStatus` takes the role pick as an explicit input. |
| F3 | **Review author names never render**, and for a guest no name renders at all. | The reviews query embeds `profiles(full_name)`, which worked under `profiles_select_public_names` — the policy the already-live freeze-admin migration **dropped**. | Names come from the `profile_public` view that migration introduced. |

### Also fixed

- `increment_vendor_views` was an un-awaited Postgrest builder. Those are lazy: with no terminal `then()` the request never left the app, so the view counter had never incremented. It now fires, and counts once per vendor per app run (which is also the M10 mitigation).
- A failed profile read no longer pushes a finished user back through onboarding.

### How this round was verified

The migrations were applied in filename order to a real PostgreSQL 16 with a
Supabase-shaped shim (`auth.uid()` reading `request.jwt.claims`, `anon` /
`authenticated` / `service_role` roles), then `seed.sql` on top — the
equivalent of `supabase db reset`. Guards were then exercised as those roles:

- 34 behavioural checks on the audit log, moderation, and the booking status machine, including that a bad report id leaves the review **not** hidden (the M9 atomicity claim) and that the append-only trigger refuses even the table owner
- 28 read checks proving guest browse works and still exposes only approved listings and visible reviews, while vendor / couple / admin reads are unchanged
- The admin CSP and throttle against a production `next build`: every script tag carries the nonce from the header, a fourth OTP send for one address returns `429`, and a wrong code and an unknown address are indistinguishable

## Suggested next work (after submit)

1. Share the OTP throttle across instances (Redis or a Postgres table) if the admin runs on more than one serverless instance; today the window is per instance.
2. `storage.objects` still has a `vendor_photos_storage_admin_all` policy that calls `is_admin()`. Public photo downloads do not go through it, and the app only lists objects while signed in, so it is not F1 — but a future anonymous `storage.list` would hit the same wall.
3. Audit-log retention / a dashboard view for it (rows are written but nothing renders them yet).
4. Archive commissions before an account deletion cascade (I2).

---

## Verification in this repo

- New SQL assertions: `test/unit/booking_integrity_guards_test.dart`
- Redirect / search / guest-count / write-guard tests updated
- `flutter analyze lib test` and `flutter test` should stay green
