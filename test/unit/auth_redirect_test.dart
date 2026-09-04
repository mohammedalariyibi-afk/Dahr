import 'package:flutter_test/flutter_test.dart';
import 'package:dahr/core/providers/auth_provider.dart';
import 'package:dahr/core/routing/auth_redirect.dart';

void main() {
  group('safeReturnTo', () {
    test('allows in-app paths and blocks open redirects', () {
      expect(safeReturnTo('/favorites'), '/favorites');
      expect(safeReturnTo('/booking/v1'), '/booking/v1');
      expect(safeReturnTo('%2Fbookings'), '/bookings');
      expect(safeReturnTo(null), isNull);
      expect(safeReturnTo(''), isNull);
      expect(safeReturnTo('https://evil.example/phish'), isNull);
      expect(safeReturnTo('//evil.example'), isNull);
      expect(safeReturnTo('auth/login'), isNull);
    });
  });

  group('guest vs signed-in guards', () {
    test('guest may browse discover, vendor detail, profile, legal, and auth', () {
      const guest = AuthFlowStatus.unauthenticated;
      for (final loc in [
        '/discover',
        '/vendor/abc',
        '/profile',
        '/legal/privacy',
        '/legal/terms',
        '/auth/language',
        '/auth/login',
        '/auth/otp',
      ]) {
        expect(
          resolveAuthRedirect(
            location: loc,
            status: guest,
            uri: Uri.parse(loc),
          ),
          isNull,
          reason: 'guest should stay on $loc',
        );
      }
    });

    test('guest hitting a protected route is sent to login with from=', () {
      const guest = AuthFlowStatus.unauthenticated;
      const protected = [
        '/favorites',
        '/bookings',
        '/booking/vendor-1',
        '/review/b1',
        '/inbox',
        '/vendor-tools/onboarding',
        '/vendor-tools/dashboard',
        '/vendor-tools/availability',
        '/vendor-tools/photos',
        '/profile/edit',
      ];
      for (final loc in protected) {
        final uri = Uri.parse(loc);
        final redirect = resolveAuthRedirect(
          location: loc,
          status: guest,
          uri: uri,
        );
        expect(redirect, isNotNull, reason: loc);
        expect(redirect!.startsWith('/auth/login?from='), isTrue, reason: loc);
        final from = Uri.parse(redirect).queryParameters['from'];
        expect(from, uri.toString(), reason: loc);
        expect(safeReturnTo(from), loc, reason: loc);
      }
    });

    test('signed-in user is not bounced off protected routes', () {
      const signedIn = AuthFlowStatus.authenticated;
      for (final loc in ['/favorites', '/bookings', '/booking/v1', '/inbox']) {
        expect(
          resolveAuthRedirect(
            location: loc,
            status: signedIn,
            uri: Uri.parse(loc),
            isVendor: loc == '/inbox',
          ),
          isNull,
        );
      }
    });

    test('couple cannot open vendor inbox or vendor tools', () {
      const signedIn = AuthFlowStatus.authenticated;
      for (final loc in [
        '/inbox',
        '/vendor-tools/dashboard',
        '/vendor-tools/availability',
        '/vendor-tools/edit',
        '/vendor-tools/photos',
      ]) {
        expect(
          resolveAuthRedirect(
            location: loc,
            status: signedIn,
            uri: Uri.parse(loc),
            isVendor: false,
          ),
          '/profile',
          reason: loc,
        );
      }
    });

    test('couple may still open vendor onboarding', () {
      expect(
        resolveAuthRedirect(
          location: '/vendor-tools/onboarding',
          status: AuthFlowStatus.authenticated,
          uri: Uri.parse('/vendor-tools/onboarding'),
          isVendor: false,
        ),
        isNull,
      );
    });

    test('vendor stays on inbox and vendor tools', () {
      for (final loc in [
        '/inbox',
        '/vendor-tools/dashboard',
        '/vendor-tools/availability',
      ]) {
        expect(
          resolveAuthRedirect(
            location: loc,
            status: AuthFlowStatus.authenticated,
            uri: Uri.parse(loc),
            isVendor: true,
          ),
          isNull,
          reason: loc,
        );
      }
    });
  });

  group('login redirect', () {
    test('authenticated user on login goes to discover without from', () {
      expect(
        resolveAuthRedirect(
          location: '/auth/login',
          status: AuthFlowStatus.authenticated,
          uri: Uri.parse('/auth/login'),
        ),
        '/discover',
      );
    });

    test('authenticated user on login returns to encoded from path', () {
      final from = Uri.encodeComponent('/booking/vendor-1');
      expect(
        resolveAuthRedirect(
          location: '/auth/login',
          status: AuthFlowStatus.authenticated,
          uri: Uri.parse('/auth/login?from=$from'),
        ),
        '/booking/vendor-1',
      );
    });

    test('authenticated user on splash or language goes to discover', () {
      expect(
        resolveAuthRedirect(
          location: '/splash',
          status: AuthFlowStatus.authenticated,
          uri: Uri.parse('/splash'),
        ),
        '/discover',
      );
      expect(
        resolveAuthRedirect(
          location: '/auth/language',
          status: AuthFlowStatus.authenticated,
          uri: Uri.parse('/auth/language'),
        ),
        '/discover',
      );
    });

    test('invalid from after login does not open-redirect', () {
      expect(
        resolveAuthRedirect(
          location: '/auth/login',
          status: AuthFlowStatus.authenticated,
          uri: Uri.parse('/auth/login?from=https://evil.example'),
        ),
        '/discover',
      );
    });

    test('OTP verify honors returnTo only when fully authenticated', () {
      expect(
        resolvePostOtpLocation(
          status: AuthFlowStatus.authenticated,
          returnTo: '/favorites',
        ),
        '/favorites',
      );
      expect(
        resolvePostOtpLocation(
          status: AuthFlowStatus.needsRole,
          returnTo: '/favorites',
        ),
        '/auth/role',
      );
      expect(
        resolvePostOtpLocation(
          status: AuthFlowStatus.needsProfile,
          returnTo: '/bookings',
        ),
        '/auth/profile-setup',
      );
      expect(
        resolvePostOtpLocation(
          status: AuthFlowStatus.authenticated,
          returnTo: 'https://evil.example',
        ),
        '/discover',
      );
    });
  });

  group('onboarding redirects', () {
    test('unknown session is held on splash', () {
      expect(
        resolveAuthRedirect(
          location: '/discover',
          status: AuthFlowStatus.unknown,
          uri: Uri.parse('/discover'),
        ),
        '/splash',
      );
      expect(
        resolveAuthRedirect(
          location: '/splash',
          status: AuthFlowStatus.unknown,
          uri: Uri.parse('/splash'),
        ),
        isNull,
      );
    });

    test('needsRole and needsProfile cannot skip setup', () {
      expect(
        resolveAuthRedirect(
          location: '/discover',
          status: AuthFlowStatus.needsRole,
          uri: Uri.parse('/discover'),
        ),
        '/auth/role',
      );
      expect(
        resolveAuthRedirect(
          location: '/discover',
          status: AuthFlowStatus.needsProfile,
          uri: Uri.parse('/discover'),
        ),
        '/auth/profile-setup',
      );
    });

    test('needsRole may still walk forward into profile setup', () {
      // Regression: role select pushes /auth/profile-setup, and a session
      // re-sync still reports needsRole while full_name is blank. Redirecting
      // back to /auth/role made onboarding unfinishable.
      expect(
        resolveAuthRedirect(
          location: '/auth/profile-setup',
          status: AuthFlowStatus.needsRole,
          uri: Uri.parse('/auth/profile-setup'),
        ),
        isNull,
      );
      expect(
        resolveAuthRedirect(
          location: '/auth/role',
          status: AuthFlowStatus.needsRole,
          uri: Uri.parse('/auth/role'),
        ),
        isNull,
      );
    });

    test('needsProfile still cannot walk back into role select', () {
      expect(
        resolveAuthRedirect(
          location: '/auth/role',
          status: AuthFlowStatus.needsProfile,
          uri: Uri.parse('/auth/role'),
        ),
        '/auth/profile-setup',
      );
    });

    test('legal screens stay open during onboarding', () {
      expect(
        resolveAuthRedirect(
          location: '/legal/privacy',
          status: AuthFlowStatus.needsRole,
          uri: Uri.parse('/legal/privacy'),
        ),
        isNull,
      );
      expect(
        resolveAuthRedirect(
          location: '/legal/terms',
          status: AuthFlowStatus.needsProfile,
          uri: Uri.parse('/legal/terms'),
        ),
        isNull,
      );
    });

    test('guest cannot open role or profile setup', () {
      expect(
        resolveAuthRedirect(
          location: '/auth/role',
          status: AuthFlowStatus.unauthenticated,
          uri: Uri.parse('/auth/role'),
        ),
        '/auth/login',
      );
      expect(
        resolveAuthRedirect(
          location: '/auth/profile-setup',
          status: AuthFlowStatus.unauthenticated,
          uri: Uri.parse('/auth/profile-setup'),
        ),
        '/auth/login',
      );
    });
  });
}
