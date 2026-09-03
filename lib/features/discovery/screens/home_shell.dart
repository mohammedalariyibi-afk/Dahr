import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../l10n/generated/app_localizations.dart';

class HomeShell extends ConsumerWidget {
  const HomeShell({super.key, required this.child});

  final Widget child;

  int _indexForLocation(String loc, bool isVendor) {
    if (loc.startsWith('/discover')) return 0;
    if (loc.startsWith('/favorites')) return 1;
    if (loc.startsWith('/bookings') || loc.startsWith('/inbox')) return 2;
    if (loc.startsWith('/profile')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final auth = ref.watch(authProvider);
    final isVendor = auth.isVendor;
    final loc = GoRouterState.of(context).matchedLocation;
    final index = _indexForLocation(loc, isVendor);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) {
          switch (i) {
            case 0:
              context.go('/discover');
            case 1:
              context.go('/favorites');
            case 2:
              context.go(isVendor ? '/inbox' : '/bookings');
            case 3:
              context.go('/profile');
          }
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.explore_outlined),
            selectedIcon: const Icon(Icons.explore),
            label: l10n.tabDiscover,
          ),
          NavigationDestination(
            icon: const Icon(Icons.favorite_border),
            selectedIcon: const Icon(Icons.favorite),
            label: l10n.tabFavorites,
          ),
          NavigationDestination(
            icon: Icon(isVendor ? Icons.inbox_outlined : Icons.event_note_outlined),
            selectedIcon: Icon(isVendor ? Icons.inbox : Icons.event_note),
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
