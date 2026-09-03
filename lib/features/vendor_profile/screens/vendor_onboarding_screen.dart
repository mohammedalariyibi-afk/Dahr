import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/models.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/supabase/supabase_client.dart';
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

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final auth = ref.read(authProvider);
    if (!auth.isLoggedIn) {
      context.push('/auth/login');
      return;
    }
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.requiredField)),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      // Ensure role is vendor
      await ref.read(authProvider.notifier).setRole(UserRole.vendor);
      final services = _servicesCtrl.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      await DahrSupabase.client.from('vendor_profiles').upsert({
        'profile_id': auth.session!.user.id,
        'business_name': _nameCtrl.text.trim(),
        'category': _category.name,
        'city': _city.name,
        'description': _descCtrl.text.trim(),
        'price_min': double.tryParse(_minCtrl.text),
        'price_max': double.tryParse(_maxCtrl.text),
        'whatsapp_number': _waCtrl.text.trim().isEmpty
            ? null
            : _waCtrl.text.trim(),
        'services': services,
      }, onConflict: 'profile_id');
      ref.invalidate(myVendorProfileProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.onboardingPending)),
      );
      context.go('/vendor-tools/dashboard');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

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
              value: _category,
              decoration: InputDecoration(labelText: l10n.categoryLabel),
              items: VendorCategory.values
                  .map((c) => DropdownMenuItem(value: c, child: Text(c.name)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _category = v);
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<CityCode>(
              value: _city,
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
