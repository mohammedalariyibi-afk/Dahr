import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String rateLimit;
  late String sendRoute;
  late String verifyRoute;
  late String loginForm;
  late String publicError;
  late String csp;
  late String middleware;
  late String supabaseMiddleware;
  late String rootLayout;

  setUpAll(() {
    rateLimit = File('admin/src/lib/rate-limit.ts').readAsStringSync();
    sendRoute =
        File('admin/src/app/api/auth/otp/route.ts').readAsStringSync();
    verifyRoute =
        File('admin/src/app/api/auth/otp/verify/route.ts').readAsStringSync();
    loginForm = File('admin/src/app/login/login-form.tsx').readAsStringSync();
    publicError = File('admin/src/lib/public-error.ts').readAsStringSync();
    csp = File('admin/src/lib/csp.ts').readAsStringSync();
    middleware = File('admin/src/middleware.ts').readAsStringSync();
    supabaseMiddleware =
        File('admin/src/lib/supabase/middleware.ts').readAsStringSync();
    rootLayout = File('admin/src/app/layout.tsx').readAsStringSync();
  });

  group('admin OTP is throttled per e-mail and per address', () {
    test('both send and verify have an e-mail and an IP rule', () {
      for (final rule in [
        'OTP_SEND_PER_EMAIL',
        'OTP_SEND_PER_IP',
        'OTP_VERIFY_PER_EMAIL',
        'OTP_VERIFY_PER_IP',
      ]) {
        expect(rateLimit, contains('export const $rule'), reason: rule);
      }
      expect(sendRoute, contains('OTP_SEND_PER_EMAIL'));
      expect(sendRoute, contains('OTP_SEND_PER_IP'));
      expect(verifyRoute, contains('OTP_VERIFY_PER_EMAIL'));
      expect(verifyRoute, contains('OTP_VERIFY_PER_IP'));
    });

    test('keys are normalized so casing cannot buy extra attempts', () {
      expect(rateLimit, contains('email.trim().toLowerCase()'));
      expect(rateLimit, contains('x-forwarded-for'));
    });

    test('the limiter runs before the request reaches Supabase Auth', () {
      for (final route in [sendRoute, verifyRoute]) {
        final decisionAt = route.indexOf('otpRateLimiter.checkAll');
        final supabaseAt = route.indexOf('await createClient()');
        expect(decisionAt, greaterThanOrEqualTo(0));
        expect(supabaseAt, greaterThan(decisionAt));
        expect(route, contains('status: 429'));
        expect(route, contains('"Retry-After"'));
      }
    });

    test('the browser no longer talks to Supabase Auth directly', () {
      expect(loginForm, contains('"/api/auth/otp"'));
      expect(loginForm, contains('"/api/auth/otp/verify"'));
      expect(loginForm, isNot(contains('auth.signInWithOtp')));
      expect(loginForm, isNot(contains('auth.verifyOtp')));
    });

    test('the sign-in endpoints stay reachable without a session', () {
      expect(supabaseMiddleware, contains('path.startsWith("/api/auth/")'));
      expect(supabaseMiddleware, contains('isAuthApi'));
    });
  });

  group('sign-in answers do not confirm an address', () {
    test('a send is always reported as sent', () {
      expect(sendRoute, contains('shouldCreateUser: false'));
      expect(sendRoute, contains('{ ok: true }'));
      // No branch on the Supabase result: an unknown address must look the
      // same as a known one.
      expect(sendRoute, isNot(contains('if (error')));
      expect(sendRoute, isNot(contains('signInError')));
    });

    test('a wrong code and a non-admin account share one answer', () {
      expect(verifyRoute, contains('PUBLIC_ERROR.signInFailed'));
      expect(verifyRoute, contains('profile?.role !== "admin"'));
      expect(verifyRoute, contains('supabase.auth.signOut()'));
      expect(
        RegExp('PUBLIC_ERROR.signInFailed').allMatches(verifyRoute).length,
        1,
        reason: 'one shared failure response',
      );
    });

    test('the copy names neither the address nor the admin role', () {
      final message = RegExp(r'case PUBLIC_ERROR.signInFailed:\s*\n\s*return "([^"]+)"')
          .firstMatch(publicError)
          ?.group(1);
      expect(message, isNotNull);
      expect(message!.toLowerCase(), isNot(contains('admin')));
      expect(message.toLowerCase(), isNot(contains('exist')));
      expect(publicError, contains('rate_limited'));
    });
  });

  group('admin serves a strict CSP', () {
    test('script execution is nonce-gated, not host-gated', () {
      expect(csp, contains("'nonce-\${nonce}'"));
      expect(csp, contains("'strict-dynamic'"));
      final scriptSrc = csp.substring(
        csp.indexOf('const scriptSrc'),
        csp.indexOf('const connectSrc'),
      );
      expect(scriptSrc, isNot(contains("'unsafe-inline'")));
      // Eval is for `next dev` hot reload only.
      expect(scriptSrc, contains('isDev ?'));
    });

    test('framing, base tags and plugins are denied', () {
      expect(csp, contains('["frame-ancestors", ["\'none\'"]]'));
      expect(csp, contains('["object-src", ["\'none\'"]]'));
      expect(csp, contains('["base-uri", ["\'self\'"]]'));
      expect(csp, contains('["form-action", ["\'self\'"]]'));
      expect(csp, contains('upgrade-insecure-requests'));
    });

    test('only the configured Supabase origin may be called', () {
      expect(csp, contains('supabaseOrigins(supabaseUrl)'));
      expect(csp, contains('NEXT_PUBLIC_SUPABASE_URL'));
      expect(middleware, contains('process.env.NEXT_PUBLIC_SUPABASE_URL'));
    });

    test('every response carries the header and a fresh nonce', () {
      expect(middleware, contains('createNonce()'));
      expect(middleware, contains('response.headers.set("Content-Security-Policy", csp)'));
      expect(middleware, contains('"x-nonce": nonce'));
    });

    test('rendering stays dynamic so Next can stamp the nonce', () {
      expect(rootLayout, contains('export const dynamic = "force-dynamic"'));
    });
  });
}
