import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
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

  String _commissionLabel(AppLocalizations l10n, CommissionStatus? s) {
    switch (s) {
      case CommissionStatus.unpaid:
        return l10n.commissionUnpaid;
      case CommissionStatus.paid:
        return l10n.commissionPaid;
      case CommissionStatus.waived:
        return l10n.commissionWaived;
      case null:
        return '';
    }
  }

  Future<void> _accept(
    BuildContext context,
    WidgetRef ref,
    BookingRequest booking,
  ) async {
    final quoted = await showDialog<double>(
      context: context,
      builder: (context) => const _AcceptBookingDialog(),
    );
    if (quoted == null || !context.mounted) return;
    try {
      await ref.read(vendorInboxProvider.notifier).acceptBooking(
            AcceptBookingPayload(
              bookingId: booking.id,
              quotedAmountLyd: quoted,
            ),
            booking: booking,
          );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _setStatus(
    BuildContext context,
    WidgetRef ref,
    String bookingId,
    BookingStatus status,
  ) async {
    try {
      await ref
          .read(vendorInboxProvider.notifier)
          .updateStatus(bookingId, status);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(vendorInboxProvider);
    final filter = ref.watch(vendorInboxFilterProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.vendorInbox)),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                _FilterChip(
                  label: l10n.inboxFilterAll,
                  selected: filter == null,
                  onTap: () => ref
                      .read(vendorInboxFilterProvider.notifier)
                      .state = null,
                ),
                _FilterChip(
                  label: l10n.statusPending,
                  selected: filter == BookingStatus.pending,
                  onTap: () => ref
                      .read(vendorInboxFilterProvider.notifier)
                      .state = BookingStatus.pending,
                ),
                _FilterChip(
                  label: l10n.statusAccepted,
                  selected: filter == BookingStatus.accepted,
                  onTap: () => ref
                      .read(vendorInboxFilterProvider.notifier)
                      .state = BookingStatus.accepted,
                ),
                _FilterChip(
                  label: l10n.statusDeclined,
                  selected: filter == BookingStatus.declined,
                  onTap: () => ref
                      .read(vendorInboxFilterProvider.notifier)
                      .state = BookingStatus.declined,
                ),
                _FilterChip(
                  label: l10n.statusCompleted,
                  selected: filter == BookingStatus.completed,
                  onTap: () => ref
                      .read(vendorInboxFilterProvider.notifier)
                      .state = BookingStatus.completed,
                ),
              ],
            ),
          ),
          Expanded(
            child: AsyncBody<List<BookingRequest>>(
              value: async,
              onRetry: () => ref.read(vendorInboxProvider.notifier).refresh(),
              emptyWhen: (list) =>
                  list.where((b) => filter == null || b.status == filter).isEmpty,
              empty: EmptyState(
                message: l10n.noInboxItems,
                icon: Icons.inbox_outlined,
              ),
              builder: (context, bookings) {
                final visible = filter == null
                    ? bookings
                    : bookings.where((b) => b.status == filter).toList();
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: visible.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final b = visible[i];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              AvailabilityCalendar.dateKey(b.eventDate),
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            Text(_statusLabel(l10n, b.status)),
                            if (b.message.isNotEmpty) Text(b.message),
                            if (b.guestCount != null)
                              Text('${l10n.guestCountLabel}: ${b.guestCount}'),
                            if (b.quotedAmountLyd != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                '${l10n.quotedAmountDisplay}: '
                                '${AppConstants.formatPrice(b.quotedAmountLyd)}',
                              ),
                              Text(
                                '${l10n.commissionDueLabel}: '
                                '${AppConstants.formatPrice(b.commissionAmountLyd)}',
                              ),
                              if (b.commissionStatus != null)
                                Text(
                                  '${l10n.commissionStatusLabel}: '
                                  '${_commissionLabel(l10n, b.commissionStatus)}',
                                ),
                            ],
                            const SizedBox(height: 8),
                            if (b.status == BookingStatus.pending)
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () => _setStatus(
                                        context,
                                        ref,
                                        b.id,
                                        BookingStatus.declined,
                                      ),
                                      child: Text(l10n.decline),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: FilledButton(
                                      onPressed: () =>
                                          _accept(context, ref, b),
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
                                onPressed: () => _setStatus(
                                  context,
                                  ref,
                                  b.id,
                                  BookingStatus.completed,
                                ),
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
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.burgundy,
        labelStyle: TextStyle(
          color: selected ? AppColors.onBurgundy : AppColors.ink,
          fontWeight: FontWeight.w600,
        ),
        checkmarkColor: AppColors.onBurgundy,
      ),
    );
  }
}

class _AcceptBookingDialog extends StatefulWidget {
  const _AcceptBookingDialog();

  @override
  State<_AcceptBookingDialog> createState() => _AcceptBookingDialogState();
}

class _AcceptBookingDialogState extends State<_AcceptBookingDialog> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String _) {
    setState(() => _error = null);
  }

  void _submit() {
    final l10n = AppLocalizations.of(context);
    final payload = AcceptBookingPayload.fromInput(
      bookingId: 'pending-accept',
      quotedAmountRaw: _controller.text,
    );
    final error = payload.validate();
    if (error != null) {
      setState(() => _error = l10n.quotedAmountRequired);
      return;
    }
    Navigator.of(context).pop(payload.quotedAmountLyd);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final parsed = CommissionMath.parseQuotedAmount(_controller.text);
    final valid = parsed != null && parsed > 0 && parsed.isFinite;
    final preview = valid
        ? '${CommissionMath.formatPreview(parsed)} ${l10n.currencyLyd}'
        : '—';

    return AlertDialog(
      title: Text(l10n.acceptBookingTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.commissionNoteVendor),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: l10n.quotedAmountLabel,
              hintText: l10n.quotedAmountHint,
              errorText: _error,
            ),
            onChanged: _onChanged,
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 12),
          Text(
            '${l10n.commissionDueLabel}: $preview',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: valid ? _submit : null,
          child: Text(l10n.confirmAccept),
        ),
      ],
    );
  }
}
