import 'package:flutter_test/flutter_test.dart';
import 'package:dahr/features/auth/providers/auth_form_validators.dart';

void main() {
  group('AuthFormValidators phone', () {
    test('accepts valid Libya mobile', () {
      expect(AuthFormValidators.validatePhone('912345678'), isNull);
      expect(AuthFormValidators.validatePhone('+218912345678'), isNull);
      expect(AuthFormValidators.validatePhone('0912345678'), isNull);
    });

    test('rejects invalid phone', () {
      expect(AuthFormValidators.validatePhone(''), 'required');
      expect(AuthFormValidators.validatePhone('123'), 'invalid_phone');
      expect(AuthFormValidators.validatePhone('812345678'), 'invalid_phone');
    });

    test('normalizes and converts to E164', () {
      expect(AuthFormValidators.normalizePhoneInput('+218912345678'), '912345678');
      expect(AuthFormValidators.toE164('912345678'), '+218912345678');
    });
  });

  group('AuthFormValidators email', () {
    test('accepts valid email', () {
      expect(AuthFormValidators.validateEmail('a@b.com'), isNull);
    });

    test('rejects invalid email', () {
      expect(AuthFormValidators.validateEmail(''), 'required');
      expect(AuthFormValidators.validateEmail('not-an-email'), 'invalid_email');
    });
  });

  group('AuthFormValidators otp', () {
    test('requires 6 digits', () {
      expect(AuthFormValidators.validateOtp('123456'), isNull);
      expect(AuthFormValidators.validateOtp('12345'), 'invalid_otp');
      expect(AuthFormValidators.validateOtp(''), 'required');
    });
  });
}
