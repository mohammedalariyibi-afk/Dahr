import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/models/enums.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/widgets.dart';

class ProfileTabScreen extends ConsumerWidget {
  const ProfileTabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final auth = ref.watch(authProvider);
    final locale = ref.watch(localeProvider);
    final city = auth.profile?.city == CityCode.benghazi
        ? l10n.cityBenghazi
        : l10n.cityTripoli;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            const Center(child: DahrLogo(height: 48)),
            const SizedBox(height: 20),
            if (auth.isGuest)
              GlassPanel(
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
              )
            else ...[
              const CircleAvatar(
                radius: 44,
                backgroundColor: AppColors.burgundySoft,
                child: Icon(Icons.person, color: AppColors.glacier, size: 44),
              ),
              const SizedBox(height: 12),
              Text(
                auth.profile?.fullName ?? '—',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: AppColors.glacier,
                  ),
                  const SizedBox(width: 4),
                  Text(city, style: const TextStyle(color: AppColors.inkMuted)),
                ],
              ),
              const SizedBox(height: 20),
            ],
            GlassPanel(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.bookmark_outline),
                    title: Text(l10n.favoritesTitle),
                    onTap: () => context.push('/favorites'),
                  ),
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
                ],
              ),
            ),
            if (auth.isVendor) ...[
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                child: Text(
                  l10n.vendorTools,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.glacier,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              GlassPanel(
                child: Column(
                  children: [
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
                      leading: const Icon(Icons.calendar_month_outlined),
                      title: Text(l10n.manageAvailability),
                      onTap: () =>
                          context.push('/vendor-tools/availability'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.storefront_outlined),
                      title: Text(l10n.vendorOnboardingTitle),
                      onTap: () => context.push('/vendor-tools/onboarding'),
                    ),
                  ],
                ),
              ),
            ] else if (auth.isLoggedIn) ...[
              const SizedBox(height: 16),
              GlassPanel(
                child: ListTile(
                  leading: const Icon(Icons.storefront_outlined),
                  title: Text(l10n.becomeVendor),
                  onTap: () => context.push('/vendor-tools/onboarding'),
                ),
              ),
            ],
            if (auth.isLoggedIn) ...[
              const SizedBox(height: 16),
              GlassPanel(
                child: ListTile(
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
              ),
            ],
          ],
        ),
      ),
    );
  }
}
