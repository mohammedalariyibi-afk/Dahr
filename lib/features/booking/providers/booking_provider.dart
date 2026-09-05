import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/models.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../vendor_profile/providers/vendor_provider.dart';

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
        .select('*, vendor_profiles(*, vendor_photos(*)), reviews(id)')
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

    final vendorRow = await DahrSupabase.client
        .from('vendor_profiles')
        .select('id, profile_id')
        .eq('id', payload.vendorId)
        .maybeSingle();
    if (vendorRow == null) throw StateError('vendor_required');
    if (vendorRow['profile_id'] == payload.consumerId) {
      throw StateError('cannot_book_own_listing');
    }

    final booked =
        await ref.read(vendorBookedDatesProvider(payload.vendorId).future);
    if (booked.contains(AvailabilitySlot.dateOnly(payload.eventDate))) {
      throw StateError('date_unavailable');
    }

    try {
      final row = await DahrSupabase.client
          .from('booking_requests')
          .insert(payload.toJson())
          .select()
          .single();
      ref.invalidateSelf();
      return BookingRequest.fromJson(Map<String, dynamic>.from(row));
    } catch (e) {
      final text = e.toString();
      if (text.contains('date_unavailable')) {
        throw StateError('date_unavailable');
      }
      rethrow;
    }
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
    var bookings = (rows as List)
        .map((e) => BookingRequest.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    bookings = await _attachConsumerNames(bookings);
    return bookings;
  }

  Future<List<BookingRequest>> _attachConsumerNames(
    List<BookingRequest> bookings,
  ) async {
    final ids = bookings.map((b) => b.consumerId).toSet().toList();
    if (ids.isEmpty) return bookings;
    try {
      final rows = await DahrSupabase.client
          .from('profile_public')
          .select('id, full_name')
          .inFilter('id', ids);
      final names = <String, String>{};
      for (final row in rows as List) {
        final map = Map<String, dynamic>.from(row as Map);
        final id = map['id'] as String?;
        final name = map['full_name'] as String?;
        if (id != null && name != null && name.trim().isNotEmpty) {
          names[id] = name.trim();
        }
      }
      return bookings
          .map((b) => b.copyWith(consumerName: names[b.consumerId]))
          .toList();
    } catch (_) {
      return bookings;
    }
  }

  void _invalidateRelated() {
    ref.invalidateSelf();
    ref.invalidate(vendorDashboardStatsProvider);
    ref.invalidate(vendorAvailabilityProvider);
    ref.invalidate(vendorBookedDatesProvider);
  }

  /// Decline or complete only. Accepting requires a quote — use [acceptBooking].
  Future<void> updateStatus(String bookingId, BookingStatus status) async {
    AcceptBookingPayload.assertNotBareAccept(status);
    await DahrSupabase.client
        .from('booking_requests')
        .update({'status': status.name}).eq('id', bookingId);
    _invalidateRelated();
  }

  Future<void> acceptBooking(AcceptBookingPayload payload) async {
    final error = payload.validate();
    if (error != null) throw StateError(error);
    await DahrSupabase.client.rpc(
      'accept_booking_request',
      params: payload.toRpcParams(),
    );

    final current = state.valueOrNull ?? [];
    BookingRequest? accepted;
    for (final b in current) {
      if (b.id == payload.bookingId) {
        accepted = b;
        break;
      }
    }
    if (accepted != null) {
      await _markEventDateBooked(accepted);
    }

    _invalidateRelated();
  }

  Future<void> _markEventDateBooked(BookingRequest booking) async {
    final vendor = await ref.read(myVendorProfileProvider.future);
    if (vendor == null) return;
    final dateStr = booking.eventDate.toIso8601String().split('T').first;
    try {
      await DahrSupabase.client.from('availability').upsert({
        'vendor_id': vendor.id,
        'date': dateStr,
        'status': AvailabilityStatus.booked.name,
      }, onConflict: 'vendor_id,date');
    } catch (_) {
      // RPC migration may already have marked the date.
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }
}
