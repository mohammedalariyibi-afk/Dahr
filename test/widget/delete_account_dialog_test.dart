import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dahr/core/theme/app_theme.dart';
import 'package:dahr/features/auth/screens/delete_account_dialog.dart';
import 'package:dahr/l10n/generated/app_localizations.dart';

void main() {
  Widget host({required bool isSignedIn, required ValueChanged<bool> onResult}) {
    return MaterialApp(
      theme: AppTheme.dark,
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return TextButton(
              onPressed: () async {
                final result = await showDeleteAccountDialog(
                  context: context,
                  isSignedIn: isSignedIn,
                );
                onResult(result.shouldCallRpc);
              },
              child: const Text('open-delete'),
            );
          },
        ),
      ),
    );
  }

  testWidgets('cancel on the confirm dialog does not request deletion',
      (tester) async {
    var shouldCall = false;
    await tester.pumpWidget(
      host(isSignedIn: true, onResult: (v) => shouldCall = v),
    );
    await tester.tap(find.text('open-delete'));
    await tester.pumpAndSettle();

    expect(find.text('Delete your account?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(shouldCall, isFalse);
  });

  testWidgets('confirm on the dialog requests the RPC for a signed-in user',
      (tester) async {
    var shouldCall = false;
    await tester.pumpWidget(
      host(isSignedIn: true, onResult: (v) => shouldCall = v),
    );
    await tester.tap(find.text('open-delete'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Delete account'));
    await tester.pumpAndSettle();
    expect(shouldCall, isTrue);
  });

  testWidgets('guest cannot confirm deletion', (tester) async {
    var shouldCall = false;
    await tester.pumpWidget(
      host(isSignedIn: false, onResult: (v) => shouldCall = v),
    );
    await tester.tap(find.text('open-delete'));
    await tester.pumpAndSettle();

    final confirm = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Delete account'),
    );
    expect(confirm.onPressed, isNull);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(shouldCall, isFalse);
  });
}
