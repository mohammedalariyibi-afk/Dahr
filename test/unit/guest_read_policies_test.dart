import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _migration =
    '20260904010000_guest_read_policies_without_helper_execute.sql';

String _withoutComments(String sql) => sql
    .split('\n')
    .where((line) => !line.trimLeft().startsWith('--'))
    .join('\n');

/// Each `CREATE POLICY ...;` statement in [sql], keyed by policy name.
Map<String, String> _policies(String sql) {
  final out = <String, String>{};
  for (final match
      in RegExp(r'CREATE POLICY\s+(\w+)([\s\S]*?);').allMatches(sql)) {
    out[match.group(1)!] = match.group(2)!;
  }
  return out;
}

bool _callsHelper(String body) =>
    body.contains('public.is_admin()') || body.contains('public.owns_vendor(');

void main() {
  late String sql;
  late Map<String, String> policies;
  late List<String> migrationNames;

  setUpAll(() {
    migrationNames = Directory('supabase/migrations')
        .listSync()
        .whereType<File>()
        .map((f) => f.uri.pathSegments.last)
        .toList()
      ..sort();
    sql = _withoutComments(
      File('supabase/migrations/$_migration').readAsStringSync(),
    );
    policies = _policies(sql);
  });

  test('migration applies last and only once', () {
    expect(migrationNames.last, _migration);
    expect(
      migrationNames.where((n) => n.contains('guest_read_policies')),
      hasLength(1),
    );
  });

  test('every policy is replaced, not stacked on the old one', () {
    for (final name in policies.keys) {
      expect(
        sql,
        contains('DROP POLICY IF EXISTS $name ON'),
        reason: 'CREATE POLICY $name without a matching DROP',
      );
    }
    expect(policies, isNotEmpty);
    // The single reviews read policy is retired in favour of two.
    expect(sql, contains('DROP POLICY IF EXISTS reviews_public_read ON'));
    expect(policies, isNot(contains('reviews_public_read')));
  });

  group('a guest is never planned against a helper call', () {
    test('every helper-calling policy is limited to authenticated', () {
      final helperPolicies =
          policies.entries.where((e) => _callsHelper(e.value));
      expect(helperPolicies, isNotEmpty);
      for (final policy in helperPolicies) {
        expect(
          policy.value,
          contains('TO authenticated'),
          reason:
              '${policy.key} calls is_admin/owns_vendor, which anon may not '
              'execute, so it must not apply to anon',
        );
      }
    });

    test('the policies that keep guest browse open call no helper', () {
      for (final name in [
        'reviews_select_visible',
      ]) {
        expect(policies, contains(name));
        expect(_callsHelper(policies[name]!), isFalse, reason: name);
      }
      // The approved-listing reads were already split out and stay untouched.
      for (final name in [
        'vendors_select_approved',
        'photos_select_approved_vendor',
        'availability_select_approved_vendor',
      ]) {
        expect(policies, isNot(contains(name)), reason: name);
      }
    });

    test('the tables a guest reads are all covered', () {
      for (final table in [
        'public.vendor_profiles',
        'public.vendor_photos',
        'public.availability',
        'public.reviews',
      ]) {
        expect(sql, contains('ON $table'), reason: table);
      }
    });

    test('availability write policy is scoped too, since FOR ALL covers SELECT',
        () {
      expect(policies, contains('availability_owner_write'));
      expect(policies['availability_owner_write'], contains('FOR ALL TO authenticated'));
      expect(policies['availability_owner_write'], contains('WITH CHECK'));
    });

    test('the fix does not re-grant the helpers to anon', () {
      expect(sql, isNot(contains('GRANT EXECUTE ON FUNCTION public.is_admin')));
      expect(
        sql,
        isNot(contains('GRANT EXECUTE ON FUNCTION public.owns_vendor')),
      );
      expect(sql, isNot(contains('TO anon')));
    });

    test('hidden reviews still need a signed-in reader', () {
      expect(policies['reviews_select_visible'], contains('NOT is_hidden'));
      expect(policies, contains('reviews_select_own_or_admin'));
      expect(
        policies['reviews_select_own_or_admin'],
        contains('consumer_id = auth.uid()'),
      );
    });
  });
}
