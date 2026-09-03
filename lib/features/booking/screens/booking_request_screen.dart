import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/models.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../providers/booking_provider.dart';

class BookingRequestScreen extends ConsumerStatefulWidget {
  const BookingRequestScreen({super.key, required this.vendorId});

  final String vendorId;

  @override
  ConsumerState<BookingRequestScreen> createState() =>
      _BookingRequestScreenState();
}

class _BookingRequestScreenState extends ConsumerState<BookingRequestScreen> {
  DateTime? _eventDate;
  final _guestsCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _guestsCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 30)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 3)),
    );
    if (picked != null) setState(() => _eventDate = picked);
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final auth = ref.read(authProvider);
    if (!auth.isLoggedIn) {
      final from = Uri.encodeComponent('/booking/${widget.vendorId}');
      context.push('/auth/login?from=$from');
      return;
    }
    if (_eventDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.requiredField)),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final payload = BookingRequestPayload(
        vendorId: widget.vendorId,
        consumerId: auth.session!.user.id,
        eventDate: _eventDate!,
        guestCount: int.tryParse(_guestsCtrl.text),
        message: _messageCtrl.text.trim(),
      );
      await ref.read(consumerBookingsProvider.notifier).submit(payload);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.bookingSuccess)),
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
      appBar: AppBar(title: Text(l10n.bookingTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.eventDateLabel),
              subtitle: Text(
                _eventDate == null
                    ? l10n.pickDate
                    : _eventDate!.toIso8601String().split('T').first,
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickDate,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _guestsCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: l10n.guestCountLabel),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _messageCtrl,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: l10n.messageLabel,
                hintText: l10n.messageHint,
              ),
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: _loading ? null : _submit,
              child: Text(l10n.submitBooking),
            ),
          ],
        ),
      ),
    );
  }
}
