import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import 'auth_redirect.dart';
import '../../features/auth/providers/auth_form_validators.dart';
import '../../features/auth/screens/language_selection_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/otp_verify_screen.dart';
import '../../features/auth/screens/role_select_screen.dart';
import '../../features/auth/screens/profile_setup_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/discovery/screens/discover_home_screen.dart';
import '../../features/discovery/screens/home_shell.dart';
import '../../features/favorites/screens/favorites_screen.dart';
import '../../features/booking/screens/booking_request_screen.dart';
import '../../features/booking/screens/consumer_booking_detail_screen.dart';
import '../../features/booking/screens/consumer_bookings_screen.dart';
import '../../features/reviews/screens/leave_review_screen.dart';
import '../../features/vendor_profile/screens/vendor_detail_screen.dart';
import '../../features/vendor_profile/screens/vendor_onboarding_screen.dart';
import '../../features/vendor_profile/screens/vendor_dashboard_screen.dart';
import '../../features/vendor_profile/screens/vendor_inbox_screen.dart';
import '../../features/vendor_profile/screens/vendor_availability_screen.dart';
import '../../features/vendor_profile/screens/vendor_edit_profile_screen.dart';
import '../../features/vendor_profile/screens/vendor_photos_screen.dart';
import '../../features/auth/screens/profile_tab_screen.dart';
import '../../features/legal/legal_documents.dart';
import '../../features/legal/screens/legal_document_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: _AuthRefresh(ref),
    redirect: (context, state) => resolveAuthRedirect(
      location: state.matchedLocation,
      status: auth.status,
      uri: state.uri,
      isVendor: auth.isVendor,
    ),
    routes: [
      GoRoute(
        path: '/splash',
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: '/auth/language',
        builder: (_, __) => const LanguageSelectionScreen(),
      ),
      GoRoute(
        path: '/auth/login',
        builder: (context, state) {
          final from = state.uri.queryParameters['from'];
          return LoginScreen(returnTo: from);
        },
      ),
      GoRoute(
        path: '/auth/otp',
        builder: (context, state) {
          final extra = state.extra as Map<String, String>? ?? {};
          return OtpVerifyScreen(
            channel: AuthLoginSpec.otpChannel(requested: extra['channel']),
            destination: extra['destination'] ?? '',
            returnTo: extra['returnTo'],
          );
        },
      ),
      GoRoute(
        path: '/auth/role',
        builder: (_, __) => const RoleSelectScreen(),
      ),
      GoRoute(
        path: '/auth/profile-setup',
        builder: (_, __) => const ProfileSetupScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => HomeShell(child: child),
        routes: [
          GoRoute(
            path: '/discover',
            pageBuilder: (_, __) => const NoTransitionPage(
              child: DiscoverHomeScreen(),
            ),
          ),
          GoRoute(
            path: '/favorites',
            pageBuilder: (_, __) => const NoTransitionPage(
              child: FavoritesScreen(),
            ),
          ),
          GoRoute(
            path: '/bookings',
            pageBuilder: (_, __) => const NoTransitionPage(
              child: ConsumerBookingsScreen(),
            ),
          ),
          GoRoute(
            path: '/inbox',
            pageBuilder: (_, __) => const NoTransitionPage(
              child: VendorInboxScreen(),
            ),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (_, __) => const NoTransitionPage(
              child: ProfileTabScreen(),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/vendor/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return VendorDetailScreen(vendorId: id);
        },
      ),
      GoRoute(
        path: '/booking/:vendorId',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          return BookingRequestScreen(
            vendorId: state.pathParameters['vendorId']!,
          );
        },
      ),
      GoRoute(
        path: '/bookings/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          return ConsumerBookingDetailScreen(
            bookingId: state.pathParameters['id']!,
          );
        },
      ),
      GoRoute(
        path: '/review/:bookingId',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra as Map<String, String>? ?? {};
          return LeaveReviewScreen(
            bookingRequestId: state.pathParameters['bookingId']!,
            vendorId: extra['vendorId'] ?? '',
          );
        },
      ),
      GoRoute(
        path: '/vendor-tools/onboarding',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const VendorOnboardingScreen(),
      ),
      GoRoute(
        path: '/vendor-tools/dashboard',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const VendorDashboardScreen(),
      ),
      GoRoute(
        path: '/vendor-tools/availability',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const VendorAvailabilityScreen(),
      ),
      GoRoute(
        path: '/vendor-tools/edit',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const VendorEditProfileScreen(),
      ),
      GoRoute(
        path: '/vendor-tools/photos',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const VendorPhotosScreen(),
      ),
      GoRoute(
        path: '/legal/privacy',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const LegalDocumentScreen(
          kind: LegalDocumentKind.privacy,
        ),
      ),
      GoRoute(
        path: '/legal/terms',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const LegalDocumentScreen(
          kind: LegalDocumentKind.terms,
        ),
      ),
    ],
  );
});

/// Bridges Riverpod auth changes into GoRouter refresh.
class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(Ref ref) {
    ref.listen<AppAuthState>(authProvider, (_, __) => notifyListeners());
  }
}
