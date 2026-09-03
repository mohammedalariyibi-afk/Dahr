import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/enums.dart';
import '../../../core/models/profile_role_write.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';

class RoleSelectScreen extends ConsumerStatefulWidget {
  const RoleSelectScreen({super.key});

  @override
  ConsumerState<RoleSelectScreen> createState() => _RoleSelectScreenState();
}

class _RoleSelectScreenState extends ConsumerState<RoleSelectScreen> {
  UserRole? _selected;
  bool _loading = false;

  String _errorLabel(AppLocalizations l10n, Object error) {
    if (error is StateError && error.message == 'role_not_assignable') {
      return l10n.roleNotAssignable;
    }
    return l10n.errorGeneric;
  }

  Future<void> _continue() async {
    if (_selected == null) return;
    setState(() => _loading = true);
    try {
      await ref.read(authProvider.notifier).setRole(_selected!);
      if (!mounted) return;
      context.go('/auth/profile-setup');
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorLabel(l10n, e))),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  _RoleCopy _copyFor(UserRole role, AppLocalizations l10n) {
    switch (role) {
      case UserRole.consumer:
        return _RoleCopy(
          title: l10n.roleConsumer,
          subtitle: l10n.roleConsumerDesc,
          icon: Icons.search_rounded,
        );
      case UserRole.vendor:
        return _RoleCopy(
          title: l10n.roleVendor,
          subtitle: l10n.roleVendorDesc,
          icon: Icons.storefront_rounded,
        );
      case UserRole.admin:
        throw StateError('role_not_assignable');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.roleTitle)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final role in RoleSelectOptions.choices) ...[
              Builder(
                builder: (context) {
                  final copy = _copyFor(role, l10n);
                  return _RoleCard(
                    title: copy.title,
                    subtitle: copy.subtitle,
                    icon: copy.icon,
                    selected: _selected == role,
                    onTap: () => setState(() => _selected = role),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
            const Spacer(),
            FilledButton(
              onPressed: _selected == null || _loading ? null : _continue,
              child: Text(l10n.continueLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleCopy {
  const _RoleCopy({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
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
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.burgundy : AppColors.border,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 36,
                color: selected ? AppColors.gold : AppColors.burgundy,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: selected ? AppColors.onBurgundy : AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: selected
                            ? AppColors.onBurgundy.withValues(alpha: 0.85)
                            : AppColors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
