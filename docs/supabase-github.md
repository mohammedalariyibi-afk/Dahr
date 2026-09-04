# Connecting GitHub to Supabase (Dahr LY)

How schema changes get from `supabase/migrations` in this repo onto the live
**Dahr LY** project (`cccusktgxrizfwpixddu`, eu-west-1).

Two halves. The repo half is done and lives in `.github/workflows`. The
dashboard half needs a human with Supabase dashboard access, because
authorizing GitHub is an OAuth flow.

| Piece | Where | Status |
| --- | --- | --- |
| Validate migrations on every PR | `.github/workflows/supabase.yml` | done, no secrets needed |
| Push migrations to Dahr LY on demand | `.github/workflows/supabase-deploy.yml` | needs three GitHub secrets |
| Deploy automatically on merge to `main` | Supabase dashboard GitHub integration | not enabled yet |

> **Do not enable automatic deploys before doing the one-time history
> reconciliation below.** The migration history on Dahr LY does not match the
> filenames in `supabase/migrations`, so the first automatic push would try to
> re-apply migrations that are already live and fail.

## 1. What CI does today

`Supabase CI` runs on every PR and every push to `main` that touches
`supabase/**`. It starts a throwaway Postgres, applies all of
`supabase/migrations` in filename order, runs `seed.sql`, then lints the
result. It never touches Dahr LY and needs no credentials.

This catches the class of problem that has bitten this project before: a
migration that assumes an object an earlier migration never created, a
duplicate migration version, or SQL that only works because it was typed into
the dashboard by hand.

Make it a required check so a broken migration cannot merge: **Settings >
Branches > `main` > Require status checks to pass**, then select
*Apply migrations to a throwaway database*.

## 2. One-time: reconcile the Dahr LY migration history

Every migration in this repo except `20260903230000_booking_integrity_guards`
and `20260904120000_booking_party_contact` is already live, but the live ones
were applied through the dashboard, so Supabase recorded different version
numbers. Nothing in `supabase_migrations.schema_migrations` matches a filename
in `supabase/migrations`:

| In `supabase/migrations` | Recorded on Dahr LY |
| --- | --- |
| `20260328000001_init_schema` | *(not recorded at all)* |
| — | `20260903000003_grant_rls_helpers_to_anon` |
| `20260903000001_booking_commission` | `20260903111958_booking_commission` |
| `20260903120000_revoke_anon_definer_rpcs` | `20260903115709_revoke_anon_definer_rpcs` |
| `20260903140000_delete_own_account` | `20260903124356_delete_own_account` |
| `20260903184000_overnight_security_hardening` | `20260903164203_overnight_security_hardening` |
| `20260903190000_freeze_admin_role_and_private_profile_rows` | `20260903170228_freeze_admin_role_and_close_profile_pii` + `20260903170257_move_public_profile_filter_to_private_function` |
| `20260903210000_scope_booking_updates_and_insert_only_reviews` | `20260903211019_scope_booking_updates_and_insert_only_reviews` |
| `20260903230000_booking_integrity_guards` | *(genuinely not applied)* |
| `20260904000000_admin_audit_log_and_atomic_moderation` | `20260904104425_admin_audit_log_and_atomic_moderation` |
| `20260904005000_customer_pays_dahr_fee` | `20260904105445_customer_pays_dahr_fee` |
| `20260904010000_guest_read_policies_without_helper_execute` | `20260904104408_guest_read_policies_without_helper_execute` |
| `20260904120000_booking_party_contact` | *(genuinely not applied)* |

`supabase migration repair` only rewrites that history table; it runs no SQL
and changes no schema. Point the repo's filenames at what is actually live:

```bash
supabase login
supabase link --project-ref cccusktgxrizfwpixddu

# Drop the dashboard-era rows, including grant_rls_helpers_to_anon, which was
# superseded by revoke_anon_definer_rpcs and has no file in this repo.
supabase migration repair --linked --status reverted \
  20260903000003 20260903111958 20260903115709 20260903124356 \
  20260903164203 20260903170228 20260903170257 20260903211019 \
  20260904104408 20260904104425 20260904105445

# Record the repo's versions as applied, since their SQL is already live.
supabase migration repair --linked --status applied \
  20260328000001 20260903000001 20260903120000 20260903140000 \
  20260903184000 20260903190000 20260903210000 20260904000000 \
  20260904005000 20260904010000

supabase migration list --linked
```

After that last command, every row should show the same version in the Local
and Remote columns, with `20260903230000_booking_integrity_guards` and
`20260904120000_booking_party_contact` local-only. Do **not** mark
`20260904120000` applied — that SQL is not on Dahr LY yet.

### Then apply the migrations that are missing

`booking_party_contact` is newer than the last applied version, so a plain
`db push` will apply it. `booking_integrity_guards` is older, so a plain
`db push` skips it. It needs `--include-all` (which also picks up the newer
file if it is still pending):

```bash
supabase db push --linked --dry-run --include-all   # expect integrity guards + booking_party_contact
supabase db push --linked --include-all
```

`booking_integrity_guards` adds the availability held-date guard
(`protect_availability_held_dates` and its trigger) and the
`booking_requests_one_held_date` / `idx_booking_requests_vendor_event_active`
indexes. `booking_party_contact` adds the authenticated-only couple name/phone
view the vendor inbox uses. None of them exist on Dahr LY today.

## 3. Automatic deploys: pick one

Do not enable both. They would race to apply the same migrations.

### Option A: Supabase dashboard GitHub integration (recommended)

No database password in GitHub, and it works on the free plan.

1. Supabase dashboard > **Project Settings > Integrations**.
2. Under **GitHub Integration**, **Authorize GitHub**, then **Authorize
   Supabase**.
3. Connect the project to this repository.
4. **Working directory**: `.` — `supabase/` sits at the repository root.
5. Enable **Deploy to production**. Leave **Automatic branching** off unless
   you are on the Pro plan and want a preview database per PR.
6. **Enable integration**.

Merging to `main` then applies new migrations, plus any Edge Functions and
storage buckets declared in `config.toml`. Everything else in `config.toml`
(API, Auth, `seed.sql`) is ignored on production.

Docs: <https://supabase.com/docs/guides/deployment/branching/github-integration>

### Option B: the deploy workflow in this repo

Useful if you want the push to show up in the Actions log, or want a required
reviewer on it.

Add these to a GitHub environment named `dahr-ly`
(**Settings > Environments > New environment**), not to repository-wide
secrets, so you can attach required reviewers:

| Secret | Value |
| --- | --- |
| `SUPABASE_ACCESS_TOKEN` | personal access token from <https://supabase.com/dashboard/account/tokens> |
| `SUPABASE_DB_PASSWORD` | Dahr LY database password (Project Settings > Database) |
| `SUPABASE_PROJECT_ID` | `cccusktgxrizfwpixddu` |

Then run **Actions > Deploy Supabase migrations > Run workflow**. It defaults
to a dry run, which prints the pending migrations and applies nothing. Untick
**dry_run** to actually push.

To make it deploy on merge instead of by hand, add a `push` trigger on `main`
for `supabase/**` — but only after step 2, and only if you did not enable
Option A.

## 4. Known gaps

- **Postgres major version.** `supabase/config.toml` pins
  `[db] major_version = 15`; Dahr LY runs Postgres 17. CI therefore validates
  migrations on 15. Bumping it to 17 means every developer runs
  `supabase stop --no-backup && supabase db reset` once, because the local data
  volume is not portable across major versions.
- **No RLS regression tests.** CI proves the migrations apply; it does not
  prove a guest can still read approved vendors. The bug fixed by
  `guest_read_policies_without_helper_execute` would not have been caught. A
  pgTAP test under `supabase/tests/` (`supabase test db`) would close that gap.
- **`db advisors` is advisory.** It runs with `--fail-on none` because the
  schema has pre-existing findings. Tighten it once those are triaged.
