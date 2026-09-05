import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/widgets.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _route());
  }

  void _route() {
    final status = ref.read(authProvider).status;
    if (status == AuthFlowStatus.unknown) {
      Future<void>.delayed(const Duration(milliseconds: 400), _route);
      return;
    }
    if (!mounted) return;
    switch (status) {
      case AuthFlowStatus.unauthenticated:
        context.go('/auth/language');
      case AuthFlowStatus.needsRole:
        context.go('/auth/role');
      case AuthFlowStatus.needsProfile:
        context.go('/auth/profile-setup');
      case AuthFlowStatus.authenticated:
        context.go('/home');
      case AuthFlowStatus.unknown:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    ref.listen(authProvider, (_, __) => _route());

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 0.85,
            colors: [Color(0xFF152033), AppColors.background],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const DahrLogo(height: 120),
            const SizedBox(height: 24),
            Text(
              l10n.appName,
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.splashTagline,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.inkMuted,
                  ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
