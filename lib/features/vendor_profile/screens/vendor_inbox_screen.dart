import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/l10n/category_labels.dart';
import '../../../core/models/models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/widgets.dart';
import '../../booking/providers/booking_provider.dart';

class VendorInboxScreen extends ConsumerStatefulWidget {
  const VendorInboxScreen({super.key});

  @override
  ConsumerState<VendorInboxScreen> createState() => _VendorInboxScreenState();
}

class _VendorInboxScreenState extends ConsumerState<VendorInboxScreen> {
  String? _busyId;

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

  String _errorText(Object e, AppLocalizations l10n) {
    if (e is StateError) return localizeErrorKey(l10n, e.message);
    return localizeErrorKey(l10n, e.toString());
  }

  Future<bool> _confirm({
    required String title,
    required String body,
  }) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _accept(BookingRequest booking) async {
    final quoted = await showDialog<double>(
      context: context,
      builder: (context) => const _AcceptBookingDialog(),
    );
    if (quoted == null || !mounted) return;
    setState(() => _busyId = booking.id);
    try {
      await ref.read(vendorInboxProvider.notifier).acceptBooking(
            AcceptBookingPayload(
              bookingId: booking.id,
              quotedAmountLyd: quoted,
            ),
          );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorText(e, AppLocalizations.of(context)))),
      );
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _setStatus(String bookingId, BookingStatus status) async {
    final l10n = AppLocalizations.of(context);
    if (status == BookingStatus.declined) {
      final ok = await _confirm(
        title: l10n.confirmDeclineTitle,
        body: l10n.decline,
      );
      if (!ok) return;
    }
    if (status == BookingStatus.completed) {
      final ok = await _confirm(
        title: l10n.confirmCompleteTitle,
        body: l10n.confirmCompleteBody,
      );
      if (!ok) return;
    }
    setState(() => _busyId = bookingId);
    try {
      await ref
          .read(vendorInboxProvider.notifier)
          .updateStatus(bookingId, status);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorText(e, l10n))),
      );
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(vendorInboxProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.vendorInbox),
            Text(
              l10n.inboxSubtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.inkMuted,
                  ),
            ),
          ],
        ),
      ),
      body: AsyncBody<List<BookingRequest>>(
        value: async,
        onRetry: () => ref.read(vendorInboxProvider.notifier).refresh(),
        emptyWhen: (list) => list.isEmpty,
        empty: EmptyState(
          message: l10n.noInboxItems,
          icon: Icons.inbox_outlined,
        ),
        builder: (context, bookings) {
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(vendorInboxProvider.notifier).refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: bookings.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final b = bookings[i];
                final busy = _busyId == b.id;
                final name = (b.consumerName != null &&
                        b.consumerName!.trim().isNotEmpty)
                    ? b.consumerName!.trim()
                    : l10n.coupleName;
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
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            StatusPill(
                              label: _statusLabel(l10n, b.status),
                              color: switch (b.status) {
                                BookingStatus.pending => AppColors.warning,
                                BookingStatus.accepted => AppColors.glacier,
                                BookingStatus.declined => AppColors.error,
                                BookingStatus.completed => AppColors.inkMuted,
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(formatDay(b.eventDate)),
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
                        if (busy)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          )
                        else if (b.status == BookingStatus.pending)
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => _setStatus(
                                    b.id,
                                    BookingStatus.declined,
                                  ),
                                  child: Text(l10n.decline),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: FilledButton(
                                  onPressed: () => _accept(b),
                                  child: Text(l10n.accept),
                                ),
                              ),
                            ],
                          )
                        else if (b.status == BookingStatus.accepted)
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.success,
                            ),
                            onPressed: () => _setStatus(
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
            ),
          );
        },
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
