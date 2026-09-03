import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/models.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/security/safe_user_error.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/widgets.dart';
import '../../booking/providers/booking_provider.dart';

class LeaveReviewScreen extends ConsumerStatefulWidget {
  const LeaveReviewScreen({
    super.key,
    required this.bookingRequestId,
    required this.vendorId,
  });

  final String bookingRequestId;
  final String vendorId;

  @override
  ConsumerState<LeaveReviewScreen> createState() => _LeaveReviewScreenState();
}

class _LeaveReviewScreenState extends ConsumerState<LeaveReviewScreen> {
  int _rating = 5;
  final _commentCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  String _errorLabel(AppLocalizations l10n, Object error) {
    return SafeUserError.of(l10n, error);
  }

  Future<void> _submit(BookingRequest booking) async {
    final l10n = AppLocalizations.of(context);
    final auth = ref.read(authProvider);
    if (!auth.isLoggedIn) {
      context.push('/auth/login');
      return;
    }
    final payload = ReviewPayload(
      vendorId: widget.vendorId.isNotEmpty ? widget.vendorId : booking.vendorId,
      consumerId: auth.session!.user.id,
      bookingRequestId: widget.bookingRequestId,
      rating: _rating,
      comment: _commentCtrl.text.trim(),
    );
    final error = payload.validate(
      bookingStatus: booking.status,
      alreadyReviewed: booking.review != null,
    );
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorLabel(l10n, StateError(error)))),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await DahrSupabase.client
          .from('reviews')
          .insert(payload.toJson())
          .select('id')
          .single();
      ref.invalidate(consumerBookingsProvider);
      ref.invalidate(bookingByIdProvider(widget.bookingRequestId));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.reviewSuccess)),
      );
      context.go('/bookings');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorLabel(l10n, e))),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bookingAsync = ref.watch(bookingByIdProvider(widget.bookingRequestId));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.reviewTitle)),
      body: bookingAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorState(
          message: SafeUserError.of(l10n, e),
          onRetry: () =>
              ref.invalidate(bookingByIdProvider(widget.bookingRequestId)),
        ),
        data: (booking) {
          if (booking == null) {
            return ErrorState(message: l10n.errorGeneric);
          }
          if (booking.status != BookingStatus.completed) {
            return EmptyState(
              message: l10n.reviewNotCompleted,
              icon: Icons.lock_outline,
              actionLabel: l10n.myBookings,
              onAction: () => context.go('/bookings'),
            );
          }
          if (booking.review != null) {
            return EmptyState(
              message: l10n.alreadyReviewed,
              icon: Icons.reviews_outlined,
              actionLabel: l10n.myBookings,
              onAction: () => context.go('/bookings'),
            );
          }
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.ratingLabel),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    final star = i + 1;
                    return IconButton(
                      onPressed: () => setState(() => _rating = star),
                      icon: Icon(
                        star <= _rating
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: AppColors.star,
                        size: 36,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _commentCtrl,
                  maxLines: 4,
                  decoration: InputDecoration(labelText: l10n.commentLabel),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: _loading ? null : () => _submit(booking),
                  child: Text(l10n.submitReview),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
