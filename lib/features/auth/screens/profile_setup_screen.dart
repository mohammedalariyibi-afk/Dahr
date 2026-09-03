import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/enums.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/security/safe_user_error.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _nameCtrl = TextEditingController();
  CityCode? _city;
  DateTime? _weddingDate;
  bool _loading = false;
  bool _hydrated = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hydrated) return;
    _hydrated = true;
    final profile = ref.read(authProvider).profile;
    if (profile?.fullName != null) {
      _nameCtrl.text = profile!.fullName!;
    }
    _city = profile?.city;
    _weddingDate = profile?.weddingDate;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    if (_nameCtrl.text.trim().isEmpty || _city == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.requiredField)),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final locale = ref.read(localeProvider).languageCode;
      final role = ref.read(authProvider).profile?.role ?? UserRole.consumer;
      await ref.read(authProvider.notifier).completeProfile(
            fullName: _nameCtrl.text,
            city: _city!,
            weddingDate: role == UserRole.consumer ? _weddingDate : null,
            locale: locale,
          );
      if (!mounted) return;
      final isVendor = ref.read(authProvider).isVendor;
      context.go(isVendor ? '/vendor-tools/onboarding' : '/discover');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(SafeUserError.of(l10n, e))),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _weddingDate ?? now.add(const Duration(days: 90)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 5)),
    );
    if (picked != null) setState(() => _weddingDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isConsumer =
        (ref.watch(authProvider).profile?.role ?? UserRole.consumer) ==
            UserRole.consumer;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileSetupTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: InputDecoration(labelText: l10n.fullNameLabel),
            ),
            const SizedBox(height: 20),
            Text(l10n.cityLabel, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: Text(l10n.cityTripoli),
                  selected: _city == CityCode.tripoli,
                  onSelected: (_) =>
                      setState(() => _city = CityCode.tripoli),
                  selectedColor: AppColors.burgundy,
                  labelStyle: TextStyle(
                    color: _city == CityCode.tripoli
                        ? AppColors.onBurgundy
                        : AppColors.ink,
                  ),
                ),
                ChoiceChip(
                  label: Text(l10n.cityBenghazi),
                  selected: _city == CityCode.benghazi,
                  onSelected: (_) =>
                      setState(() => _city = CityCode.benghazi),
                  selectedColor: AppColors.burgundy,
                  labelStyle: TextStyle(
                    color: _city == CityCode.benghazi
                        ? AppColors.onBurgundy
                        : AppColors.ink,
                  ),
                ),
              ],
            ),
            if (isConsumer) ...[
              const SizedBox(height: 20),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.weddingDateLabel),
                subtitle: Text(
                  _weddingDate == null
                      ? l10n.pickDate
                      : _weddingDate!.toIso8601String().split('T').first,
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickDate,
              ),
            ],
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _loading ? null : _save,
              child: Text(l10n.saveProfile),
            ),
          ],
        ),
      ),
    );
  }
}
