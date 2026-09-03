import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/models.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/supabase/supabase_client.dart';

final consumerBookingsProvider =
    AsyncNotifierProvider<ConsumerBookingsNotifier, List<BookingRequest>>(
  ConsumerBookingsNotifier.new,
);

class ConsumerBookingsNotifier extends AsyncNotifier<List<BookingRequest>> {
  @override
  Future<List<BookingRequest>> build() => _fetch();

  Future<List<BookingRequest>> _fetch() async {
    final auth = ref.watch(authProvider);
    if (!auth.isLoggedIn) return [];
    final uid = auth.session!.user.id;
    final rows = await DahrSupabase.client
        .from('booking_requests')
        .select('*, vendor_profiles(*, vendor_photos(*))')
        .eq('consumer_id', uid)
        .order('created_at', ascending: false);
    return (rows as List)
        .map((e) => BookingRequest.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<BookingRequest> submit(BookingRequestPayload payload) async {
    final error = payload.validate();
    if (error != null) throw StateError(error);
    final row = await DahrSupabase.client
        .from('booking_requests')
        .insert(payload.toJson())
        .select()
        .single();
    ref.invalidateSelf();
    return BookingRequest.fromJson(Map<String, dynamic>.from(row));
  }
}

final vendorInboxProvider =
    AsyncNotifierProvider<VendorInboxNotifier, List<BookingRequest>>(
  VendorInboxNotifier.new,
);

class VendorInboxNotifier extends AsyncNotifier<List<BookingRequest>> {
  @override
  Future<List<BookingRequest>> build() => _fetch();

  Future<List<BookingRequest>> _fetch() async {
    final auth = ref.watch(authProvider);
    if (!auth.isLoggedIn) return [];
    final uid = auth.session!.user.id;
    final vendor = await DahrSupabase.client
        .from('vendor_profiles')
        .select('id')
        .eq('profile_id', uid)
        .maybeSingle();
    if (vendor == null) return [];
    final vendorId = vendor['id'] as String;
    final rows = await DahrSupabase.client
        .from('booking_requests')
        .select()
        .eq('vendor_id', vendorId)
        .order('created_at', ascending: false);
    return (rows as List)
        .map((e) => BookingRequest.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> updateStatus(String bookingId, BookingStatus status) async {
    await DahrSupabase.client
        .from('booking_requests')
        .update({'status': status.name}).eq('id', bookingId);
    ref.invalidateSelf();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }
}
