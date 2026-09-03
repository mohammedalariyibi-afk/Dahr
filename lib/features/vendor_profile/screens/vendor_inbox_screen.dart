import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/widgets.dart';
import '../../booking/providers/booking_provider.dart';

class VendorInboxScreen extends ConsumerWidget {
  const VendorInboxScreen({super.key});

  String _statusLabel(AppLocalizations l10n, BookingStatus s) {
    switch (s) {
      case BookingStatus.pending:
        return l10n.statusPending;
      case BookingStatus.accepted:
        return l10n.statusAccepted;
      case BookingStatus.declined:
        return l10n.statusDeclined;
      case BookingStatus.completed:
        return l10n.statusCompleted;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(vendorInboxProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.vendorInbox)),
      body: AsyncBody<List<BookingRequest>>(
        value: async,
        onRetry: () => ref.read(vendorInboxProvider.notifier).refresh(),
        emptyWhen: (list) => list.isEmpty,
        empty: EmptyState(
          message: l10n.noInboxItems,
          icon: Icons.inbox_outlined,
        ),
        builder: (context, bookings) {
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: bookings.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final b = bookings[i];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        b.eventDate.toIso8601String().split('T').first,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(_statusLabel(l10n, b.status)),
                      if (b.message.isNotEmpty) Text(b.message),
                      if (b.guestCount != null)
                        Text('${l10n.guestCountLabel}: ${b.guestCount}'),
                      const SizedBox(height: 8),
                      if (b.status == BookingStatus.pending)
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => ref
                                    .read(vendorInboxProvider.notifier)
                                    .updateStatus(
                                      b.id,
                                      BookingStatus.declined,
                                    ),
                                child: Text(l10n.decline),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: FilledButton(
                                onPressed: () => ref
                                    .read(vendorInboxProvider.notifier)
                                    .updateStatus(
                                      b.id,
                                      BookingStatus.accepted,
                                    ),
                                child: Text(l10n.accept),
                              ),
                            ),
                          ],
                        ),
                      if (b.status == BookingStatus.accepted)
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.success,
                          ),
                          onPressed: () => ref
                              .read(vendorInboxProvider.notifier)
                              .updateStatus(b.id, BookingStatus.completed),
                          child: Text(l10n.complete),
                        ),
                    ],
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
