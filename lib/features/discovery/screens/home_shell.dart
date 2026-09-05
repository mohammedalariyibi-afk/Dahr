import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';

class HomeShell extends ConsumerWidget {
  const HomeShell({super.key, required this.child});

  final Widget child;

  int _indexForLocation(String loc) {
    if (loc.startsWith('/home')) return 0;
    if (loc.startsWith('/search') || loc.startsWith('/discover')) return 1;
    if (loc.startsWith('/bookings') || loc.startsWith('/inbox')) return 2;
    if (loc.startsWith('/profile') || loc.startsWith('/favorites')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final auth = ref.watch(authProvider);
    final isVendor = auth.isVendor;
    final loc = GoRouterState.of(context).matchedLocation;
    final index = _indexForLocation(loc);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        backgroundColor: AppColors.background,
        onDestinationSelected: (i) {
          switch (i) {
            case 0:
              context.go('/home');
            case 1:
              context.go('/search');
            case 2:
              context.go(isVendor ? '/inbox' : '/bookings');
            case 3:
              context.go('/profile');
          }
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: l10n.tabHome,
          ),
          NavigationDestination(
            icon: const Icon(Icons.search),
            selectedIcon: const Icon(Icons.search),
            label: l10n.tabSearch,
          ),
          NavigationDestination(
            icon: Icon(
              isVendor ? Icons.calendar_month_outlined : Icons.event_note_outlined,
            ),
            selectedIcon: Icon(
              isVendor ? Icons.calendar_month : Icons.event_note,
            ),
            label: isVendor ? l10n.tabInbox : l10n.tabBookings,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: l10n.tabProfile,
          ),
        ],
      ),
    );
  }
}
