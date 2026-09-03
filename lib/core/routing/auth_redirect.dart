import '../providers/auth_provider.dart';

/// Routes that require a signed-in session. Discover, vendor detail, profile,
/// and auth screens stay open to guests.
const kAuthProtectedPrefixes = [
  '/favorites',
  '/bookings',
  '/booking',
  '/review',
  '/inbox',
  '/vendor-tools',
];

/// Only allow in-app relative paths (blocks open redirects).
String? safeReturnTo(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  final decoded = Uri.decodeComponent(raw);
  if (!decoded.startsWith('/') || decoded.startsWith('//')) return null;
  return decoded;
}

/// GoRouter redirect for guest vs signed-in guards and post-login `from`.
String? resolveAuthRedirect({
  required String location,
  required AuthFlowStatus status,
  required Uri uri,
}) {
  if (status == AuthFlowStatus.unknown && location != '/splash') {
    return '/splash';
  }

  final onSplash = location == '/splash';
  final onLanguage = location == '/auth/language';
  final onLogin = location == '/auth/login';
  final onRole = location == '/auth/role';
  final onProfileSetup = location == '/auth/profile-setup';

  // Incomplete onboarding must finish before browsing.
  if (status == AuthFlowStatus.needsRole && !onRole) {
    return '/auth/role';
  }
  if (status == AuthFlowStatus.needsProfile && !onProfileSetup) {
    return '/auth/profile-setup';
  }

  // Role/profile setup require a session.
  if (status == AuthFlowStatus.unauthenticated && (onRole || onProfileSetup)) {
    return '/auth/login';
  }

  if (status == AuthFlowStatus.authenticated) {
    // Leave /auth/otp alone so the screen can honor returnTo after verify.
    if (onSplash || onLanguage || onLogin) {
      return safeReturnTo(uri.queryParameters['from']) ?? '/discover';
    }
  }

  final needsAuth =
      kAuthProtectedPrefixes.any((prefix) => location.startsWith(prefix));
  if (needsAuth && status == AuthFlowStatus.unauthenticated) {
    final from = Uri.encodeComponent(uri.toString());
    return '/auth/login?from=$from';
  }

  return null;
}

/// Where to send the user after a successful OTP verify.
String resolvePostOtpLocation({
  required AuthFlowStatus status,
  String? returnTo,
}) {
  final safe = safeReturnTo(returnTo);
  if (safe != null && status == AuthFlowStatus.authenticated) {
    return safe;
  }
  if (status == AuthFlowStatus.needsRole) return '/auth/role';
  if (status == AuthFlowStatus.needsProfile) return '/auth/profile-setup';
  return '/discover';
}
