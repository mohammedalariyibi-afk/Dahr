import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:dahr/features/auth/providers/otp_resend_gate.dart';

void main() {
  group('OtpResendGate', () {
    test('blocks resend during cooldown and unlocks after it', () {
      var now = DateTime(2026, 9, 6, 12);
      final gate = OtpResendGate(
        cooldown: const Duration(seconds: 30),
        clock: () => now,
      );

      expect(gate.canResend, isTrue);
      gate.armFromPriorSend();
      expect(gate.canResend, isFalse);
      expect(gate.isCoolingDown, isTrue);
      expect(gate.remainingSeconds, 30);
      expect(gate.begin(), isFalse);

      now = now.add(const Duration(seconds: 29));
      expect(gate.canResend, isFalse);
      expect(gate.remainingSeconds, 1);

      now = now.add(const Duration(seconds: 1));
      expect(gate.canResend, isTrue);
      expect(gate.remainingSeconds, 0);
      expect(gate.begin(), isTrue);
      expect(gate.inFlight, isTrue);
      expect(gate.canResend, isFalse);
    });

    test('succeed starts a new cooldown; fail does not', () {
      var now = DateTime(2026, 9, 6, 12);
      final gate = OtpResendGate(
        cooldown: const Duration(seconds: 30),
        clock: () => now,
      );

      expect(gate.begin(), isTrue);
      gate.succeed();
      expect(gate.inFlight, isFalse);
      expect(gate.canResend, isFalse);
      expect(gate.remainingSeconds, 30);

      now = now.add(const Duration(seconds: 30));
      expect(gate.begin(), isTrue);
      gate.fail();
      expect(gate.inFlight, isFalse);
      expect(gate.canResend, isTrue);
    });

    test('begin is ignored while a send is already in flight', () {
      final gate = OtpResendGate(clock: () => DateTime(2026, 9, 6));
      expect(gate.begin(), isTrue);
      expect(gate.begin(), isFalse);
    });
  });

  test('OTP screen wires loading, success snackbar, and the cooldown gate', () {
    final src =
        File('lib/features/auth/screens/otp_verify_screen.dart').readAsStringSync();
    expect(src.contains('OtpResendGate'), isTrue);
    expect(src.contains('armFromPriorSend'), isTrue);
    expect(src.contains('otpResendSent'), isTrue);
    expect(src.contains('CircularProgressIndicator'), isTrue);
    expect(src.contains('_gate.begin()'), isTrue);
  });
}
