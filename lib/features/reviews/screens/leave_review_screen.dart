import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';

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

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final auth = ref.read(authProvider);
    if (!auth.isLoggedIn) {
      context.push('/auth/login');
      return;
    }
    setState(() => _loading = true);
    try {
      await DahrSupabase.client.from('reviews').insert({
        'vendor_id': widget.vendorId,
        'consumer_id': auth.session!.user.id,
        'booking_request_id': widget.bookingRequestId,
        'rating': _rating,
        'comment': _commentCtrl.text.trim(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.reviewSuccess)),
      );
      context.go('/bookings');
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.reviewTitle)),
      body: Padding(
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
              onPressed: _loading ? null : _submit,
              child: Text(l10n.submitReview),
            ),
          ],
        ),
      ),
    );
  }
}
