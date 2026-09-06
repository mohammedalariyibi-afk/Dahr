import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dahr/core/theme/app_theme.dart';
import 'package:dahr/features/auth/providers/otp_resend_gate.dart';
import 'package:dahr/features/auth/screens/otp_verify_screen.dart';
import 'package:dahr/l10n/generated/app_localizations.dart';

Widget _host({
  required OtpResendGate gate,
  Locale locale = const Locale('en'),
}) {
  return ProviderScope(
    child: MaterialApp(
      theme: AppTheme.dark,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: OtpVerifyScreen(
        channel: 'email',
        destination: 'couple@dahr.ly',
        resendGate: gate,
      ),
    ),
  );
}

void main() {
  testWidgets('resend is disabled during cooldown and shows wait copy',
      (tester) async {
    final now = DateTime(2026, 9, 6, 12);
    final gate = OtpResendGate(
      cooldown: const Duration(seconds: 30),
      clock: () => now,
    )..armFromPriorSend();

    await tester.pumpWidget(_host(gate: gate));
    await tester.pump();

    expect(find.text('Resend in 30s'), findsOneWidget);
    final button = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'Resend in 30s'),
    );
    expect(button.onPressed, isNull);
    expect(find.text('A new code was sent.'), findsNothing);
  });

  testWidgets('AR resend wait copy uses the cooldown seconds', (tester) async {
    final now = DateTime(2026, 9, 6, 12);
    final gate = OtpResendGate(
      cooldown: const Duration(seconds: 30),
      clock: () => now,
    )..armFromPriorSend();

    await tester.pumpWidget(
      _host(gate: gate, locale: const Locale('ar')),
    );
    await tester.pump();

    expect(find.text('أعد الإرسال خلال 30 ث'), findsOneWidget);
  });

  testWidgets('resend is enabled when the cooldown has elapsed', (tester) async {
    var now = DateTime(2026, 9, 6, 12);
    final gate = OtpResendGate(
      cooldown: const Duration(seconds: 30),
      clock: () => now,
    )..armFromPriorSend();
    now = now.add(const Duration(seconds: 30));

    await tester.pumpWidget(_host(gate: gate));
    await tester.pump();

    expect(find.text('Resend code'), findsOneWidget);
    final button = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'Resend code'),
    );
    expect(button.onPressed, isNotNull);
  });
}
