import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/generated/app_localizations.dart';

/// Vendor-only unpaid 10% total. Hidden when nothing is owed.
///
/// No WhatsApp or bank pay instructions — collection copy is blocked.
class VendorCommissionBanner extends StatelessWidget {
  const VendorCommissionBanner({
    super.key,
    required this.unpaidTotalLyd,
    this.margin = const EdgeInsets.fromLTRB(16, 12, 16, 4),
  });

  final double unpaidTotalLyd;
  final EdgeInsetsGeometry margin;

  bool get _visible => unpaidTotalLyd.isFinite && unpaidTotalLyd > 0;

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final amount = AppConstants.formatPrice(unpaidTotalLyd);

    return Card(
      color: AppColors.creamDark,
      margin: margin,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.account_balance_wallet_outlined,
              color: AppColors.burgundy,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.commissionBannerTitle,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppColors.burgundy,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.commissionBannerBody(amount),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.commissionBannerHint,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.inkMuted,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
