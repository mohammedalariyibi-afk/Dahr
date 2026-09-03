import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/models.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/widgets.dart';
import '../providers/favorites_provider.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final auth = ref.watch(authProvider);

    if (auth.isGuest) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.favoritesTitle)),
        body: EmptyState(
          message: l10n.loginRequiredBody,
          icon: Icons.favorite_border,
          actionLabel: l10n.loginAction,
          onAction: () {
            final from = Uri.encodeComponent('/favorites');
            context.push('/auth/login?from=$from');
          },
        ),
      );
    }

    final async = ref.watch(favoriteVendorsProvider);
    final favIds = ref.watch(favoritesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.favoritesTitle)),
      body: AsyncBody<List<VendorProfile>>(
        value: async,
        onRetry: () => ref.invalidate(favoriteVendorsProvider),
        emptyWhen: (list) => list.isEmpty,
        empty: EmptyState(
          message: l10n.noFavorites,
          icon: Icons.favorite_border,
        ),
        builder: (context, vendors) {
          final ids = favIds.valueOrNull;
          final visible = ids == null
              ? vendors
              : vendors.where((v) => ids.contains(v.id)).toList();
          if (visible.isEmpty) {
            return EmptyState(
              message: l10n.noFavorites,
              icon: Icons.favorite_border,
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(favoriteVendorIdsProvider);
              ref.invalidate(favoriteVendorsProvider);
              await ref.read(favoriteVendorsProvider.future);
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: visible.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final v = visible[i];
                return VendorCard(
                  vendor: v,
                  isFavorite: true,
                  onTap: () => context.push('/vendor/${v.id}'),
                  onFavoriteToggle: () => ref
                      .read(favoritesProvider.notifier)
                      .toggle(
                        v.id,
                        context: context,
                        returnPath: '/favorites',
                      ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
