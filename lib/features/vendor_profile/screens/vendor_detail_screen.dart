import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/whatsapp.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/widgets.dart';
import '../../discovery/providers/vendors_provider.dart';
import '../../favorites/providers/favorites_provider.dart';

class VendorDetailScreen extends ConsumerWidget {
  const VendorDetailScreen({super.key, required this.vendorId});

  final String vendorId;

  Future<void> _openWhatsApp(String number) => openWhatsApp(number);

  Future<void> _report(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final auth = ref.read(authProvider);
    if (!auth.isLoggedIn) {
      final from = Uri.encodeComponent('/vendor/$vendorId');
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
    if (ok != true || reasonCtrl.text.trim().isEmpty) return;
    await DahrSupabase.client.from('reports').insert({
      'reported_by': auth.session!.user.id,
      'target_type': 'vendor',
      'target_id': vendorId,
      'reason': reasonCtrl.text.trim(),
    });
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.reportSuccess)),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final vendorAsync = ref.watch(vendorDetailProvider(vendorId));
    final reviewsAsync = ref.watch(vendorReviewsProvider(vendorId));
    final favIds = ref.watch(favoriteVendorIdsProvider);
    final isFav = favIds.maybeWhen(
      data: (ids) => ids.contains(vendorId),
      orElse: () => false,
    );

    return Scaffold(
      body: vendorAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(vendorDetailProvider(vendorId)),
        ),
        data: (vendor) {
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 260,
                pinned: true,
                actions: [
                  IconButton(
                    icon: Icon(
                      isFav ? Icons.favorite : Icons.favorite_border,
                      color: isFav ? AppColors.favorite : null,
                    ),
                    onPressed: () => ref
                        .read(favoritesProvider.notifier)
                        .toggle(vendorId, context: context),
                  ),
                  IconButton(
                    icon: const Icon(Icons.flag_outlined),
                    onPressed: () => _report(context, ref),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: vendor.photos.isEmpty
                      ? Container(color: AppColors.creamDark)
                      : PageView.builder(
                          itemCount: vendor.photos.length,
                          itemBuilder: (_, i) => CachedNetworkImage(
                            imageUrl: vendor.photos[i].storageUrl,
                            fit: BoxFit.cover,
                          ),
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
                          if (vendor.isVerified) const VerifiedBadge(),
                        ],
                      ),
                      const SizedBox(height: 8),
                      PriceRangeBadge(
                        label: AppConstants.formatPriceRange(
                          vendor.priceMin,
                          vendor.priceMax,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.description,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(vendor.description.isEmpty
                          ? '—'
                          : vendor.description),
                      if (vendor.services.isNotEmpty) ...[
                        const SizedBox(height: 16),
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
                      const SizedBox(height: 20),
                      Text(
                        l10n.reviews,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      reviewsAsync.when(
                        loading: () => const LinearProgressIndicator(),
                        error: (e, _) => Text(e.toString()),
                        data: (reviews) {
                          if (reviews.isEmpty) {
                            return Text(l10n.noReviews);
                          }
                          return Column(
                            children: reviews
                                .map(
                                  (r) => ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: RatingStars(
                                      rating: r.rating.toDouble(),
                                      size: 16,
                                    ),
                                    subtitle: Text(
                                      '${r.consumerName ?? ''} — ${r.comment}',
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
                    vendor.whatsappNumber!.isNotEmpty)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _openWhatsApp(vendor.whatsappNumber!),
                      icon: const Icon(Icons.chat),
                      label: Text(l10n.whatsapp),
                    ),
                  ),
                if (vendor.whatsappNumber != null &&
                    vendor.whatsappNumber!.isNotEmpty)
                  const SizedBox(width: 12),
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
