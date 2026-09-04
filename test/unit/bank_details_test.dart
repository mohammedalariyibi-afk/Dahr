import 'package:flutter_test/flutter_test.dart';
import 'package:dahr/core/models/bank_details.dart';

void main() {
  test('empty or missing settings are unset — fail-safe UI', () {
    expect(PlatformBankDetails.unset.isConfigured, isFalse);
    expect(PlatformBankDetails.fromJson(null).isConfigured, isFalse);
    expect(
      PlatformBankDetails.fromJson({
        'bank_name': '  ',
        'account_holder': 'Ops',
        'account_number': '123',
      }).isConfigured,
      isFalse,
    );
  });

  test('configured only when bank, holder, and number are present', () {
    final details = PlatformBankDetails.fromJson({
      'bank_name': 'Example Bank',
      'account_holder': 'Dahr Operator',
      'account_number': 'PLACEHOLDER-ONLY',
      'bank_note': ' optional ',
    });
    expect(details.isConfigured, isTrue);
    expect(details.optionalNote, 'optional');
  });

  test('shipped JSON never invents a Libyan account number', () {
    expect(PlatformBankDetails.unset.accountNumber, isEmpty);
    expect(PlatformBankDetails.selectColumns, contains('account_number'));
    expect(PlatformBankDetails.singletonId, 'default');
  });
}
