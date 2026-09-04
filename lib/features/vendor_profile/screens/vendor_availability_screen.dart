import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/models.dart';
import '../../../core/security/safe_user_error.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/widgets.dart';
import '../providers/vendor_provider.dart';

class VendorAvailabilityScreen extends ConsumerWidget {
  const VendorAvailabilityScreen({super.key});

  /// Availability writes can be rejected by RLS; report instead of dropping.
  static Future<void> _runWrite(
    BuildContext context,
    AppLocalizations l10n,
    Future<void> Function() write,
  ) async {
    try {
      await write();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(SafeUserError.of(l10n, e))),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(vendorAvailabilityProvider);
    final now = DateTime.now();
    final first = DateTime(now.year, now.month, now.day);
    final last = first.add(const Duration(days: 365 * 2));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.availabilityTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: first,
            firstDate: first,
            lastDate: last,
          );
          if (picked == null) return;
          if (!context.mounted) return;
          await _runWrite(
            context,
            l10n,
            () => ref
                .read(vendorAvailabilityProvider.notifier)
                .toggleDate(picked),
          );
        },
        icon: const Icon(Icons.event),
        label: Text(l10n.markBooked),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorState(
          message: SafeUserError.of(l10n, e),
          onRetry: () => ref.read(vendorAvailabilityProvider.notifier).refresh(),
        ),
        data: (slots) {
          final booked = AvailabilityCalendar.upcomingBookedDates(slots);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(l10n.toggleAvailabilityHint),
              const SizedBox(height: 12),
              Card(
                child: SizedBox(
                  height: 360,
                  child: CalendarDatePicker(
                    initialDate: first,
                    currentDate: first,
                    firstDate: first,
                    lastDate: last,
                    onDateChanged: (date) => _runWrite(
                      context,
                      l10n,
                      () => ref
                          .read(vendorAvailabilityProvider.notifier)
                          .toggleDate(date),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.bookedDatesTitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              if (booked.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(l10n.noBookedDates),
                  ),
                )
              else
                ...booked.map((d) {
                  return Card(
                    child: ListTile(
                      title: Text(AvailabilityCalendar.dateKey(d)),
                      subtitle: Text(l10n.markBooked),
                      trailing: Switch(
                        value: true,
                        activeThumbColor: AppColors.burgundy,
                        onChanged: (_) => _runWrite(
                          context,
                          l10n,
                          () => ref
                              .read(vendorAvailabilityProvider.notifier)
                              .upsertDate(d, AvailabilityStatus.available),
                        ),
                      ),
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}
