import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/models/models.dart';
import '../../../core/security/safe_user_error.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/widgets.dart';
import '../providers/booking_provider.dart';

class ConsumerBookingDetailScreen extends ConsumerStatefulWidget {
  const ConsumerBookingDetailScreen({super.key, required this.bookingId});

  final String bookingId;

  @override
  ConsumerState<ConsumerBookingDetailScreen> createState() =>
      _ConsumerBookingDetailScreenState();
}

class _ConsumerBookingDetailScreenState
    extends ConsumerState<ConsumerBookingDetailScreen> {
  late final TextEditingController _noteController;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

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

  Future<void> _submitTransfer() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _submitting = true);
    try {
      await ref.read(consumerBookingsProvider.notifier).reportTransfer(
            bookingId: widget.bookingId,
            referenceNote: _noteController.text,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.transferReported)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(SafeUserError.of(l10n, e))),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bookingAsync = ref.watch(bookingByIdProvider(widget.bookingId));
    final bankAsync = ref.watch(platformBankDetailsProvider);
    final notesAsync = ref.watch(
      transferNotesByBookingProvider(widget.bookingId),
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.bookingDetailTitle)),
      body: bookingAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorState(
          message: SafeUserError.of(l10n, e),
          onRetry: () => ref.invalidate(bookingByIdProvider(widget.bookingId)),
        ),
        data: (booking) {
          if (booking == null) {
            return EmptyState(
              title: l10n.bookingsEmptyTitle,
              message: l10n.bookingsEmptyBody,
              icon: Icons.event_busy_outlined,
              actionLabel: l10n.myBookings,
              onAction: () => context.go('/bookings'),
            );
          }
          final bank = bankAsync.valueOrNull ?? PlatformBankDetails.unset;
          final notes = notesAsync.valueOrNull;
          final latestNote =
              notes == null || notes.isEmpty ? null : notes.first;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        booking.vendor?.businessName ?? booking.vendorId,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(AvailabilityCalendar.dateKey(booking.eventDate)),
                      Text(_statusLabel(l10n, booking.status)),
                      if (booking.quotedAmountLyd != null)
                        Text(
                          '${l10n.quotedAmountDisplay}: '
                          '${AppConstants.formatPrice(booking.quotedAmountLyd)}',
                        ),
                    ],
                  ),
                ),
              ),
              if (booking.showsCouplePlatformFee &&
                  booking.commissionAmountLyd != null) ...[
                const SizedBox(height: 12),
                CouplePlatformFeeCard(
                  amountLyd: booking.commissionAmountLyd!,
                  status: booking.commissionStatus,
                  bankDetails: bank,
                  submittedNote: latestNote,
                  noteController: _noteController,
                  onSubmitTransfer: _submitTransfer,
                  submitting: _submitting,
                ),
              ],
              if (booking.canLeaveReview) ...[
                const SizedBox(height: 16),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.success,
                  ),
                  onPressed: () => context.push(
                    '/review/${booking.id}',
                    extra: {'vendorId': booking.vendorId},
                  ),
                  child: Text(l10n.leaveReview),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
