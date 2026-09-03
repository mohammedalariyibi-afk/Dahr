import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/models/enums.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'delete_account_dialog.dart';

class ProfileTabScreen extends ConsumerWidget {
  const ProfileTabScreen({super.key});

  Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final confirmation = await showDeleteAccountDialog(
      context: context,
      isSignedIn: ref.read(authProvider).isLoggedIn,
    );
    if (!confirmation.shouldCallRpc) return;
    try {
      await ref.read(authProvider.notifier).deleteAccount();
      if (context.mounted) context.go('/auth/language');
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.deleteAccountFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final auth = ref.watch(authProvider);
    final locale = ref.watch(localeProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (auth.isGuest)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(l10n.loginRequiredBody),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => context.push('/auth/login'),
                      child: Text(l10n.loginAction),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppColors.burgundy,
                child: Icon(Icons.person, color: AppColors.onBurgundy),
              ),
              title: Text(auth.profile?.fullName ?? '—'),
              subtitle: Text(
                auth.profile?.city == CityCode.benghazi
                    ? l10n.cityBenghazi
                    : l10n.cityTripoli,
              ),
            ),
            const Divider(),
          ],
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(l10n.language),
            subtitle: Text(
              locale.languageCode == AppConstants.defaultLocale
                  ? l10n.languageArabic
                  : l10n.languageEnglish,
            ),
            onTap: () => ref.read(localeProvider.notifier).toggle(),
          ),
          if (auth.isVendor) ...[
            const Divider(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                l10n.vendorTools,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.burgundy,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard_outlined),
              title: Text(l10n.vendorDashboard),
              onTap: () => context.push('/vendor-tools/dashboard'),
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text(l10n.editListing),
              onTap: () => context.push('/vendor-tools/edit'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l10n.managePhotos),
              onTap: () => context.push('/vendor-tools/photos'),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month_outlined),
              title: Text(l10n.manageAvailability),
              onTap: () => context.push('/vendor-tools/availability'),
            ),
            ListTile(
              leading: const Icon(Icons.storefront_outlined),
              title: Text(l10n.vendorOnboardingTitle),
              onTap: () => context.push('/vendor-tools/onboarding'),
            ),
          ] else if (auth.isLoggedIn) ...[
            ListTile(
              leading: const Icon(Icons.storefront_outlined),
              title: Text(l10n.becomeVendor),
              onTap: () => context.push('/vendor-tools/onboarding'),
            ),
          ],
          const Divider(),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: Text(l10n.privacyPolicy),
            onTap: () => context.push(AppConstants.privacyPath),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: Text(l10n.termsOfUse),
            onTap: () => context.push(AppConstants.termsPath),
          ),
          if (auth.isLoggedIn) ...[
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: AppColors.error),
              title: Text(
                l10n.signOut,
                style: const TextStyle(color: AppColors.error),
              ),
              onTap: () async {
                await ref.read(authProvider.notifier).signOut();
                if (context.mounted) context.go('/auth/language');
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.delete_forever_outlined,
                color: AppColors.error,
              ),
              title: Text(
                l10n.deleteAccount,
                style: const TextStyle(color: AppColors.error),
              ),
              onTap: () => _deleteAccount(context, ref),
            ),
          ],
        ],
      ),
    );
  }
}
