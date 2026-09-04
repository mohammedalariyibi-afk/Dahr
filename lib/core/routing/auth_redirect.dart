import '../providers/auth_provider.dart';

/// Routes that require a signed-in session. Discover, vendor detail, profile,
/// legal screens, and auth screens stay open to guests.
const kAuthProtectedPrefixes = [
  '/favorites',
  '/bookings',
  '/booking',
  '/review',
  '/inbox',
  '/vendor-tools',
];

/// Vendor product surfaces. Onboarding stays open so a couple can become a
/// vendor. Inbox / dashboard / calendar / photos require `profiles.role`.
const kVendorOnlyPrefixes = [
  '/inbox',
  '/vendor-tools/dashboard',
  '/vendor-tools/availability',
  '/vendor-tools/edit',
  '/vendor-tools/photos',
];

bool isVendorOnlyLocation(String location) =>
    kVendorOnlyPrefixes.any((prefix) => location.startsWith(prefix));

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
  bool isVendor = false,
}) {
  if (status == AuthFlowStatus.unknown && location != '/splash') {
    return '/splash';
  }

  final onSplash = location == '/splash';
  final onLanguage = location == '/auth/language';
  final onLogin = location == '/auth/login';
  final onRole = location == '/auth/role';
  final onProfileSetup = location == '/auth/profile-setup';
  final onLegal = location.startsWith('/legal');

  // Incomplete onboarding must finish before browsing.
  // Legal screens stay reachable (store reviewers and the user).
  // Profile setup is the step after role, so it stays reachable too: a session
  // re-sync still reports needsRole while the name is blank, and bouncing back
  // would discard what the user typed.
  if (status == AuthFlowStatus.needsRole &&
      !onRole &&
      !onProfileSetup &&
      !onLegal) {
    return '/auth/role';
  }
  if (status == AuthFlowStatus.needsProfile && !onProfileSetup && !onLegal) {
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

  if (status == AuthFlowStatus.authenticated &&
      isVendorOnlyLocation(location) &&
      !isVendor) {
    return '/profile';
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
