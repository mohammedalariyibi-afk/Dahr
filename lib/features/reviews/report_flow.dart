import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/review.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/security/safe_user_error.dart';
import '../../core/supabase/supabase_client.dart';
import '../../core/supabase/write_guard.dart';
import '../../l10n/generated/app_localizations.dart';

Future<String?> showReportReasonDialog(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final reasonCtrl = TextEditingController();
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.report),
      content: TextField(
        controller: reasonCtrl,
        decoration: InputDecoration(labelText: l10n.reportReason),
        maxLines: 3,
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(l10n.reportSubmit),
        ),
      ],
    ),
  );
  final reason = reasonCtrl.text.trim();
  reasonCtrl.dispose();
  if (ok != true || reason.isEmpty) return null;
  return reason;
}

/// Vendor or review report. Guests are sent to login first.
Future<void> submitContentReport({
  required BuildContext context,
  required WidgetRef ref,
  required String targetType,
  required String targetId,
  required String loginReturnPath,
}) async {
  final l10n = AppLocalizations.of(context);
  final auth = ref.read(authProvider);
  if (!auth.isLoggedIn) {
    final from = Uri.encodeComponent(loginReturnPath);
    context.push('/auth/login?from=$from');
    return;
  }

  final reason = await showReportReasonDialog(context);
  if (reason == null || !context.mounted) return;

  try {
    final payload = ReportWrite.insert(
      reportedBy: auth.session!.user.id,
      targetType: targetType,
      targetId: targetId,
      reason: reason,
    );
    final rows = await DahrSupabase.client
        .from('reports')
        .insert(payload)
        .select('id');
    requireMutatedRows(rows);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.reportSuccess)),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(SafeUserError.of(l10n, e))),
      );
    }
  }
}
