import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/models/models.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../../core/supabase/write_guard.dart';

final myVendorProfileProvider = FutureProvider<VendorProfile?>((ref) async {
  final auth = ref.watch(authProvider);
  if (!auth.isLoggedIn) return null;
  final uid = auth.session!.user.id;
  final row = await DahrSupabase.client
      .from('vendor_profiles')
      .select('*, vendor_photos(*)')
      .eq('profile_id', uid)
      .maybeSingle();
  if (row == null) return null;
  return VendorProfile.fromJson(Map<String, dynamic>.from(row));
});

class VendorDashboardStats {
  const VendorDashboardStats({
    required this.views,
    required this.pending,
    required this.accepted,
    required this.unpaidCommissionLyd,
    required this.unpaidBookings,
    required this.photoCount,
    required this.nextBookedDates,
  });

  final int views;
  final int pending;
  final int accepted;
  final double unpaidCommissionLyd;
  final List<BookingRequest> unpaidBookings;
  final int photoCount;
  final List<DateTime> nextBookedDates;
}

final vendorDashboardStatsProvider =
    FutureProvider<VendorDashboardStats>((ref) async {
  final vendor = await ref.watch(myVendorProfileProvider.future);
  if (vendor == null) {
    return const VendorDashboardStats(
      views: 0,
      pending: 0,
      accepted: 0,
      unpaidCommissionLyd: 0,
      unpaidBookings: [],
      photoCount: 0,
      nextBookedDates: [],
    );
  }
  final rows = await DahrSupabase.client
      .from('booking_requests')
      .select()
      .eq('vendor_id', vendor.id)
      .order('created_at', ascending: false);
  final bookings = (rows as List)
      .map((e) => BookingRequest.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList();
  var pending = 0;
  var accepted = 0;
  final unpaid = <BookingRequest>[];
  var unpaidTotal = 0.0;
  for (final b in bookings) {
    if (b.status == BookingStatus.pending) pending++;
    if (b.status == BookingStatus.accepted) accepted++;
    if (b.isCommissionUnpaid) {
      unpaid.add(b);
      unpaidTotal += b.commissionAmountLyd ?? 0;
    }
  }
  final availabilityRows = await DahrSupabase.client
      .from('availability')
      .select()
      .eq('vendor_id', vendor.id)
      .eq('status', AvailabilityStatus.booked.name)
      .order('date');
  final slots = (availabilityRows as List)
      .map((e) =>
          AvailabilitySlot.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList();
  return VendorDashboardStats(
    views: vendor.viewCount,
    pending: pending,
    accepted: accepted,
    unpaidCommissionLyd: unpaidTotal,
    unpaidBookings: unpaid,
    photoCount: vendor.photos.length,
    nextBookedDates: AvailabilityCalendar.upcomingBookedDates(slots).take(5).toList(),
  );
});

/// Booked dates for an approved vendor — used on the couple booking screen.
final vendorBookedDatesProvider =
    FutureProvider.family<Set<String>, String>((ref, vendorId) async {
  final rows = await DahrSupabase.client
      .from('availability')
      .select()
      .eq('vendor_id', vendorId)
      .eq('status', AvailabilityStatus.booked.name);
  final slots = (rows as List)
      .map((e) =>
          AvailabilitySlot.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList();
  return AvailabilityCalendar.bookedDateKeys(slots);
});

final vendorAvailabilityProvider =
    AsyncNotifierProvider<VendorAvailabilityNotifier, List<AvailabilitySlot>>(
  VendorAvailabilityNotifier.new,
);

class VendorAvailabilityNotifier
    extends AsyncNotifier<List<AvailabilitySlot>> {
  @override
  Future<List<AvailabilitySlot>> build() => _fetch();

  Future<List<AvailabilitySlot>> _fetch() async {
    final vendor = await ref.watch(myVendorProfileProvider.future);
    if (vendor == null) return [];
    final rows = await DahrSupabase.client
        .from('availability')
        .select()
        .eq('vendor_id', vendor.id)
        .order('date');
    return (rows as List)
        .map((e) =>
            AvailabilitySlot.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> upsertDate(DateTime date, AvailabilityStatus status) async {
    final vendor = await ref.read(myVendorProfileProvider.future);
    if (vendor == null) throw StateError('not_vendor');
    final rows = await DahrSupabase.client
        .from('availability')
        .upsert(
          AvailabilityCalendar.upsertJson(
            vendorId: vendor.id,
            date: date,
            status: status,
          ),
          onConflict: 'vendor_id,date',
        )
        .select('id');
    requireMutatedRows(rows);
    ref.invalidate(vendorDashboardStatsProvider);
    ref.invalidateSelf();
  }

  Future<void> toggleDate(DateTime date) async {
    final slots = state.valueOrNull ?? await _fetch();
    final next = AvailabilityCalendar.nextStatusForDate(
      date: date,
      slots: slots,
    );
    await upsertDate(date, next);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }
}

/// Uploads a vendor photo to Storage (`vendor-photos/{userId}/{uuid}.jpg`)
/// and inserts a `vendor_photos` row.
Future<VendorPhoto> uploadVendorPhoto({
  required String vendorId,
  required String userId,
  required Uint8List bytes,
  required int sortOrder,
  String contentType = 'image/jpeg',
}) async {
  final uid = DahrSupabase.currentUserId;
  if (uid == null || uid != userId) {
    throw StateError('write_rejected');
  }
  final path = VendorPhotoStorage.objectPath(userId, const Uuid().v4());
  await DahrSupabase.client.storage.from(VendorPhotoStorage.bucket).uploadBinary(
        path,
        bytes,
        fileOptions: FileOptions(contentType: contentType, upsert: false),
      );
  final publicUrl = DahrSupabase.client.storage
      .from(VendorPhotoStorage.bucket)
      .getPublicUrl(path);
  final row = await DahrSupabase.client
      .from('vendor_photos')
      .insert({
        'vendor_id': vendorId,
        'storage_url': publicUrl,
        'sort_order': sortOrder,
      })
      .select()
      .single();
  return VendorPhoto.fromJson(Map<String, dynamic>.from(row));
}

Future<void> deleteVendorPhoto(VendorPhoto photo) async {
  final uid = DahrSupabase.currentUserId;
  final path = VendorPhotoStorage.objectPathFromPublicUrl(photo.storageUrl);
  final rows = await DahrSupabase.client
      .from('vendor_photos')
      .delete()
      .eq('id', photo.id)
      .select('id');
  requireMutatedRows(rows);
  if (uid != null &&
      path != null &&
      VendorPhotoStorage.isOwnedObjectPath(uid, path)) {
    await DahrSupabase.client.storage
        .from(VendorPhotoStorage.bucket)
        .remove([path]);
  }
}

Future<void> persistPhotoOrder(List<VendorPhoto> photos) async {
  for (final photo in photos) {
    final rows = await DahrSupabase.client
        .from('vendor_photos')
        .update({'sort_order': photo.sortOrder})
        .eq('id', photo.id)
        .select('id');
    requireMutatedRows(rows);
  }
}

final vendorPhotosProvider =
    AsyncNotifierProvider<VendorPhotosNotifier, List<VendorPhoto>>(
  VendorPhotosNotifier.new,
);

class VendorPhotosNotifier extends AsyncNotifier<List<VendorPhoto>> {
  @override
  Future<List<VendorPhoto>> build() async {
    final vendor = await ref.watch(myVendorProfileProvider.future);
    if (vendor == null) return [];
    return List<VendorPhoto>.of(vendor.photos)
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  Future<void> addBytes(Uint8List bytes, {String contentType = 'image/jpeg'}) async {
    final auth = ref.read(authProvider);
    final vendor = await ref.read(myVendorProfileProvider.future);
    if (vendor == null || !auth.isLoggedIn) {
      throw StateError('not_vendor');
    }
    final current = state.valueOrNull ?? [];
    final photo = await uploadVendorPhoto(
      vendorId: vendor.id,
      userId: auth.session!.user.id,
      bytes: bytes,
      sortOrder: current.length,
      contentType: contentType,
    );
    state = AsyncData([...current, photo]);
    ref.invalidate(myVendorProfileProvider);
    ref.invalidate(vendorDashboardStatsProvider);
  }

  Future<void> remove(VendorPhoto photo) async {
    await deleteVendorPhoto(photo);
    final remaining = (state.valueOrNull ?? [])
        .where((p) => p.id != photo.id)
        .toList();
    final reindexed = [
      for (var i = 0; i < remaining.length; i++)
        remaining[i].copyWith(sortOrder: i),
    ];
    await persistPhotoOrder(reindexed);
    state = AsyncData(reindexed);
    ref.invalidate(myVendorProfileProvider);
    ref.invalidate(vendorDashboardStatsProvider);
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    final current = state.valueOrNull ?? [];
    final next = VendorPhotoStorage.applyReorder(current, oldIndex, newIndex);
    state = AsyncData(next);
    await persistPhotoOrder(next);
    ref.invalidate(myVendorProfileProvider);
  }

  Future<void> refresh() async {
    ref.invalidate(myVendorProfileProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final vendor = await ref.read(myVendorProfileProvider.future);
      if (vendor == null) return <VendorPhoto>[];
      return List<VendorPhoto>.of(vendor.photos)
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    });
  }
}
