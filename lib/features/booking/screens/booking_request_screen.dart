import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/models.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../vendor_profile/providers/vendor_provider.dart';
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

  String _errorLabel(AppLocalizations l10n, Object error) {
    if (BookingDateConflict.matches(error)) {
      return l10n.bookingDateBookedError;
    }
    final key = error is StateError ? error.message : error.toString();
    switch (key) {
      case 'event_date_past':
      case 'vendor_required':
      case 'consumer_required':
        return l10n.requiredField;
      default:
        return error.toString();
    }
  }

  Future<void> _pickDate(Set<String> bookedKeys) async {
    final now = DateTime.now();
    final first = DateTime(now.year, now.month, now.day);
    var initial = _eventDate ?? now.add(const Duration(days: 30));
    if (initial.isBefore(first)) initial = first;
    while (AvailabilityCalendar.isBookedDate(initial, bookedKeys) &&
        initial.isBefore(first.add(const Duration(days: 365 * 3)))) {
      initial = initial.add(const Duration(days: 1));
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: first.add(const Duration(days: 365 * 3)),
      selectableDayPredicate: (day) =>
          !AvailabilityCalendar.isBookedDate(day, bookedKeys),
    );
    if (picked != null) setState(() => _eventDate = picked);
  }

  Future<void> _submit(Set<String> bookedKeys) async {
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
      await ref.read(consumerBookingsProvider.notifier).submit(
            payload,
            bookedDateKeys: bookedKeys,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.bookingSuccess)),
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
    final bookedAsync = ref.watch(vendorBookedDatesProvider(widget.vendorId));
    final bookedKeys = bookedAsync.valueOrNull ?? <String>{};

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
                    : AvailabilityCalendar.dateKey(_eventDate!),
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _pickDate(bookedKeys),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.bookedDatesTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            bookedAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text(e.toString()),
              data: (keys) {
                if (keys.isEmpty) {
                  return Text(l10n.noBookedDates);
                }
                final sorted = keys.toList()..sort();
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: sorted
                      .map(
                        (d) => Chip(
                          label: Text(d),
                          avatar: const Icon(Icons.event_busy, size: 16),
                        ),
                      )
                      .toList(),
                );
              },
            ),
            const SizedBox(height: 16),
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
              onPressed: _loading ? null : () => _submit(bookedKeys),
              child: Text(l10n.submitBooking),
            ),
          ],
        ),
      ),
    );
  }
}
