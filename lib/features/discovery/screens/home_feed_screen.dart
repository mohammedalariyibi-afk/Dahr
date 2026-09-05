import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/category_labels.dart';
import '../../../core/models/models.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/widgets.dart';
import '../../favorites/providers/favorites_provider.dart';
import '../providers/vendors_provider.dart';

class HomeFeedScreen extends ConsumerWidget {
  const HomeFeedScreen({super.key});

  static const _gridCats = <VendorCategory>[
    VendorCategory.venues,
    VendorCategory.photography,
    VendorCategory.catering,
    VendorCategory.dresses,
    VendorCategory.beauty,
    VendorCategory.music,
    VendorCategory.cars,
    VendorCategory.decor,
  ];

  static const _catIcons = <VendorCategory, IconData>{
    VendorCategory.venues: Icons.storefront_outlined,
    VendorCategory.photography: Icons.photo_camera_outlined,
    VendorCategory.catering: Icons.restaurant_outlined,
    VendorCategory.dresses: Icons.checkroom_outlined,
    VendorCategory.beauty: Icons.spa_outlined,
    VendorCategory.music: Icons.music_note_outlined,
    VendorCategory.cars: Icons.directions_car_outlined,
    VendorCategory.decor: Icons.palette_outlined,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final filters = ref.watch(vendorFiltersProvider);
    final vendorsAsync = ref.watch(homeVendorsProvider);
    final favIds = ref.watch(favoriteVendorIdsProvider);
    final profile = ref.watch(authProvider).profile;
    final city = filters.city ?? profile?.city ?? CityCode.tripoli;
    final cityLabel =
        city == CityCode.benghazi ? l10n.cityBenghazi : l10n.cityTripoli;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            DahrHeader(
              cityLabel: cityLabel,
              onCityTap: () => _pickCity(context, ref, filters.city),
              onNotifications: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.notifications)),
                );
              },
            ),
            Expanded(
              child: AsyncBody<List<VendorProfile>>(
                value: vendorsAsync,
                onRetry: () => ref.invalidate(homeVendorsProvider),
                emptyWhen: (list) => list.isEmpty,
                empty: EmptyState(
                  message: l10n.emptyDefault,
                  icon: Icons.storefront_outlined,
                ),
                builder: (context, vendors) {
                  final featured = [
                    ...vendors.where((v) => v.isVerified),
                    ...vendors.where((v) => !v.isVerified),
                  ].take(8).toList();
                  final recent = vendors.take(12).toList();
                  return RefreshIndicator(
                    color: AppColors.glacier,
                    onRefresh: () async =>
                        ref.invalidate(homeVendorsProvider),
                    child: CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.homeHeadline,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(color: AppColors.ink),
                                ),
                                const SizedBox(height: 16),
                                TextField(
                                  readOnly: true,
                                  onTap: () => context.go('/search'),
                                  decoration: InputDecoration(
                                    hintText: l10n.homeSearchHint,
                                    prefixIcon: const Icon(Icons.search),
                                    filled: true,
                                    fillColor: AppColors.surface,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(28),
                                      borderSide: const BorderSide(
                                        color: AppColors.border,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(28),
                                      borderSide: const BorderSide(
                                        color: AppColors.border,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 28),
                                GridView.count(
                                  crossAxisCount: 4,
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  mainAxisSpacing: 16,
                                  crossAxisSpacing: 8,
                                  childAspectRatio: 0.78,
                                  children: [
                                    for (final c in _gridCats)
                                      _CategoryTile(
                                        icon: _catIcons[c]!,
                                        label: localizedCategory(l10n, c),
                                        onTap: () {
                                          ref
                                              .read(
                                                vendorFiltersProvider.notifier,
                                              )
                                              .setCategory(c);
                                          context.go('/search');
                                        },
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    l10n.featuredVendors,
                                    style:
                                        Theme.of(context).textTheme.titleLarge,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => context.go('/search'),
                                  child: Text(l10n.seeAll),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: SizedBox(
                            height: 268,
                            child: ListView.separated(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              scrollDirection: Axis.horizontal,
                              itemCount: featured.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 12),
                              itemBuilder: (context, i) {
                                final v = featured[i];
                                final isFav = favIds.maybeWhen(
                                  data: (ids) => ids.contains(v.id),
                                  orElse: () => false,
                                );
                                return VendorCard(
                                  vendor: v,
                                  featured: true,
                                  isFavorite: isFav,
                                  onTap: () => context.push('/vendor/${v.id}'),
                                  onFavoriteToggle: () => ref
                                      .read(favoritesProvider.notifier)
                                      .toggle(v.id, context: context),
                                );
                              },
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                            child: Text(
                              l10n.recentlyAdded,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                          sliver: SliverList.separated(
                            itemCount: recent.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, i) {
                              final v = recent[i];
                              final isFav = favIds.maybeWhen(
                                data: (ids) => ids.contains(v.id),
                                orElse: () => false,
                              );
                              return VendorCard(
                                vendor: v,
                                isFavorite: isFav,
                                onTap: () => context.push('/vendor/${v.id}'),
                                onFavoriteToggle: () => ref
                                    .read(favoritesProvider.notifier)
                                    .toggle(v.id, context: context),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _pickCity(BuildContext context, WidgetRef ref, CityCode? current) {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(l10n.allCategories),
                selected: current == null,
                onTap: () {
                  ref.read(vendorFiltersProvider.notifier).setCity(null);
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                title: Text(l10n.cityTripoli),
                selected: current == CityCode.tripoli,
                onTap: () {
                  ref
                      .read(vendorFiltersProvider.notifier)
                      .setCity(CityCode.tripoli);
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                title: Text(l10n.cityBenghazi),
                selected: current == CityCode.benghazi,
                onTap: () {
                  ref
                      .read(vendorFiltersProvider.notifier)
                      .setCity(CityCode.benghazi);
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: Icon(icon, color: AppColors.ink),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.inkMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
