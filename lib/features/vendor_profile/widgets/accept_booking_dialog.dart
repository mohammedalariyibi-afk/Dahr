import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/models/models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';

/// Vendor accept-with-quote dialog. LYD quote required; 10% unpaid preview.
class AcceptBookingDialog extends StatefulWidget {
  const AcceptBookingDialog({
    super.key,
    this.eventDate,
  });

  final DateTime? eventDate;

  @override
  State<AcceptBookingDialog> createState() => _AcceptBookingDialogState();
}

class _AcceptBookingDialogState extends State<AcceptBookingDialog> {
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
    final commissionPreview = valid
        ? AppConstants.formatPrice(CommissionMath.amountDue(parsed))
        : '—';
    final quotePreview =
        valid ? AppConstants.formatPrice(parsed) : '—';
    final dateLabel = widget.eventDate == null
        ? null
        : '${l10n.eventDateLabel}: ${AvailabilityCalendar.dateKey(widget.eventDate!)}';

    return AlertDialog(
      title: Text(l10n.acceptBookingTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.commissionNoteVendor),
            if (dateLabel != null) ...[
              const SizedBox(height: 8),
              Text(
                dateLabel,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: l10n.quotedAmountLabel,
                hintText: l10n.quotedAmountHint,
                suffixText: l10n.currencyLyd,
                errorText: _error,
              ),
              onChanged: _onChanged,
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 12),
            Text(
              '${l10n.quotedAmountDisplay}: $quotePreview',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              '${l10n.commissionDueLabel}: $commissionPreview',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.warning,
              ),
            ),
          ],
        ),
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
