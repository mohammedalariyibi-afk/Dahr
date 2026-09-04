import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/models.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/security/booking_write.dart';
import '../../../core/security/commission_write.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../../core/supabase/write_guard.dart';
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
        .select(BookingSelect.consumerList)
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

  Future<BookingRequest> submit(
    BookingRequestPayload payload, {
    Iterable<String>? bookedDateKeys,
  }) async {
    final error = payload.validate(bookedDateKeys: bookedDateKeys);
    if (error != null) throw StateError(error);
    final row = await DahrSupabase.client
        .from('booking_requests')
        .insert(BookingStatusWrite.consumerInsert(payload.toJson()))
        .select(BookingSelect.consumerInsert)
        .single();
    ref.invalidateSelf();
    return BookingRequest.fromJson(Map<String, dynamic>.from(row));
  }

  /// Couple records a bank-transfer note. Does not set commission_status.
  Future<CommissionTransferNote> reportTransfer({
    required String bookingId,
    required String referenceNote,
  }) async {
    final uid = ref.read(authProvider).session?.user.id;
    if (uid == null) throw StateError('write_rejected');
    final payload = CommissionTransferWrite.consumerInsert(
      bookingId: bookingId,
      consumerId: uid,
      referenceNote: referenceNote,
    );
    if (CommissionTransferWrite.insertContainsMoneyStatus(payload)) {
      throw StateError('write_rejected');
    }
    final row = await DahrSupabase.client
        .from(CommissionTransferWrite.notesTable)
        .insert(payload)
        .select(CommissionTransferNote.select)
        .single();
    ref.invalidate(transferNotesByBookingProvider(bookingId));
    return CommissionTransferNote.fromJson(Map<String, dynamic>.from(row));
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
        .select(BookingSelect.vendor)
        .eq('vendor_id', vendorId)
        .order('created_at', ascending: false);
    return (rows as List)
        .map((e) => BookingRequest.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  void _invalidateRelated() {
    ref.invalidateSelf();
    ref.invalidate(vendorDashboardStatsProvider);
  }

  /// Decline or complete only. Accepting requires a quote — use [acceptBooking].
  Future<void> updateStatus(String bookingId, BookingStatus status) async {
    final patch = BookingStatusWrite.vendorDirectPatch(status);
    final rows = await DahrSupabase.client
        .from('booking_requests')
        .update(patch)
        .eq('id', bookingId)
        .select('id');
    requireMutatedRows(rows);
    _invalidateRelated();
  }

  Future<void> acceptBooking(AcceptBookingPayload payload) async {
    final error = payload.validate();
    if (error != null) throw StateError(error);
    await DahrSupabase.client.rpc(
      BookingStatusWrite.acceptRpcName,
      params: payload.toRpcParams(),
    );
    // The accept RPC marks the date booked in the same transaction, so both
    // calendars only need re-reading — the vendor's own view and the booked
    // dates a couple sees.
    ref.invalidate(vendorAvailabilityProvider);
    ref.invalidate(vendorBookedDatesProvider);
    _invalidateRelated();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }
}

final bookingByIdProvider =
    FutureProvider.family<BookingRequest?, String>((ref, id) async {
  final uid = ref.watch(authProvider).session?.user.id;
  if (uid == null) return null;
  final row = await DahrSupabase.client
      .from('booking_requests')
      .select(BookingSelect.consumerById)
      .eq('id', id)
      .eq('consumer_id', uid)
      .maybeSingle();
  if (row == null) return null;
  return BookingRequest.fromJson(Map<String, dynamic>.from(row));
});

/// Null filter = all statuses. Default pending so new requests are front.
final vendorInboxFilterProvider =
    StateProvider<BookingStatus?>((ref) => BookingStatus.pending);

final platformBankDetailsProvider =
    FutureProvider<PlatformBankDetails>((ref) async {
  final uid = ref.watch(authProvider).session?.user.id;
  if (uid == null) return PlatformBankDetails.unset;
  try {
    final row = await DahrSupabase.client
        .from(PlatformBankDetails.table)
        .select(PlatformBankDetails.select)
        .eq('id', PlatformBankDetails.singletonId)
        .maybeSingle();
    return PlatformBankDetails.fromJson(
      row == null ? null : Map<String, dynamic>.from(row),
    );
  } catch (_) {
    return PlatformBankDetails.unset;
  }
});

final transferNotesByBookingProvider = FutureProvider.family<
    List<CommissionTransferNote>, String>((ref, bookingId) async {
  final uid = ref.watch(authProvider).session?.user.id;
  if (uid == null) return const [];
  try {
    final rows = await DahrSupabase.client
        .from(CommissionTransferWrite.notesTable)
        .select(CommissionTransferNote.select)
        .eq('booking_id', bookingId)
        .eq('consumer_id', uid)
        .order('created_at', ascending: false);
    return (rows as List)
        .map(
          (e) => CommissionTransferNote.fromJson(
            Map<String, dynamic>.from(e as Map),
          ),
        )
        .toList();
  } catch (_) {
    return const [];
  }
});
