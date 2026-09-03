import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/widgets.dart';
import '../providers/vendor_provider.dart';

class VendorAvailabilityScreen extends ConsumerWidget {
  const VendorAvailabilityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(vendorAvailabilityProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.availabilityTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final now = DateTime.now();
          final picked = await showDatePicker(
            context: context,
            initialDate: now,
            firstDate: now,
            lastDate: now.add(const Duration(days: 365 * 2)),
          );
          if (picked == null) return;
          await ref
              .read(vendorAvailabilityProvider.notifier)
              .upsertDate(picked, AvailabilityStatus.booked);
        },
        icon: const Icon(Icons.add),
        label: Text(l10n.markBooked),
      ),
      body: AsyncBody<List<AvailabilitySlot>>(
        value: async,
        onRetry: () =>
            ref.read(vendorAvailabilityProvider.notifier).refresh(),
        emptyWhen: (list) => list.isEmpty,
        empty: EmptyState(message: l10n.emptyDefault),
        builder: (context, slots) {
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: slots.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final s = slots[i];
              final booked = s.status == AvailabilityStatus.booked.name;
              return Card(
                child: ListTile(
                  title: Text(s.date.toIso8601String().split('T').first),
                  subtitle: Text(
                    booked ? l10n.markBooked : l10n.markAvailable,
                  ),
                  trailing: Switch(
                    value: booked,
                    activeColor: AppColors.burgundy,
                    onChanged: (v) {
                      ref.read(vendorAvailabilityProvider.notifier).upsertDate(
                            s.date,
                            v
                                ? AvailabilityStatus.booked
                                : AvailabilityStatus.available,
                          );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
