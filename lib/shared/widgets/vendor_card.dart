import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
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
  });

  final VendorProfile vendor;
  final VoidCallback onTap;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final price = AppConstants.formatPriceRange(
      vendor.priceMin,
      vendor.priceMax,
    );

    return Material(
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
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: AspectRatio(
                  aspectRatio: 16 / 10,
                  child: vendor.coverUrl != null
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
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 8, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            vendor.businessName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        if (onFavoriteToggle != null)
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            onPressed: onFavoriteToggle,
                            icon: Icon(
                              isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: isFavorite
                                  ? AppColors.favorite
                                  : AppColors.inkFaint,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          _categoryLabel(l10n, vendor.category),
                          style: const TextStyle(
                            color: AppColors.inkMuted,
                            fontSize: 13,
                          ),
                        ),
                        const Text(' · ', style: TextStyle(color: AppColors.inkFaint)),
                        Text(
                          vendor.city == CityCode.tripoli
                              ? l10n.cityTripoli
                              : l10n.cityBenghazi,
                          style: const TextStyle(
                            color: AppColors.inkMuted,
                            fontSize: 13,
                          ),
                        ),
                        if (vendor.isVerified) ...[
                          const SizedBox(width: 6),
                          VerifiedBadge(
                            compact: true,
                            label: l10n.verified,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        PriceRangeBadge(label: price),
                        const Spacer(),
                        if (vendor.avgRating != null)
                          RatingStars(
                            rating: vendor.avgRating!,
                            size: 16,
                            showValue: true,
                            count: vendor.reviewCount,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _categoryLabel(AppLocalizations l10n, VendorCategory c) {
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
}
