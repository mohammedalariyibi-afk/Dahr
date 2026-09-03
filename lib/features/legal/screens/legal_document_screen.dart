import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../legal_documents.dart';

class LegalDocumentScreen extends StatelessWidget {
  const LegalDocumentScreen({super.key, required this.kind});

  final LegalDocumentKind kind;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final doc = LegalDocuments.of(kind, locale);
    final title = kind == LegalDocumentKind.privacy
        ? l10n.privacyPolicy
        : l10n.termsOfUse;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            l10n.legalStartingNotice,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.inkMuted,
                  fontStyle: FontStyle.italic,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            doc.updated,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.inkFaint,
                ),
          ),
          const SizedBox(height: 16),
          Text(
            doc.intro,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.ink,
                  height: 1.45,
                ),
          ),
          const SizedBox(height: 20),
          for (final section in doc.sections) ...[
            Text(
              section.heading,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.burgundy,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              section.body,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.ink,
                    height: 1.45,
                  ),
            ),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }
}
