import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/models.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../booking/providers/booking_provider.dart';
import '../../discovery/providers/vendors_provider.dart';

final bookingForReviewProvider =
    FutureProvider.family<BookingRequest?, String>((ref, bookingId) async {
  final auth = ref.watch(authProvider);
  if (!auth.isLoggedIn) return null;
  final uid = auth.session!.user.id;
  final row = await DahrSupabase.client
      .from('booking_requests')
      .select('*, reviews(id), vendor_profiles(*, vendor_photos(*))')
      .eq('id', bookingId)
      .eq('consumer_id', uid)
      .maybeSingle();
  if (row == null) return null;
  return BookingRequest.fromJson(Map<String, dynamic>.from(row));
});

Future<void> submitReview(WidgetRef ref, ReviewPayload payload) async {
  final error = payload.validate();
  if (error != null) throw StateError(error);
  try {
    await DahrSupabase.client.from('reviews').insert(payload.toJson());
  } catch (e) {
    final text = e.toString();
    if (text.contains('duplicate') ||
        text.contains('unique') ||
        text.contains('reviews_booking_request_id')) {
      throw StateError('already_reviewed');
    }
    if (text.contains('completed')) {
      throw StateError('review_only_completed');
    }
    rethrow;
  }
  ref.invalidate(consumerBookingsProvider);
  ref.invalidate(bookingForReviewProvider(payload.bookingRequestId));
  ref.invalidate(vendorReviewsProvider(payload.vendorId));
}
