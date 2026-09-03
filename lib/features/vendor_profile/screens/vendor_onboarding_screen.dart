import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/category_labels.dart';
import '../../../core/models/models.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/security/safe_user_error.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../../core/supabase/write_guard.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../providers/vendor_provider.dart';

class VendorOnboardingScreen extends ConsumerStatefulWidget {
  const VendorOnboardingScreen({super.key});

  @override
  ConsumerState<VendorOnboardingScreen> createState() =>
      _VendorOnboardingScreenState();
}

class _VendorOnboardingScreenState
    extends ConsumerState<VendorOnboardingScreen> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _waCtrl = TextEditingController();
  final _minCtrl = TextEditingController();
  final _maxCtrl = TextEditingController();
  final _servicesCtrl = TextEditingController();
  VendorCategory _category = VendorCategory.other;
  CityCode _city = CityCode.tripoli;
  bool _loading = false;
  bool _hydrated = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _waCtrl.dispose();
    _minCtrl.dispose();
    _maxCtrl.dispose();
    _servicesCtrl.dispose();
    super.dispose();
  }

  String _errorLabel(AppLocalizations l10n, String key) {
    switch (key) {
      case 'business_name_required':
        return l10n.businessNameRequired;
      case 'description_required':
        return l10n.descriptionRequired;
      case 'whatsapp_required':
        return l10n.whatsappRequired;
      case 'whatsapp_invalid':
        return l10n.invalidWhatsapp;
      case 'price_range_required':
        return l10n.priceRangeRequired;
      case 'price_range_invalid':
        return l10n.priceRangeInvalid;
      default:
        return l10n.requiredField;
    }
  }

  void _hydrateIfNeeded(VendorProfile? existing) {
    if (_hydrated || existing == null) return;
    _hydrated = true;
    _nameCtrl.text = existing.businessName;
    _descCtrl.text = existing.description;
    _waCtrl.text = existing.whatsappNumber ?? '';
    _minCtrl.text = existing.priceMin?.toString() ?? '';
    _maxCtrl.text = existing.priceMax?.toString() ?? '';
    _servicesCtrl.text = existing.services.join(', ');
    _category = existing.category;
    _city = existing.city;
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final auth = ref.read(authProvider);
    if (!auth.isLoggedIn) {
      context.push('/auth/login');
      return;
    }
    final payload = VendorOnboardingPayload.fromInput(
      profileId: auth.session!.user.id,
      businessName: _nameCtrl.text,
      category: _category,
      city: _city,
      description: _descCtrl.text,
      whatsappNumber: _waCtrl.text,
      priceMinRaw: _minCtrl.text,
      priceMaxRaw: _maxCtrl.text,
      servicesRaw: _servicesCtrl.text,
    );
    final error = payload.validate();
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorLabel(l10n, error))),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(authProvider.notifier).setRole(UserRole.vendor);
      final rows = await DahrSupabase.client
          .from('vendor_profiles')
          .upsert(
            payload.toJson(),
            onConflict: 'profile_id',
          )
          .select('id');
      requireMutatedRows(rows);
      ref.invalidate(myVendorProfileProvider);
      ref.invalidate(vendorDashboardStatsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.onboardingPending)),
      );
      context.go('/vendor-tools/dashboard');
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final existing = ref.watch(myVendorProfileProvider).valueOrNull;
    _hydrateIfNeeded(existing);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.vendorOnboardingTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: InputDecoration(labelText: l10n.businessNameLabel),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<VendorCategory>(
              key: ValueKey(_category),
              initialValue: _category,
              decoration: InputDecoration(labelText: l10n.categoryLabel),
              items: VendorCategory.values
                  .map(
                    (c) => DropdownMenuItem(
                      value: c,
                      child: Text(localizedCategory(l10n, c)),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _category = v);
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<CityCode>(
              key: ValueKey(_city),
              initialValue: _city,
              decoration: InputDecoration(labelText: l10n.cityLabel),
              items: [
                DropdownMenuItem(
                  value: CityCode.tripoli,
                  child: Text(l10n.cityTripoli),
                ),
                DropdownMenuItem(
                  value: CityCode.benghazi,
                  child: Text(l10n.cityBenghazi),
                ),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _city = v);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descCtrl,
              maxLines: 4,
              decoration: InputDecoration(labelText: l10n.descriptionLabel),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _waCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(labelText: l10n.whatsappNumberLabel),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _minCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: l10n.priceMinLabel),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _maxCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: l10n.priceMaxLabel),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _servicesCtrl,
              decoration: InputDecoration(labelText: l10n.servicesLabel),
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: _loading ? null : _submit,
              child: Text(l10n.submitOnboarding),
            ),
          ],
        ),
      ),
    );
  }
}
