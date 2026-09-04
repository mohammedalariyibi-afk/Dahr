import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dahr/core/security/safe_user_error.dart';
import 'package:dahr/l10n/generated/app_localizations.dart';

void main() {
  group('every known key has copy', () {
    for (final locale in [const Locale('en'), const Locale('ar')]) {
      test('in ${locale.languageCode}', () async {
        final l10n = await AppLocalizations.delegate.load(locale);
        for (final key in SafeUserError.knownKeys) {
          final message = SafeUserError.fromKey(l10n, key);
          expect(message.trim(), isNotEmpty, reason: key);
          if (SafeUserError.opaqueKeys.contains(key)) continue;
          expect(
            message,
            isNot(l10n.errorGeneric),
            reason: '$key is listed as known but falls back to generic copy',
          );
        }
      });
    }

    test('the booking guard keys raised by the DB are covered', () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      for (final key in [
        'vendor_not_approved',
        'booking_must_be_pending',
        'invalid_booking_transition',
        'date_has_accepted_booking',
        'guest_count_invalid',
      ]) {
        expect(SafeUserError.knownKeys, contains(key), reason: key);
        expect(SafeUserError.fromKey(l10n, key), isNot(l10n.errorGeneric),
            reason: key);
      }
    });

    test('an unknown or internal message stays generic', () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      expect(SafeUserError.fromKey(l10n, 'something_new'), l10n.errorGeneric);
      expect(
        SafeUserError.of(
          l10n,
          StateError('PostgrestException(message: permission denied)'),
        ),
        l10n.errorGeneric,
      );
    });
  });

  group('SafeUserError.looksInternal', () {
    test('treats API exceptions and tokens as internal', () {
      expect(SafeUserError.looksInternal(null), isTrue);
      expect(SafeUserError.looksInternal(''), isTrue);
      expect(
        SafeUserError.looksInternal('PostgrestException(message: jwt expired)'),
        isTrue,
      );
      expect(
        SafeUserError.looksInternal('AuthException(message: Invalid login)'),
        isTrue,
      );
      expect(
        SafeUserError.looksInternal(
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.payload.sig',
        ),
        isTrue,
      );
      expect(SafeUserError.looksInternal('access_token=secret'), isTrue);
    });

    test('allows short user-facing copy', () {
      expect(SafeUserError.looksInternal('Something went wrong. Try again.'), isFalse);
      expect(SafeUserError.looksInternal('Could not upload photo'), isFalse);
    });
  });
}
