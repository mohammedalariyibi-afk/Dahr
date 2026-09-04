import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/models/enums.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/security/safe_user_error.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../auth/providers/auth_form_validators.dart';
import '../widgets/profile_details_fields.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key, this.isEditing = false});

  final bool isEditing;

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
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
    if (profile?.phone != null && profile!.phone!.isNotEmpty) {
      _phoneCtrl.text = AppConstants.normalizeLibyaPhone(profile.phone!);
    }
    _city = profile?.city;
    _weddingDate = profile?.weddingDate;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  bool get _isConsumer =>
      (ref.read(authProvider).profile?.role ?? UserRole.consumer) ==
      UserRole.consumer;

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    if (_nameCtrl.text.trim().isEmpty || _city == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.requiredField)),
      );
      return;
    }
    final phoneErr = _isConsumer
        ? AuthFormValidators.validatePhone(_phoneCtrl.text)
        : (_phoneCtrl.text.trim().isEmpty
            ? null
            : AuthFormValidators.validatePhone(_phoneCtrl.text));
    if (phoneErr != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            phoneErr == 'invalid_phone' ? l10n.invalidPhone : l10n.requiredField,
          ),
        ),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final locale = ref.read(localeProvider).languageCode;
      await ref.read(authProvider.notifier).completeProfile(
            fullName: _nameCtrl.text,
            city: _city!,
            weddingDate: _isConsumer ? _weddingDate : null,
            locale: locale,
            phone: _phoneCtrl.text,
            requirePhone: _isConsumer,
          );
      if (!mounted) return;
      if (widget.isEditing) {
        context.pop();
        return;
      }
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
    final first = widget.isEditing
        ? DateTime(now.year - 1, now.month, now.day)
        : now;
    final picked = await showDatePicker(
      context: context,
      initialDate: _weddingDate ?? now.add(const Duration(days: 90)),
      firstDate: first,
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
      appBar: AppBar(
        title: Text(
          widget.isEditing ? l10n.editProfile : l10n.profileSetupTitle,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ProfileDetailsFields(
              nameController: _nameCtrl,
              phoneController: _phoneCtrl,
              city: _city,
              onCityChanged: (city) => setState(() => _city = city),
              showCoupleFields: isConsumer,
              weddingDate: _weddingDate,
              onPickWeddingDate: _pickDate,
            ),
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
