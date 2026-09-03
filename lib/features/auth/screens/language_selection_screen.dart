import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';

class LanguageSelectionScreen extends ConsumerWidget {
  const LanguageSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = ref.watch(localeProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Text(
                l10n.appName,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: AppColors.burgundy,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.chooseLanguage,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.inkMuted,
                    ),
              ),
              const SizedBox(height: 40),
              _LangTile(
                label: l10n.languageArabic,
                selected: locale.languageCode == AppConstants.defaultLocale,
                onTap: () => ref
                    .read(localeProvider.notifier)
                    .setLocale(AppConstants.defaultLocale),
              ),
              const SizedBox(height: 12),
              _LangTile(
                label: l10n.languageEnglish,
                selected: locale.languageCode == AppConstants.englishLocale,
                onTap: () => ref
                    .read(localeProvider.notifier)
                    .setLocale(AppConstants.englishLocale),
              ),
              const Spacer(),
              FilledButton(
                onPressed: () => context.go('/auth/login'),
                child: Text(l10n.continueLabel),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go('/discover'),
                child: Text(l10n.skipAsGuest),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LangTile extends StatelessWidget {
  const _LangTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.burgundy : AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.burgundy : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: selected ? AppColors.onBurgundy : AppColors.ink,
                  ),
                ),
              ),
              if (selected)
                const Icon(Icons.check_circle, color: AppColors.onPrimary),
            ],
          ),
        ),
      ),
    );
  }
}
