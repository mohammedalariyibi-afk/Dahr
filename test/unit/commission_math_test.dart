import 'package:flutter_test/flutter_test.dart';
import 'package:dahr/core/models/commission.dart';

void main() {
  group('CommissionMath', () {
    test('computes 10% matching Postgres ROUND to 2 decimals', () {
      expect(CommissionMath.amountDue(1000), 100.0);
      expect(CommissionMath.amountDue(2500), 250.0);
      expect(CommissionMath.amountDue(33.33), 3.33);
      expect(CommissionMath.amountDue(10.05), 1.01);
      expect(CommissionMath.amountDue(99.99), 10.00);
    });

    test('rejects non-positive quotes', () {
      expect(() => CommissionMath.amountDue(0), throwsArgumentError);
      expect(() => CommissionMath.amountDue(-5), throwsArgumentError);
    });

    test('parses vendor quote input', () {
      expect(CommissionMath.parseQuotedAmount('1500'), 1500);
      expect(CommissionMath.parseQuotedAmount('1500.50'), 1500.50);
      expect(CommissionMath.parseQuotedAmount('1500,50'), 1500.50);
      expect(CommissionMath.parseQuotedAmount('1,250.50'), 1250.50);
      expect(CommissionMath.parseQuotedAmount(''), isNull);
      expect(CommissionMath.parseQuotedAmount('nope'), isNull);
    });
  });
}
