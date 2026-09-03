import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String sql;
  late List<String> migrationNames;

  setUpAll(() {
    final dir = Directory('supabase/migrations');
    migrationNames = dir
        .listSync()
        .whereType<File>()
        .map((f) => f.uri.pathSegments.last)
        .toList()
      ..sort();
    sql = File(
      'supabase/migrations/20260903190000_freeze_admin_role_and_private_profile_rows.sql',
    ).readAsStringSync();
  });

  test('combined file sits after overnight hardening and is unique', () {
    expect(
      migrationNames,
      contains('20260903184000_overnight_security_hardening.sql'),
    );
    expect(
      migrationNames,
      contains('20260903190000_freeze_admin_role_and_private_profile_rows.sql'),
    );
    expect(
      migrationNames.indexOf(
        '20260903190000_freeze_admin_role_and_private_profile_rows.sql',
      ),
      greaterThan(
        migrationNames.indexOf('20260903184000_overnight_security_hardening.sql'),
      ),
    );
    expect(
      migrationNames.where(
        (n) => n.contains('freeze_admin_role_and_private_profile_rows'),
      ),
      hasLength(1),
    );
  });

  test('protect_profile_admin_role is trigger-only, not an anon RPC', () {
    expect(sql, contains('CREATE OR REPLACE FUNCTION public.protect_profile_admin_role()'));
    expect(sql, contains('RETURNS trigger'));
    expect(sql, contains("NEW.role := 'consumer'::public.user_role"));
    expect(sql, contains('CREATE TRIGGER profiles_protect_admin_role'));
    expect(sql, contains('BEFORE INSERT OR UPDATE OF role ON public.profiles'));
    expect(
      sql,
      contains(
        'REVOKE ALL ON FUNCTION public.protect_profile_admin_role() FROM PUBLIC, anon, authenticated',
      ),
    );
    expect(
      sql,
      contains(
        'GRANT EXECUTE ON FUNCTION public.protect_profile_admin_role() TO service_role',
      ),
    );
    expect(
      sql,
      isNot(contains('GRANT EXECUTE ON FUNCTION public.protect_profile_admin_role() TO anon')),
    );
    expect(
      sql,
      isNot(
        contains(
          'GRANT EXECUTE ON FUNCTION public.protect_profile_admin_role() TO authenticated',
        ),
      ),
    );
  });

  test('drops public-names table policy and uses private definer + invoker view', () {
    expect(sql, contains('DROP POLICY IF EXISTS profiles_select_public_names ON public.profiles'));
    expect(sql, contains('CREATE SCHEMA IF NOT EXISTS private'));
    expect(sql, contains('CREATE OR REPLACE FUNCTION private.public_profile_rows()'));
    expect(sql, contains('SET search_path = \'\''));
    expect(
      sql,
      contains(
        'GRANT EXECUTE ON FUNCTION private.public_profile_rows() TO anon, authenticated, service_role',
      ),
    );
    expect(sql, contains('CREATE OR REPLACE VIEW public.profile_public'));
    expect(
      sql,
      contains('WITH (security_invoker = true, security_barrier = true)'),
    );
    expect(sql, contains('FROM private.public_profile_rows() AS r'));
    expect(sql, contains('ALTER VIEW public.profile_public OWNER TO postgres'));
    expect(sql, contains('REVOKE ALL ON public.profile_public FROM PUBLIC'));
    expect(
      sql,
      contains(
        'GRANT SELECT ON public.profile_public TO anon, authenticated, service_role',
      ),
    );
  });

  test('does not change Storage buckets or re-grant RLS helpers to anon', () {
    expect(sql, isNot(contains('storage.objects')));
    expect(sql, isNot(contains('storage.buckets')));
    expect(sql, isNot(contains("bucket_id = 'vendor-photos'")));
    expect(sql, isNot(contains('GRANT EXECUTE ON FUNCTION public.is_admin() TO anon')));
    expect(
      sql,
      isNot(contains('GRANT EXECUTE ON FUNCTION public.owns_vendor(uuid) TO anon')),
    );
  });
}
