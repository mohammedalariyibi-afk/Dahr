import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/models/models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/widgets.dart';
import '../providers/booking_provider.dart';

class ConsumerBookingsScreen extends ConsumerWidget {
  const ConsumerBookingsScreen({super.key});

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

  Color _statusColor(BookingStatus s) {
    switch (s) {
      case BookingStatus.pending:
        return AppColors.warning;
      case BookingStatus.accepted:
        return AppColors.success;
      case BookingStatus.declined:
        return AppColors.error;
      case BookingStatus.completed:
        return AppColors.burgundy;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(consumerBookingsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.myBookings)),
      body: AsyncBody<List<BookingRequest>>(
        value: async,
        onRetry: () => ref.read(consumerBookingsProvider.notifier).refresh(),
        emptyWhen: (list) => list.isEmpty,
        empty: EmptyState(
          title: l10n.bookingsEmptyTitle,
          message: l10n.bookingsEmptyBody,
          icon: Icons.event_busy_outlined,
          actionLabel: l10n.browseDiscover,
          onAction: () => context.go('/discover'),
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
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              b.vendor?.businessName ?? b.vendorId,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.circle,
                            size: 10,
                            color: _statusColor(b.status),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(AvailabilityCalendar.dateKey(b.eventDate)),
                      Text(_statusLabel(l10n, b.status)),
                      if (b.quotedAmountLyd != null)
                        Text(
                          '${l10n.quotedAmountDisplay}: '
                          '${AppConstants.formatPrice(b.quotedAmountLyd)}',
                        ),
                      if (b.canLeaveReview)
                        Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: TextButton(
                            onPressed: () => context.push(
                              '/review/${b.id}',
                              extra: {'vendorId': b.vendorId},
                            ),
                            child: Text(l10n.leaveReview),
                          ),
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
