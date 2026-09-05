import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/category_labels.dart';
import '../../../core/models/models.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/widgets.dart';
import '../providers/review_provider.dart';

class LeaveReviewScreen extends ConsumerStatefulWidget {
  const LeaveReviewScreen({
    super.key,
    required this.bookingRequestId,
    this.vendorId = '',
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

  String _snack(Object e, AppLocalizations l10n) {
    if (e is StateError) return localizeErrorKey(l10n, e.message);
    return localizeErrorKey(l10n, e.toString());
  }

  Future<void> _submit(BookingRequest booking) async {
    final l10n = AppLocalizations.of(context);
    final auth = ref.read(authProvider);
    if (!auth.isLoggedIn) {
      final from = Uri.encodeComponent('/review/${widget.bookingRequestId}');
      context.push('/auth/login?from=$from');
      return;
    }
    setState(() => _loading = true);
    try {
      await submitReview(
        ref,
        ReviewPayload(
          vendorId: booking.vendorId,
          consumerId: auth.session!.user.id,
          bookingRequestId: widget.bookingRequestId,
          rating: _rating,
          comment: _commentCtrl.text.trim(),
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.reviewSuccess)),
      );
      context.go('/bookings');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_snack(e, l10n))),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bookingAsync =
        ref.watch(bookingForReviewProvider(widget.bookingRequestId));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.reviewTitle)),
      body: bookingAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(
            bookingForReviewProvider(widget.bookingRequestId),
          ),
        ),
        data: (booking) {
          if (booking == null) {
            return EmptyState(message: l10n.reviewMissingBooking);
          }
          if (booking.hasReview) {
            return EmptyState(message: l10n.alreadyReviewed);
          }
          if (booking.status != BookingStatus.completed) {
            return EmptyState(message: l10n.reviewOnlyCompleted);
          }
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (booking.vendor?.businessName != null) ...[
                  Text(
                    booking.vendor!.businessName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                ],
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
