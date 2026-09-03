import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/models/models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/widgets.dart';
import '../providers/vendor_provider.dart';

class VendorDashboardScreen extends ConsumerWidget {
  const VendorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final statsAsync = ref.watch(vendorDashboardStatsProvider);
    final vendorAsync = ref.watch(myVendorProfileProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.vendorDashboard)),
      body: vendorAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(myVendorProfileProvider),
        ),
        data: (vendor) {
          if (vendor == null) {
            return EmptyState(
              message: l10n.setupVendorListing,
              icon: Icons.storefront_outlined,
              actionLabel: l10n.vendorOnboardingTitle,
              onAction: () => context.push('/vendor-tools/onboarding'),
            );
          }
          return statsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => ErrorState(
              message: e.toString(),
              onRetry: () => ref.invalidate(vendorDashboardStatsProvider),
            ),
            data: (stats) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (!vendor.isApproved)
                    Card(
                      color: AppColors.creamDark,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(l10n.onboardingPending),
                      ),
                    ),
                  const SizedBox(height: 12),
                  _StatTile(
                    label: l10n.views,
                    value: '${stats.views}',
                    icon: Icons.visibility_outlined,
                  ),
                  _StatTile(
                    label: l10n.pendingRequests,
                    value: '${stats.pending}',
                    icon: Icons.hourglass_empty,
                  ),
                  _StatTile(
                    label: l10n.acceptedRequests,
                    value: '${stats.accepted}',
                    icon: Icons.check_circle_outline,
                  ),
                  _StatTile(
                    label: l10n.photoCountStat,
                    value: '${stats.photoCount}',
                    icon: Icons.photo_library_outlined,
                  ),
                  _StatTile(
                    label: l10n.unpaidCommissionOwed,
                    value: AppConstants.formatPrice(stats.unpaidCommissionLyd),
                    icon: Icons.account_balance_wallet_outlined,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.nextBookedDates,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  if (stats.nextBookedDates.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(l10n.noUpcomingBooked),
                      ),
                    )
                  else
                    ...stats.nextBookedDates.map(
                      (d) => Card(
                        child: ListTile(
                          leading: const Icon(
                            Icons.event_busy,
                            color: AppColors.burgundy,
                          ),
                          title: Text(AvailabilityCalendar.dateKey(d)),
                          subtitle: Text(l10n.markBooked),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.unpaidCommissionOwed,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  if (stats.unpaidBookings.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(l10n.noUnpaidCommission),
                      ),
                    )
                  else
                    ...stats.unpaidBookings.map(
                      (b) => Card(
                        child: ListTile(
                          title: Text(
                            AvailabilityCalendar.dateKey(b.eventDate),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            '${l10n.quotedAmountDisplay}: '
                            '${AppConstants.formatPrice(b.quotedAmountLyd)}\n'
                            '${l10n.commissionDueLabel}: '
                            '${AppConstants.formatPrice(b.commissionAmountLyd)}',
                          ),
                          isThreeLine: true,
                          trailing: Text(
                            l10n.commissionUnpaid,
                            style: const TextStyle(
                              color: AppColors.warning,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () => context.go('/inbox'),
                    child: Text(l10n.vendorInbox),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () => context.push('/vendor-tools/photos'),
                    child: Text(l10n.managePhotos),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () => context.push('/vendor-tools/availability'),
                    child: Text(l10n.manageAvailability),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () => context.push('/vendor-tools/edit'),
                    child: Text(l10n.editListing),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: AppColors.burgundy),
        title: Text(label),
        trailing: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.burgundy,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
      ),
    );
  }
}
