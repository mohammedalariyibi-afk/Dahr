import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../account_deletion.dart';

/// Confirm dialog for self-serve account deletion.
///
/// Returns [DeleteAccountConfirmation] so the caller can decide whether to
/// invoke the RPC. Cancel or a dismissed dialog never confirms.
Future<DeleteAccountConfirmation> showDeleteAccountDialog({
  required BuildContext context,
  required bool isSignedIn,
}) async {
  final l10n = AppLocalizations.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.deleteAccountTitle),
      content: Text(l10n.deleteAccountBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: isSignedIn ? () => Navigator.pop(ctx, true) : null,
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(ctx).colorScheme.error,
          ),
          child: Text(l10n.deleteAccountConfirm),
        ),
      ],
    ),
  );
  return DeleteAccountConfirmation(
    isSignedIn: isSignedIn,
    confirmed: confirmed == true,
  );
}
