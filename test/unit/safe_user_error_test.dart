import 'package:flutter_test/flutter_test.dart';
import 'package:dahr/core/security/safe_user_error.dart';

void main() {
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
