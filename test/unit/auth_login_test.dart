import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:dahr/features/auth/providers/auth_form_validators.dart';

void main() {
  group('AuthLoginSpec', () {
    test('email OTP is the only consumer sign-in channel', () {
      expect(AuthLoginSpec.primaryChannel, 'email');
      expect(AuthLoginSpec.supportsPhoneOtp, isFalse);
      expect(AuthLoginSpec.otpChannel(), 'email');
      expect(AuthLoginSpec.otpChannel(requested: 'phone'), 'email');
      expect(AuthLoginSpec.otpChannel(requested: 'email'), 'email');
      expect(AuthLoginSpec.usesPhoneOtp('phone'), isFalse);
      expect(AuthLoginSpec.usesPhoneOtp('email'), isFalse);
    });

    test('otp extra always sends the email channel', () {
      expect(
        AuthLoginSpec.otpExtra(email: 'couple@dahr.ly'),
        {
          'channel': 'email',
          'destination': 'couple@dahr.ly',
        },
      );
      expect(
        AuthLoginSpec.otpExtra(
          email: 'vendor@dahr.ly',
          returnTo: '/booking/v1',
        )['channel'],
        'email',
      );
      expect(
        AuthLoginSpec.otpExtra(
          email: 'vendor@dahr.ly',
          returnTo: '/booking/v1',
        )['returnTo'],
        '/booking/v1',
      );
    });
  });

  test('AR+EN login copy is email OTP, not phone-first', () {
    final en = File('lib/l10n/app_en.arb').readAsStringSync();
    final ar = File('lib/l10n/app_ar.arb').readAsStringSync();
    expect(en, contains('Enter your email to receive a one-time sign-in code'));
    expect(ar, contains('أدخل بريدك الإلكتروني لاستلام رمز الدخول لمرة واحدة'));
    expect(en, isNot(contains('Enter your Libyan phone number')));
    expect(ar, isNot(contains('أدخل رقم هاتفك الليبي لاستلام رمز التحقق')));
    expect(en.toLowerCase(), isNot(contains('phone-first')));
    expect(en, isNot(contains('needs an SMS provider')));
  });

  test('README documents Email OTP only', () {
    final readme = File('README.md').readAsStringSync();
    expect(readme, contains('Email OTP only'));
    expect(readme, isNot(contains('the Flutter login screen is phone-first')));
    expect(readme, isNot(contains('Continue with email')));
    expect(readme, isNot(contains('Phone OTP (+218)')));
    expect(readme.toLowerCase(), isNot(contains('twilio')));
  });
}
