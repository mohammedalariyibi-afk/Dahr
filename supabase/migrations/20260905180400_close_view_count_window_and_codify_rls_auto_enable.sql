-- Two leftovers from dashboard-era hardening.
--
-- increment_vendor_views sets dahr.allow_view_increment = on and never
-- turns it off. PostgREST is one statement per transaction today, so a
-- vendor cannot chain an RPC and an UPDATE over the REST API. The flag
-- still leaks for the rest of any future multi-statement transaction
-- (a wrapper function, a cron job, a batched admin op). Close the window
-- before returning. Guest view counting stays — dropping the anon grant
-- would stop Discover from counting unsigned traffic. Ranking must not
-- treat view_count as authoritative; that is a product rule, not SQL.
--
-- rls_auto_enable() plus event trigger ensure_rls already exist on
-- Dahr LY and auto-enable RLS on new public tables. They are in no
-- migration file, so db reset does not reproduce production. This
-- writes the live body down. The event trigger is created only when
-- missing; production already has it so the branch is a no-op there.
-- CREATE EVENT TRIGGER needs superuser. If a local role cannot create
-- it, the NOTICE is the signal — enable it from the dashboard.

CREATE OR REPLACE FUNCTION public.increment_vendor_views(p_vendor_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  PERFORM set_config('dahr.allow_view_increment', 'on', true);
  UPDATE public.vendor_profiles
  SET view_count = view_count + 1
  WHERE id = p_vendor_id AND is_approved = true;
  PERFORM set_config('dahr.allow_view_increment', 'off', true);
END;
$$;

REVOKE ALL ON FUNCTION public.increment_vendor_views(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.increment_vendor_views(uuid) TO anon, authenticated, service_role;

CREATE OR REPLACE FUNCTION public.rls_auto_enable()
RETURNS event_trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $$
DECLARE
  cmd record;
BEGIN
  FOR cmd IN
    SELECT *
    FROM pg_event_trigger_ddl_commands()
    WHERE command_tag IN ('CREATE TABLE', 'CREATE TABLE AS', 'SELECT INTO')
      AND object_type IN ('table', 'partitioned table')
  LOOP
    IF cmd.schema_name IS NOT NULL
       AND cmd.schema_name IN ('public')
       AND cmd.schema_name NOT IN ('pg_catalog', 'information_schema')
       AND cmd.schema_name NOT LIKE 'pg_toast%'
       AND cmd.schema_name NOT LIKE 'pg_temp%'
    THEN
      BEGIN
        EXECUTE format('alter table if exists %s enable row level security', cmd.object_identity);
        RAISE LOG 'rls_auto_enable: enabled RLS on %', cmd.object_identity;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE LOG 'rls_auto_enable: failed to enable RLS on %', cmd.object_identity;
      END;
    ELSE
      RAISE LOG 'rls_auto_enable: skip % (either system schema or not in enforced list: %.)',
        cmd.object_identity, cmd.schema_name;
    END IF;
  END LOOP;
END;
$$;

REVOKE ALL ON FUNCTION public.rls_auto_enable() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.rls_auto_enable() TO service_role;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_event_trigger WHERE evtname = 'ensure_rls') THEN
    EXECUTE 'CREATE EVENT TRIGGER ensure_rls ON ddl_command_end EXECUTE FUNCTION public.rls_auto_enable()';
  END IF;
EXCEPTION
  WHEN insufficient_privilege THEN
    RAISE NOTICE 'ensure_rls event trigger requires superuser; create it from the dashboard if missing';
END;
$$;
