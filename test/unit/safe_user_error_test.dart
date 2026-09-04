import 'package:flutter_test/flutter_test.dart';
import 'package:dahr/core/security/safe_user_error.dart';
import 'package:dahr/l10n/generated/app_localizations.dart';
import 'package:dahr/l10n/generated/app_localizations_ar.dart';
import 'package:dahr/l10n/generated/app_localizations_en.dart';

void main() {
  final en = AppLocalizationsEn();
  final ar = AppLocalizationsAr();
  final locales = <AppLocalizations>[en, ar];

  group('validation keys reach the user', () {
    // Thrown by BookingRequestPayload.validate and ReviewPayload.validate.
    // These had no case, so a fixable input problem surfaced as the generic
    // "something went wrong" copy.
    const fixable = {
      'guest_count_invalid',
      'message_too_long',
      'rating_invalid',
      'comment_too_long',
    };

    // Raised by the database guards in
    // 20260903230000_booking_integrity_guards.sql.
    const bookingGuards = {
      'vendor_not_approved',
      'booking_must_be_pending',
      'invalid_booking_transition',
      'date_has_accepted_booking',
    };

    for (final locale in locales) {
      test('${locale.localeName}: every known key has its own copy', () {
        for (final key in SafeUserError.knownKeys) {
          final message = SafeUserError.fromKey(locale, key);
          expect(message.trim(), isNotEmpty, reason: key);
          if (SafeUserError.opaqueKeys.contains(key)) continue;
          expect(
            message,
            isNot(locale.errorGeneric),
            reason: '$key is listed as known but falls back to generic copy',
          );
        }
      });

      test('${locale.localeName}: fixable input errors are not generic', () {
        for (final key in fixable) {
          expect(
            SafeUserError.fromKey(locale, key),
            isNot(locale.errorGeneric),
            reason: '$key must tell the user what to fix',
          );
        }
      });

      test('${locale.localeName}: booking guard errors are not generic', () {
        for (final key in bookingGuards) {
          expect(
            SafeUserError.fromKey(locale, key),
            isNot(locale.errorGeneric),
            reason: key,
          );
        }
      });

      test('${locale.localeName}: booking_required asks for the field', () {
        expect(
          SafeUserError.fromKey(locale, 'booking_required'),
          locale.requiredField,
        );
      });

      test('${locale.localeName}: unknown keys stay generic', () {
        expect(
          SafeUserError.fromKey(locale, 'pgrst_internal_detail'),
          locale.errorGeneric,
        );
        expect(SafeUserError.fromKey(locale, null), locale.errorGeneric);
      });
    }

    test('every key a payload or guard throws is a known key', () {
      for (final key in {...fixable, ...bookingGuards}) {
        expect(SafeUserError.knownKeys, contains(key), reason: key);
      }
      expect(SafeUserError.knownKeys, contains('booking_required'));
    });

    test('StateError validation keys map through of()', () {
      expect(
        SafeUserError.of(en, StateError('guest_count_invalid')),
        en.guestCountInvalid,
      );
      expect(
        SafeUserError.of(en, StateError('rating_invalid')),
        en.ratingRequired,
      );
      expect(
        SafeUserError.of(en, StateError('vendor_not_approved')),
        en.vendorNotApprovedError,
      );
    });

    test('an internal exception never reaches the user', () {
      expect(
        SafeUserError.of(
          en,
          StateError('PostgrestException(message: permission denied)'),
        ),
        en.errorGeneric,
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
      expect(
        SafeUserError.looksInternal('Something went wrong. Try again.'),
        isFalse,
      );
      expect(SafeUserError.looksInternal('Could not upload photo'), isFalse);
    });
  });
}
