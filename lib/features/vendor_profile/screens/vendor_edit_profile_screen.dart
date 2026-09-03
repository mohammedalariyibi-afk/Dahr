import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/models/models.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/widgets.dart';
import '../providers/vendor_provider.dart';

class VendorEditProfileScreen extends ConsumerStatefulWidget {
  const VendorEditProfileScreen({super.key});

  @override
  ConsumerState<VendorEditProfileScreen> createState() =>
      _VendorEditProfileScreenState();
}

class _VendorEditProfileScreenState
    extends ConsumerState<VendorEditProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _waCtrl = TextEditingController();
  final _minCtrl = TextEditingController();
  final _maxCtrl = TextEditingController();
  final _servicesCtrl = TextEditingController();
  VendorCategory _category = VendorCategory.other;
  CityCode _city = CityCode.tripoli;
  bool _loaded = false;
  bool _loading = false;
  bool _uploadingPhoto = false;
  String? _vendorId;
  List<VendorPhoto> _photos = [];

  void _hydrate(VendorProfile v) {
    if (_loaded) return;
    _vendorId = v.id;
    _nameCtrl.text = v.businessName;
    _descCtrl.text = v.description;
    _waCtrl.text = v.whatsappNumber ?? '';
    _minCtrl.text = v.priceMin?.toString() ?? '';
    _maxCtrl.text = v.priceMax?.toString() ?? '';
    _servicesCtrl.text = v.services.join(', ');
    _category = v.category;
    _city = v.city;
    _photos = List.of(v.photos);
    _loaded = true;
  }

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

  Future<void> _save() async {
    if (_vendorId == null) return;
    setState(() => _loading = true);
    try {
      final services = _servicesCtrl.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      await DahrSupabase.client.from('vendor_profiles').update({
        'business_name': _nameCtrl.text.trim(),
        'category': _category.name,
        'city': _city.name,
        'description': _descCtrl.text.trim(),
        'price_min': double.tryParse(_minCtrl.text),
        'price_max': double.tryParse(_maxCtrl.text),
        'whatsapp_number':
            _waCtrl.text.trim().isEmpty ? null : _waCtrl.text.trim(),
        'services': services,
      }).eq('id', _vendorId!);
      ref.invalidate(myVendorProfileProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).saveChanges)),
      );
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

  Future<void> _addPhoto() async {
    final l10n = AppLocalizations.of(context);
    final auth = ref.read(authProvider);
    if (_vendorId == null || !auth.isLoggedIn) return;

    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 75,
    );
    if (file == null) return;

    setState(() => _uploadingPhoto = true);
    try {
      final bytes = await file.readAsBytes();
      final photo = await uploadVendorPhoto(
        vendorId: _vendorId!,
        userId: auth.session!.user.id,
        bytes: bytes,
        sortOrder: _photos.length,
      );
      setState(() => _photos = [..._photos, photo]);
      ref.invalidate(myVendorProfileProvider);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.photoUploadFailed)),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _removePhoto(VendorPhoto photo) async {
    try {
      await deleteVendorPhoto(photo);
      setState(() => _photos = _photos.where((p) => p.id != photo.id).toList());
      ref.invalidate(myVendorProfileProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final vendorAsync = ref.watch(myVendorProfileProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.editVendorProfile)),
      body: vendorAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorState(message: e.toString()),
        data: (vendor) {
          if (vendor == null) {
            return EmptyState(
              message: l10n.vendorOnboardingTitle,
              actionLabel: l10n.continueLabel,
              onAction: () => context.push('/vendor-tools/onboarding'),
            );
          }
          _hydrate(vendor);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.photosLabel,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 96,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      ..._photos.map(
                        (p) => Padding(
                          padding: const EdgeInsetsDirectional.only(end: 8),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: CachedNetworkImage(
                                  imageUrl: p.storageUrl,
                                  width: 96,
                                  height: 96,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 2,
                                right: 2,
                                child: IconButton(
                                  iconSize: 18,
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.black54,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.all(4),
                                    minimumSize: const Size(28, 28),
                                  ),
                                  onPressed: () => _removePhoto(p),
                                  icon: const Icon(Icons.close),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      OutlinedButton(
                        onPressed: _uploadingPhoto ? null : _addPhoto,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(96, 96),
                          foregroundColor: AppColors.burgundy,
                        ),
                        child: _uploadingPhoto
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.add_a_photo_outlined),
                                  const SizedBox(height: 4),
                                  Text(l10n.addPhoto, textAlign: TextAlign.center),
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nameCtrl,
                  decoration:
                      InputDecoration(labelText: l10n.businessNameLabel),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<VendorCategory>(
                  value: _category,
                  decoration: InputDecoration(labelText: l10n.categoryLabel),
                  items: VendorCategory.values
                      .map(
                        (c) =>
                            DropdownMenuItem(value: c, child: Text(c.name)),
                      )
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
                  decoration:
                      InputDecoration(labelText: l10n.descriptionLabel),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _waCtrl,
                  decoration:
                      InputDecoration(labelText: l10n.whatsappNumberLabel),
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
                  onPressed: _loading ? null : _save,
                  child: Text(l10n.saveChanges),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
