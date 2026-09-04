import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _migration =
    '20260904000000_admin_audit_log_and_atomic_moderation.sql';

/// Quoted single-line entries of an `IN (...)` list in the migration.
Set<String> _sqlAllowlist(String sql, String afterMarker) {
  final start = sql.indexOf(afterMarker);
  expect(start, greaterThanOrEqualTo(0), reason: 'missing $afterMarker');
  final open = sql.indexOf('(', start);
  final close = sql.indexOf(')', open);
  expect(close, greaterThan(open));
  return RegExp("'([a-z_]+)'")
      .allMatches(sql.substring(open, close))
      .map((m) => m.group(1)!)
      .toSet();
}

Set<String> _tsAllowlist(String ts, String constName) {
  final start = ts.indexOf('export const $constName = [');
  expect(start, greaterThanOrEqualTo(0), reason: 'missing $constName');
  final close = ts.indexOf(']', start);
  expect(close, greaterThan(start));
  return RegExp('"([a-z_]+)"')
      .allMatches(ts.substring(start, close))
      .map((m) => m.group(1)!)
      .toSet();
}

void main() {
  late String sql;
  late String auditLogTs;
  late String adminActions;
  late List<String> migrationNames;

  setUpAll(() {
    migrationNames = Directory('supabase/migrations')
        .listSync()
        .whereType<File>()
        .map((f) => f.uri.pathSegments.last)
        .toList()
      ..sort();
    sql = File('supabase/migrations/$_migration').readAsStringSync();
    auditLogTs = File('admin/src/lib/audit-log.ts').readAsStringSync();
    adminActions = File('admin/src/app/(admin)/actions.ts').readAsStringSync();
  });

  test('migration applies after the booking integrity guards', () {
    expect(migrationNames, contains(_migration));
    expect(migrationNames.where((n) => n.contains('admin_audit_log')),
        hasLength(1));
    expect(
      migrationNames.indexOf(_migration),
      greaterThan(
        migrationNames.indexOf('20260903230000_booking_integrity_guards.sql'),
      ),
    );
  });

  group('admin_audit_log is append-only', () {
    test('UPDATE and DELETE are rejected by trigger', () {
      expect(sql, contains("RAISE EXCEPTION 'admin_audit_log is append-only'"));
      expect(
        sql,
        contains('BEFORE UPDATE OR DELETE ON public.admin_audit_log'),
      );
      expect(
        sql,
        contains(
          'DROP TRIGGER IF EXISTS admin_audit_log_append_only ON public.admin_audit_log',
        ),
      );
    });

    test('clients may read as admin but never write the table directly', () {
      expect(sql, contains('ALTER TABLE public.admin_audit_log ENABLE ROW LEVEL SECURITY'));
      expect(sql, contains('FOR SELECT TO authenticated'));
      expect(
        sql,
        contains(
          'REVOKE ALL ON public.admin_audit_log FROM PUBLIC, anon, authenticated',
        ),
      );
      expect(sql, contains('GRANT SELECT ON public.admin_audit_log TO authenticated'));
      expect(sql, isNot(contains('GRANT INSERT ON public.admin_audit_log')));
      expect(sql, isNot(contains('FOR INSERT TO authenticated')));
    });

    test('rows survive the account deletion cascade', () {
      final table = sql.substring(
        sql.indexOf('CREATE TABLE IF NOT EXISTS public.admin_audit_log'),
        sql.indexOf('COMMENT ON TABLE public.admin_audit_log'),
      );
      expect(table, contains('actor_id UUID NOT NULL'));
      expect(table, isNot(contains('REFERENCES')));
    });
  });

  group('log_admin_action is the only writer', () {
    test('admin-only, allowlisted, and not an anon RPC', () {
      expect(sql, contains("RAISE EXCEPTION 'only admin may write the audit log'"));
      expect(sql, contains("RAISE EXCEPTION 'unknown_audit_action'"));
      expect(sql, contains("RAISE EXCEPTION 'unknown_audit_target'"));
      expect(sql, contains('SECURITY DEFINER'));
      expect(sql, contains('SET search_path = public'));
      expect(
        sql,
        contains(
          'GRANT EXECUTE ON FUNCTION public.log_admin_action(TEXT, TEXT, UUID, JSONB)\n  TO authenticated',
        ),
      );
      expect(
        sql,
        contains(
          'REVOKE ALL ON FUNCTION public.log_admin_action(TEXT, TEXT, UUID, JSONB)\n  FROM PUBLIC, anon',
        ),
      );
    });

    test('the dashboard allowlist matches the SQL allowlist exactly', () {
      expect(
        _tsAllowlist(auditLogTs, 'AUDIT_ACTIONS'),
        _sqlAllowlist(sql, 'p_action NOT IN'),
      );
      expect(
        _tsAllowlist(auditLogTs, 'AUDIT_TARGETS'),
        _sqlAllowlist(sql, 'p_target_type NOT IN'),
      );
    });
  });

  group('hide_review_and_close_report is one transaction', () {
    test('hides the review and closes the report, logging both', () {
      expect(sql, contains('CREATE OR REPLACE FUNCTION public.hide_review_and_close_report'));
      expect(sql, contains('SECURITY INVOKER'));
      expect(sql, contains("RAISE EXCEPTION 'only admin may hide a review'"));
      expect(sql, contains("RAISE EXCEPTION 'review_not_found'"));
      expect(sql, contains("RAISE EXCEPTION 'report_not_found'"));
      expect(sql, contains("PERFORM public.log_admin_action(\n    'review_hidden'"));
      expect(sql, contains("'report_actioned'"));
      expect(
        sql,
        contains(
          "SET status = 'actioned'::public.report_status",
        ),
      );
    });

    test('not reachable as an anon RPC', () {
      expect(
        sql,
        contains(
          'REVOKE ALL ON FUNCTION public.hide_review_and_close_report(UUID, UUID)\n  FROM PUBLIC, anon',
        ),
      );
      expect(
        sql,
        isNot(
          contains(
            'GRANT EXECUTE ON FUNCTION public.hide_review_and_close_report(UUID, UUID)\n  TO anon',
          ),
        ),
      );
    });
  });

  group('admin dashboard writes the trail', () {
    test('hide review prefers the RPC and keeps the pre-migration fallback',
        () {
      expect(adminActions, contains('HIDE_REVIEW_RPC'));
      expect(adminActions, contains('RPC_MISSING_CODE'));
      expect(adminActions, contains('adminHideReviewPatch()'));
    });

    test('every admin decision logs an allowlisted action', () {
      for (final call in [
        'vendorApprovalAction(approved)',
        'vendorVerificationAction(verified)',
        'reportStatusAction(status)',
        'commissionAction(status)',
      ]) {
        expect(adminActions, contains(call), reason: call);
      }
      expect(adminActions, contains('LOG_ADMIN_ACTION_RPC'));
      expect(adminActions, contains('auditRpcArgs(entry)'));
    });

    test('a failed audit write cannot roll back the decision', () {
      expect(auditLogTs, contains('unknown_audit_action'));
      expect(auditLogTs, contains('unknown_audit_target'));
      final logger = adminActions.substring(
        adminActions.indexOf('async function logAdminAction'),
        adminActions.indexOf('export async function signOut'),
      );
      expect(logger, contains('try {'));
      expect(logger, contains('} catch {'));
      expect(logger, isNot(contains('fail(')));
    });
  });
}
