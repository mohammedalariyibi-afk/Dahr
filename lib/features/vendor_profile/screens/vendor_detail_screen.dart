import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/whatsapp.dart';
import '../../../core/models/models.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/security/safe_user_error.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/widgets.dart';
import '../../discovery/providers/vendors_provider.dart';
import '../../favorites/providers/favorites_provider.dart';

class VendorDetailScreen extends ConsumerStatefulWidget {
  const VendorDetailScreen({super.key, required this.vendorId});

  final String vendorId;

  @override
  ConsumerState<VendorDetailScreen> createState() => _VendorDetailScreenState();
}

class _VendorDetailScreenState extends ConsumerState<VendorDetailScreen> {
  int _galleryIndex = 0;

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

  Future<void> _openWhatsApp(BuildContext context, String number) async {
    final l10n = AppLocalizations.of(context);
    final ok = await openWhatsApp(number);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorGeneric)),
      );
    }
  }

  Future<void> _report(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final auth = ref.read(authProvider);
    if (!auth.isLoggedIn) {
      final from = Uri.encodeComponent('/vendor/${widget.vendorId}');
      context.push('/auth/login?from=$from');
      return;
    }
    final reasonCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.report),
        content: TextField(
          controller: reasonCtrl,
          decoration: InputDecoration(labelText: l10n.reportReason),
          maxLines: 3,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.reportSubmit),
          ),
        ],
      ),
    );
    final reason = reasonCtrl.text.trim();
    reasonCtrl.dispose();
    if (ok != true || reason.isEmpty) return;

    try {
      await DahrSupabase.client.from('reports').insert({
        'reported_by': auth.session!.user.id,
        'target_type': 'vendor',
        'target_id': widget.vendorId,
        'reason': reason,
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.reportSuccess)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorGeneric)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final vendorId = widget.vendorId;
    final vendorAsync = ref.watch(vendorDetailProvider(vendorId));
    final reviewsAsync = ref.watch(vendorReviewsProvider(vendorId));
    final favIds = ref.watch(favoritesProvider);
    final isFav = favIds.maybeWhen(
      data: (ids) => ids.contains(vendorId),
      orElse: () => false,
    );

    return Scaffold(
      appBar: vendorAsync.hasValue ? null : AppBar(),
      body: vendorAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorState(
          message: SafeUserError.of(l10n, e),
          onRetry: () => ref.invalidate(vendorDetailProvider(vendorId)),
        ),
        data: (vendor) {
          final photos = vendor.photos;
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                actions: [
                  IconButton(
                    tooltip: isFav ? l10n.unfavorite : l10n.favorite,
                    icon: Icon(
                      isFav ? Icons.favorite : Icons.favorite_border,
                      color: isFav ? AppColors.favorite : null,
                    ),
                    onPressed: () => ref.read(favoritesProvider.notifier).toggle(
                          vendorId,
                          context: context,
                          returnPath: '/vendor/$vendorId',
                        ),
                  ),
                  IconButton(
                    tooltip: l10n.report,
                    icon: const Icon(Icons.flag_outlined),
                    onPressed: () => _report(context),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (photos.isEmpty)
                        Container(
                          color: AppColors.creamDark,
                          child: const Icon(
                            Icons.storefront_outlined,
                            size: 64,
                            color: AppColors.inkFaint,
                          ),
                        )
                      else
                        PageView.builder(
                          itemCount: photos.length,
                          onPageChanged: (i) =>
                              setState(() => _galleryIndex = i),
                          itemBuilder: (_, i) => CachedNetworkImage(
                            imageUrl: photos[i].storageUrl,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              color: AppColors.skeletonBase,
                            ),
                            errorWidget: (_, __, ___) => Container(
                              color: AppColors.creamDark,
                              child: const Icon(
                                Icons.image_not_supported_outlined,
                                color: AppColors.inkFaint,
                              ),
                            ),
                          ),
                        ),
                      if (photos.length > 1)
                        Positioned(
                          bottom: 12,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              photos.length,
                              (i) => Container(
                                width: 8,
                                height: 8,
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 3),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: i == _galleryIndex
                                      ? AppColors.surface
                                      : AppColors.surface.withValues(alpha: 0.45),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              vendor.businessName,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                          if (vendor.isVerified)
                            VerifiedBadge(label: l10n.verified),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_catLabel(l10n, vendor.category)} · '
                        '${vendor.city == CityCode.tripoli ? l10n.cityTripoli : l10n.cityBenghazi}',
                        style: const TextStyle(color: AppColors.inkMuted),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          PriceRangeBadge(
                            label: AppConstants.formatPriceRange(
                              vendor.priceMin,
                              vendor.priceMax,
                            ),
                          ),
                          if (vendor.avgRating != null) ...[
                            const SizedBox(width: 12),
                            RatingStars(
                              rating: vendor.avgRating!,
                              size: 18,
                              showValue: true,
                              count: vendor.reviewCount,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        l10n.description,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        vendor.description.isEmpty ? '—' : vendor.description,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      if (vendor.services.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Text(
                          l10n.services,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: vendor.services
                              .map((s) => Chip(label: Text(s)))
                              .toList(),
                        ),
                      ],
                      const SizedBox(height: 24),
                      Text(
                        l10n.reviews,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      reviewsAsync.when(
                        loading: () => const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: LinearProgressIndicator(),
                        ),
                        error: (e, _) => Text(
                          SafeUserError.of(l10n, e),
                          style: const TextStyle(color: AppColors.error),
                        ),
                        data: (reviews) {
                          if (reviews.isEmpty) {
                            return Text(
                              l10n.noReviews,
                              style: const TextStyle(color: AppColors.inkMuted),
                            );
                          }
                          return Column(
                            children: reviews
                                .map(
                                  (r) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            RatingStars(
                                              rating: r.rating.toDouble(),
                                              size: 16,
                                            ),
                                            const SizedBox(width: 8),
                                            if (r.consumerName != null &&
                                                r.consumerName!.isNotEmpty)
                                              Text(
                                                r.consumerName!,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.inkMuted,
                                                ),
                                              ),
                                          ],
                                        ),
                                        if (r.comment.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(r.comment),
                                        ],
                                      ],
                                    ),
                                  ),
                                )
                                .toList(),
                          );
                        },
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: vendorAsync.maybeWhen(
        data: (vendor) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: [
                if (vendor.whatsappNumber != null &&
                    vendor.whatsappNumber!.isNotEmpty) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          _openWhatsApp(context, vendor.whatsappNumber!),
                      icon: const Icon(Icons.chat),
                      label: Text(l10n.whatsapp),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      final auth = ref.read(authProvider);
                      if (!auth.isLoggedIn) {
                        final from =
                            Uri.encodeComponent('/booking/$vendorId');
                        context.push('/auth/login?from=$from');
                        return;
                      }
                      context.push('/booking/$vendorId');
                    },
                    child: Text(l10n.bookNow),
                  ),
                ),
              ],
            ),
          ),
        ),
        orElse: () => null,
      ),
    );
  }
}
