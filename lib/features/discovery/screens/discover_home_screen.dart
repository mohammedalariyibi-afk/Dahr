import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/widgets.dart';
import '../../favorites/providers/favorites_provider.dart';
import '../providers/vendors_provider.dart';

class DiscoverHomeScreen extends ConsumerStatefulWidget {
  const DiscoverHomeScreen({super.key});

  @override
  ConsumerState<DiscoverHomeScreen> createState() => _DiscoverHomeScreenState();
}

class _DiscoverHomeScreenState extends ConsumerState<DiscoverHomeScreen> {
  final _searchCtrl = TextEditingController();
  Timer? _searchDebounce;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  String _catLabel(AppLocalizations l10n, VendorCategory c) {
    switch (c) {
      case VendorCategory.venues:
        return l10n.categoryVenues;
      case VendorCategory.photography:
        return l10n.categoryPhotography;
      case VendorCategory.catering:
        return l10n.categoryCatering;
      case VendorCategory.dresses:
        return l10n.categoryDresses;
      case VendorCategory.beauty:
        return l10n.categoryBeauty;
      case VendorCategory.music:
        return l10n.categoryMusic;
      case VendorCategory.cars:
        return l10n.categoryCars;
      case VendorCategory.decor:
        return l10n.categoryDecor;
      case VendorCategory.other:
        return l10n.categoryOther;
    }
  }

  String _cityLabel(AppLocalizations l10n, CityCode city) {
    return city == CityCode.tripoli ? l10n.cityTripoli : l10n.cityBenghazi;
  }

  void _showFilters() {
    final l10n = AppLocalizations.of(context);
    final filters = ref.read(vendorFiltersProvider);
    CityCode? city = filters.city;
    final minCtrl =
        TextEditingController(text: filters.priceMin?.toStringAsFixed(0) ?? '');
    final maxCtrl =
        TextEditingController(text: filters.priceMax?.toStringAsFixed(0) ?? '');

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: StatefulBuilder(
            builder: (context, setModal) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.filters,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Text(l10n.cityLabel),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: Text(l10n.allCategories),
                        selected: city == null,
                        onSelected: (_) => setModal(() => city = null),
                      ),
                      ChoiceChip(
                        label: Text(l10n.cityTripoli),
                        selected: city == CityCode.tripoli,
                        onSelected: (_) =>
                            setModal(() => city = CityCode.tripoli),
                      ),
                      ChoiceChip(
                        label: Text(l10n.cityBenghazi),
                        selected: city == CityCode.benghazi,
                        onSelected: (_) =>
                            setModal(() => city = CityCode.benghazi),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: minCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: l10n.priceMin),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: maxCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: l10n.priceMax),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () {
                      ref.read(vendorFiltersProvider.notifier).setCity(city);
                      ref.read(vendorFiltersProvider.notifier).setPriceRange(
                            double.tryParse(minCtrl.text),
                            double.tryParse(maxCtrl.text),
                          );
                      Navigator.pop(ctx);
                    },
                    child: Text(l10n.applyFilters),
                  ),
                  TextButton(
                    onPressed: () {
                      ref.read(vendorFiltersProvider.notifier).clear();
                      _searchCtrl.clear();
                      setState(() {});
                      Navigator.pop(ctx);
                    },
                    child: Text(l10n.clearFilters),
                  ),
                ],
              );
            },
          ),
        );
      },
    ).whenComplete(() {
      minCtrl.dispose();
      maxCtrl.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final filters = ref.watch(vendorFiltersProvider);
    final vendorsAsync = ref.watch(vendorsProvider);
    final favIds = ref.watch(favoritesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appName),
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: filters.hasActiveFilters,
              smallSize: 8,
              backgroundColor: AppColors.burgundy,
              child: const Icon(Icons.tune),
            ),
            onPressed: _showFilters,
            tooltip: l10n.filters,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: l10n.searchHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchDebounce?.cancel();
                          _searchCtrl.clear();
                          ref
                              .read(vendorFiltersProvider.notifier)
                              .setSearch(null);
                          setState(() {});
                        },
                      )
                    : null,
              ),
              onChanged: (v) {
                setState(() {});
                _searchDebounce?.cancel();
                _searchDebounce = Timer(const Duration(milliseconds: 350), () {
                  ref.read(vendorFiltersProvider.notifier).setSearch(v);
                });
              },
              textInputAction: TextInputAction.search,
              onSubmitted: (v) {
                _searchDebounce?.cancel();
                ref.read(vendorFiltersProvider.notifier).setSearch(v);
              },
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: CategoryChip(
                    label: l10n.allCategories,
                    selected: filters.category == null,
                    onSelected: (_) => ref
                        .read(vendorFiltersProvider.notifier)
                        .setCategory(null),
                  ),
                ),
                ...VendorCategory.values.map(
                  (c) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: CategoryChip(
                      label: _catLabel(l10n, c),
                      selected: filters.category == c,
                      onSelected: (_) => ref
                          .read(vendorFiltersProvider.notifier)
                          .setCategory(filters.category == c ? null : c),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (filters.hasActiveFilters) ...[
            const SizedBox(height: 4),
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  if (filters.city != null)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: 8),
                      child: InputChip(
                        label: Text(_cityLabel(l10n, filters.city!)),
                        onDeleted: () => ref
                            .read(vendorFiltersProvider.notifier)
                            .setCity(null),
                      ),
                    ),
                  if (filters.priceMin != null || filters.priceMax != null)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: 8),
                      child: InputChip(
                        label: Text(
                          [
                            if (filters.priceMin != null)
                              '${l10n.priceMin}: ${filters.priceMin!.toStringAsFixed(0)}',
                            if (filters.priceMax != null)
                              '${l10n.priceMax}: ${filters.priceMax!.toStringAsFixed(0)}',
                          ].join(' · '),
                        ),
                        onDeleted: () => ref
                            .read(vendorFiltersProvider.notifier)
                            .setPriceRange(null, null),
                      ),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          Expanded(
            child: AsyncBody<List<VendorProfile>>(
              value: vendorsAsync,
              onRetry: () => ref.read(vendorsProvider.notifier).refresh(),
              emptyWhen: (list) => list.isEmpty,
              empty: EmptyState(
                message: l10n.emptyDefault,
                icon: Icons.storefront_outlined,
              ),
              builder: (context, vendors) {
                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(vendorsProvider.notifier).refresh(),
                  color: AppColors.burgundy,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: vendors.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final v = vendors[i];
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
                            .toggle(
                              v.id,
                              context: context,
                              returnPath: '/discover',
                            ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
