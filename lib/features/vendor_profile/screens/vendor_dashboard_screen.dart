import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(vendorDashboardStatsProvider),
        ),
        data: (stats) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              vendorAsync.maybeWhen(
                data: (v) {
                  if (v != null && !v.isApproved) {
                    return Card(
                      color: AppColors.creamDark,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(l10n.onboardingPending),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
                orElse: () => const SizedBox.shrink(),
              ),
              const SizedBox(height: 12),
              _StatTile(
                label: l10n.views,
                value: '${stats['views'] ?? 0}',
                icon: Icons.visibility_outlined,
              ),
              _StatTile(
                label: l10n.pendingRequests,
                value: '${stats['pending'] ?? 0}',
                icon: Icons.hourglass_empty,
              ),
              _StatTile(
                label: l10n.acceptedRequests,
                value: '${stats['accepted'] ?? 0}',
                icon: Icons.check_circle_outline,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.go('/inbox'),
                child: Text(l10n.vendorInbox),
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
        trailing: Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.burgundy,
                fontWeight: FontWeight.w800,
              ),
        ),
      ),
    );
  }
}
