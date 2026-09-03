import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dahr/features/auth/screens/login_screen.dart';
import 'package:dahr/l10n/generated/app_localizations.dart';

void main() {
  Widget host({Locale locale = const Locale('en')}) {
    return ProviderScope(
      child: MaterialApp(
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: const LoginScreen(),
      ),
    );
  }

  testWidgets('EN login is email OTP only — no phone field or SMS toggle',
      (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    expect(
      find.text('Enter your email to receive a one-time sign-in code'),
      findsOneWidget,
    );
    expect(find.text('Email'), findsOneWidget);
    expect(find.byType(TextFormField), findsOneWidget);
    expect(find.text('Send code'), findsOneWidget);

    expect(find.text('Phone number'), findsNothing);
    expect(find.text('Continue with email'), findsNothing);
    expect(find.text('Continue with phone'), findsNothing);
    expect(find.textContaining('+218'), findsNothing);
    expect(find.byIcon(Icons.phone_android), findsNothing);
    expect(find.byIcon(Icons.email_outlined), findsOneWidget);
  });

  testWidgets('AR login is email OTP only — no phone-first copy', (tester) async {
    await tester.pumpWidget(host(locale: const Locale('ar')));
    await tester.pumpAndSettle();

    expect(
      find.text('أدخل بريدك الإلكتروني لاستلام رمز الدخول لمرة واحدة'),
      findsOneWidget,
    );
    expect(find.text('البريد الإلكتروني'), findsOneWidget);
    expect(find.text('رقم الهاتف'), findsNothing);
    expect(find.text('المتابعة بالبريد الإلكتروني'), findsNothing);
    expect(find.text('المتابعة برقم الهاتف'), findsNothing);
  });
}
