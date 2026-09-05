-- Grant-layer backstop. Supabase's platform default privileges give
-- anon INSERT/UPDATE/DELETE/TRUNCATE on every new public table. init_schema
-- only ever added grants, so the eight original tables still show
-- has_table_privilege('anon', ..., 'TRUNCATE') = true.
--
-- RLS does not cover TRUNCATE. PostgREST has no TRUNCATE verb today, so
-- this is not an open door through the API — it is the missing backstop
-- under every write policy. The three newer tables already revoked
-- correctly; this makes the original eight match.
--
-- Also drops write grants on profile_public. That view is not
-- auto-updatable, so the grants were never exploitable, just inconsistent
-- with booking_party_contact (SELECT only).
--
-- ALTER DEFAULT PRIVILEGES is scoped to the role that owns the default.
-- Live defaults are owned by both postgres and supabase_admin, so both
-- are revoked. service_role is left alone.

REVOKE INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER
  ON ALL TABLES IN SCHEMA public FROM anon;

REVOKE TRUNCATE, REFERENCES, TRIGGER
  ON ALL TABLES IN SCHEMA public FROM authenticated;

-- Current role can rewrite its own defaults. supabase_admin owns a
-- second set (dashboard-created tables); that revoke needs superuser
-- and is skipped with a notice if this runs as postgres.
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public
  REVOKE INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER ON TABLES FROM anon;

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public
  REVOKE TRUNCATE, REFERENCES, TRIGGER ON TABLES FROM authenticated;

DO $$
BEGIN
  EXECUTE $sql$
    ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public
      REVOKE INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER ON TABLES FROM anon
  $sql$;
  EXECUTE $sql$
    ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public
      REVOKE TRUNCATE, REFERENCES, TRIGGER ON TABLES FROM authenticated
  $sql$;
EXCEPTION
  WHEN insufficient_privilege THEN
    RAISE NOTICE 'could not rewrite supabase_admin default privileges; do that from the dashboard if new tables still grant anon writes';
END;
$$;

REVOKE ALL ON TABLE public.profile_public FROM anon, authenticated;
GRANT SELECT ON TABLE public.profile_public TO anon, authenticated;
