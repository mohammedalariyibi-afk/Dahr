import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String sql;

  setUpAll(() {
    sql = File(
      'supabase/migrations/20260904010000_customer_pays_dahr_fee.sql',
    ).readAsStringSync();
  });

  test('git-only migration reuses commission columns and admin RPC', () {
    expect(sql, contains('do NOT `db push`'));
    expect(sql, contains('commission_status'));
    expect(sql, contains('set_booking_commission_status'));
    expect(sql, contains('Paid by the couple to Dahr by bank transfer'));
    expect(sql, contains('CREATE TABLE public.platform_settings'));
    expect(sql, contains('CREATE TABLE public.commission_transfer_notes'));
    expect(sql, isNot(contains('service_role')));
  });

  test('couples can insert a transfer note but cannot set paid', () {
    expect(sql, contains('commission_transfer_notes_insert_own_unpaid'));
    expect(sql, contains("b.commission_status = 'unpaid'"));
    expect(sql, contains('Couples still cannot UPDATE booking_requests'));
    expect(
      sql,
      isNot(contains('GRANT UPDATE ON TABLE public.commission_transfer_notes')),
    );
    expect(sql, isNot(contains('commission_transfer_notes_update')));
    expect(sql, isNot(contains('GRANT ALL ON TABLE public.booking_requests')));
  });

  test('bank details ship empty with no invented account number', () {
    expect(sql, contains("DEFAULT ''"));
    expect(sql, contains('Do not invent a Libyan account number'));
    expect(sql, isNot(contains('LY00')));
    expect(sql, isNot(contains('IBAN')));
  });
}
