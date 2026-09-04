import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/security/safe_user_error.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/widgets.dart';
import '../providers/vendor_provider.dart';

class VendorPhotosScreen extends ConsumerWidget {
  const VendorPhotosScreen({super.key});

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 75,
    );
    if (file == null) return;
    try {
      final bytes = await file.readAsBytes();
      await ref.read(vendorPhotosProvider.notifier).addBytes(bytes);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.photoUploadFailed)),
      );
    }
  }

  /// Delete and reorder update state optimistically, so a rejected write has
  /// to be reported and the list resynced from the server.
  Future<void> _runWrite(
    BuildContext context,
    WidgetRef ref,
    Future<void> Function() write,
  ) async {
    final l10n = AppLocalizations.of(context);
    try {
      await write();
    } catch (e) {
      await ref.read(vendorPhotosProvider.notifier).refresh();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(SafeUserError.of(l10n, e))),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final vendorAsync = ref.watch(myVendorProfileProvider);
    final photosAsync = ref.watch(vendorPhotosProvider);

    return vendorAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text(l10n.vendorPhotosTitle)),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: Text(l10n.vendorPhotosTitle)),
        body: ErrorState(
          message: SafeUserError.of(l10n, e),
          onRetry: () => ref.invalidate(myVendorProfileProvider),
        ),
      ),
      data: (vendor) {
        if (vendor == null) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.vendorPhotosTitle)),
            body: EmptyState(
              message: l10n.setupVendorListing,
              actionLabel: l10n.continueLabel,
              onAction: () => context.push('/vendor-tools/onboarding'),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(title: Text(l10n.vendorPhotosTitle)),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _add(context, ref),
            icon: const Icon(Icons.add_a_photo_outlined),
            label: Text(l10n.addPhoto),
          ),
          body: AsyncBody(
            value: photosAsync,
            onRetry: () => ref.read(vendorPhotosProvider.notifier).refresh(),
            emptyWhen: (list) => list.isEmpty,
            empty: EmptyState(
              message: l10n.photosEmpty,
              icon: Icons.photo_library_outlined,
              actionLabel: l10n.addPhoto,
              onAction: () => _add(context, ref),
            ),
            builder: (context, photos) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(l10n.reorderPhotosHint),
                  ),
                  Expanded(
                    child: ReorderableListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                      itemCount: photos.length,
                      // The new order is applied locally first, so a failed
                      // write would otherwise leave the cover photo looking
                      // changed while `sort_order` still says otherwise.
                      onReorderItem: (oldIndex, newIndex) => _runWrite(
                        context,
                        ref,
                        () => ref
                            .read(vendorPhotosProvider.notifier)
                            .reorder(oldIndex, newIndex),
                      ),
                      itemBuilder: (context, i) {
                        final photo = photos[i];
                        return Card(
                          key: ValueKey(photo.id),
                          child: ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CachedNetworkImage(
                                imageUrl: photo.storageUrl,
                                width: 64,
                                height: 64,
                                fit: BoxFit.cover,
                              ),
                            ),
                            title: Text(
                              i == 0 ? l10n.coverPhoto : '${i + 1}',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: l10n.deletePhoto,
                                  onPressed: () => _runWrite(
                                    context,
                                    ref,
                                    () => ref
                                        .read(vendorPhotosProvider.notifier)
                                        .remove(photo),
                                  ),
                                  icon: const Icon(Icons.delete_outline),
                                  color: AppColors.error,
                                ),
                                ReorderableDragStartListener(
                                  index: i,
                                  child: const Icon(Icons.drag_handle),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
