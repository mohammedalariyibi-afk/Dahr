import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/models/models.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/supabase/supabase_client.dart';

final myVendorProfileProvider =
    FutureProvider<VendorProfile?>((ref) async {
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
  });

  final int views;
  final int pending;
  final int accepted;
  final double unpaidCommissionLyd;
  final List<BookingRequest> unpaidBookings;
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
  return VendorDashboardStats(
    views: vendor.viewCount,
    pending: pending,
    accepted: accepted,
    unpaidCommissionLyd: unpaidTotal,
    unpaidBookings: unpaid,
  );
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
    if (vendor == null) return;
    final dateStr = date.toIso8601String().split('T').first;
    await DahrSupabase.client.from('availability').upsert({
      'vendor_id': vendor.id,
      'date': dateStr,
      'status': status.name,
    }, onConflict: 'vendor_id,date');
    ref.invalidateSelf();
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
  final path = '$userId/${const Uuid().v4()}.jpg';
  await DahrSupabase.client.storage.from('vendor-photos').uploadBinary(
        path,
        bytes,
        fileOptions: FileOptions(contentType: contentType, upsert: false),
      );
  final publicUrl =
      DahrSupabase.client.storage.from('vendor-photos').getPublicUrl(path);
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
  await DahrSupabase.client.from('vendor_photos').delete().eq('id', photo.id);
}
