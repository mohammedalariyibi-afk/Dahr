import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/l10n/category_labels.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/generated/app_localizations.dart';
import 'badges.dart';

class VendorCard extends StatelessWidget {
  const VendorCard({
    super.key,
    required this.vendor,
    required this.onTap,
    this.isFavorite = false,
    this.onFavoriteToggle,
    this.featured = false,
  });

  final VendorProfile vendor;
  final VoidCallback onTap;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;
  final bool featured;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final city = vendor.city == CityCode.tripoli
        ? l10n.cityTripoli
        : l10n.cityBenghazi;
    final price = vendor.priceMin == null && vendor.priceMax == null
        ? l10n.priceOnRequest
        : l10n.startsFrom(
            AppConstants.formatPrice(vendor.priceMin ?? vendor.priceMax),
          );

    final card = Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: featured ? MainAxisSize.min : MainAxisSize.max,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: AspectRatio(
                  aspectRatio: featured ? 16 / 10 : 16 / 9,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      vendor.coverUrl != null
                          ? CachedNetworkImage(
                              imageUrl: vendor.coverUrl!,
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
                            )
                          : Container(
                              color: AppColors.creamDark,
                              child: const Icon(
                                Icons.storefront_outlined,
                                size: 40,
                                color: AppColors.inkFaint,
                              ),
                            ),
                      if (vendor.isVerified)
                        const PositionedDirectional(
                          top: 10,
                          start: 10,
                          child: VerifiedBadge(compact: true),
                        ),
                      if (onFavoriteToggle != null)
                        PositionedDirectional(
                          top: 8,
                          end: 8,
                          child: Material(
                            color: AppColors.background.withOpacity(0.55),
                            shape: const CircleBorder(),
                            child: IconButton(
                              visualDensity: VisualDensity.compact,
                              onPressed: onFavoriteToggle,
                              icon: Icon(
                                isFavorite
                                    ? Icons.bookmark
                                    : Icons.bookmark_border,
                                color: isFavorite
                                    ? AppColors.glacier
                                    : AppColors.ink,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vendor.businessName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${localizedCategory(l10n, vendor.category)} · $city',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.inkMuted,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        if (vendor.avgRating != null)
                          RatingStars(
                            rating: vendor.avgRating!,
                            size: 14,
                            showValue: true,
                            count: featured ? null : vendor.reviewCount,
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      price,
                      style: const TextStyle(
                        color: AppColors.glacier,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (featured) return SizedBox(width: 280, child: card);
    return card;
  }
}
