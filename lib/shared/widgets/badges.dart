import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/generated/app_localizations.dart';

class RatingStars extends StatelessWidget {
  const RatingStars({
    super.key,
    required this.rating,
    this.size = 18,
    this.showValue = false,
    this.count,
  });

  final double rating;
  final double size;
  final bool showValue;
  final int? count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(5, (i) {
          final filled = rating >= i + 1;
          final half = !filled && rating > i && rating < i + 1;
          return Icon(
            half
                ? Icons.star_half_rounded
                : filled
                    ? Icons.star_rounded
                    : Icons.star_outline_rounded,
            size: size,
            color: AppColors.star,
          );
        }),
        if (showValue) ...[
          const SizedBox(width: 6),
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              fontSize: size * 0.75,
              color: AppColors.inkMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        if (count != null) ...[
          const SizedBox(width: 4),
          Text(
            '($count)',
            style: TextStyle(
              fontSize: size * 0.7,
              color: AppColors.inkFaint,
            ),
          ),
        ],
      ],
    );
  }
}

class VerifiedBadge extends StatelessWidget {
  const VerifiedBadge({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.background.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.verified_rounded,
            size: compact ? 14 : 16,
            color: AppColors.glacier,
          ),
          if (!compact) ...[
            const SizedBox(width: 4),
            Text(
              AppLocalizations.of(context).verified,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.glacier,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class PriceRangeBadge extends StatelessWidget {
  const PriceRangeBadge({
    super.key,
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.glacier.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: AppColors.glacier,
          fontSize: 13,
        ),
      ),
    );
  }
}

class CategoryChip extends StatelessWidget {
  const CategoryChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      selectedColor: AppColors.chipSelectedBg,
      checkmarkColor: AppColors.chipSelectedFg,
      labelStyle: TextStyle(
        color: selected ? AppColors.chipSelectedFg : AppColors.chipFg,
        fontWeight: FontWeight.w500,
      ),
      backgroundColor: AppColors.chipBg,
      side: BorderSide.none,
    );
  }
}
