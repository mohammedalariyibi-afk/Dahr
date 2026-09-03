import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_constants.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/generated/app_localizations.dart';

/// Couple-facing 10% Dahr fee. Bank transfer only — no Pay now / cards.
class CouplePlatformFeeCard extends StatelessWidget {
  const CouplePlatformFeeCard({
    super.key,
    required this.amountLyd,
    required this.status,
    required this.bankDetails,
    this.submittedNote,
    this.noteController,
    this.onSubmitTransfer,
    this.submitting = false,
    this.compact = false,
  });

  final double amountLyd;
  final CommissionStatus? status;
  final PlatformBankDetails bankDetails;
  final CommissionTransferNote? submittedNote;
  final TextEditingController? noteController;
  final VoidCallback? onSubmitTransfer;
  final bool submitting;
  final bool compact;

  bool get _unpaid => status == CommissionStatus.unpaid;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final amount = AppConstants.formatPrice(amountLyd);
    final theme = Theme.of(context);

    return Card(
      color: AppColors.creamDark,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.platformFeeTitle,
              style: theme.textTheme.titleSmall?.copyWith(
                color: AppColors.burgundy,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              amount,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.platformFeeBody(amount),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.inkMuted,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.platformFeeVendorRest,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.inkMuted,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${l10n.commissionStatusLabel}: ${_statusLabel(l10n)}',
              style: theme.textTheme.labelLarge?.copyWith(
                color: _unpaid ? AppColors.warning : AppColors.success,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (!compact) ...[
              const SizedBox(height: 16),
              _BankDetailsBlock(bankDetails: bankDetails),
              if (_unpaid) ...[
                const SizedBox(height: 16),
                if (submittedNote != null)
                  Text(
                    l10n.transferReported,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.success,
                    ),
                  )
                else
                  _TransferNoteForm(
                    controller: noteController,
                    onSubmit: onSubmitTransfer,
                    submitting: submitting,
                  ),
                if (submittedNote != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    submittedNote!.referenceNote,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.inkMuted,
                    ),
                  ),
                ],
              ],
            ],
          ],
        ),
      ),
    );
  }

  String _statusLabel(AppLocalizations l10n) {
    switch (status) {
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
}

class _BankDetailsBlock extends StatelessWidget {
  const _BankDetailsBlock({required this.bankDetails});

  final PlatformBankDetails bankDetails;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    if (!bankDetails.isConfigured) {
      return Text(
        l10n.bankDetailsPending,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: AppColors.inkMuted,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.bankDetailsTitle,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        _CopyRow(label: l10n.bankNameLabel, value: bankDetails.bankName),
        _CopyRow(
          label: l10n.accountHolderLabel,
          value: bankDetails.accountHolder,
        ),
        _CopyRow(
          label: l10n.accountNumberLabel,
          value: bankDetails.accountNumber,
        ),
        if (bankDetails.optionalNote.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              bankDetails.optionalNote,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.inkMuted,
              ),
            ),
          ),
      ],
    );
  }
}

class _CopyRow extends StatelessWidget {
  const _CopyRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              '$label: $value',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          IconButton(
            tooltip: label,
            onPressed: () => Clipboard.setData(ClipboardData(text: value)),
            icon: const Icon(Icons.copy_outlined, size: 18),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _TransferNoteForm extends StatelessWidget {
  const _TransferNoteForm({
    required this.controller,
    required this.onSubmit,
    required this.submitting,
  });

  final TextEditingController? controller;
  final VoidCallback? onSubmit;
  final bool submitting;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: controller,
          enabled: !submitting,
          maxLength: 500,
          minLines: 2,
          maxLines: 4,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            labelText: l10n.transferNoteLabel,
            hintText: l10n.transferNoteHint,
          ),
        ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: submitting ? null : onSubmit,
          child: Text(l10n.iTransferred),
        ),
      ],
    );
  }
}
