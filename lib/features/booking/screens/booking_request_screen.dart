import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/category_labels.dart';
import '../../../core/models/models.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/widgets.dart';
import '../../discovery/providers/vendors_provider.dart';
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

  String _snack(Object e, AppLocalizations l10n) {
    if (e is StateError) return localizeErrorKey(l10n, e.message);
    return localizeErrorKey(l10n, e.toString());
  }

  Future<void> _pickDate(Set<DateTime> booked) async {
    final now = DateTime.now();
    final first = DateTime(now.year, now.month, now.day);
    var initial = _eventDate ?? now.add(const Duration(days: 30));
    if (initial.isBefore(first)) initial = first;
    while (booked.contains(AvailabilitySlot.dateOnly(initial)) &&
        initial.isBefore(now.add(const Duration(days: 365 * 3)))) {
      initial = initial.add(const Duration(days: 1));
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: now.add(const Duration(days: 365 * 3)),
      selectableDayPredicate: (day) {
        return !booked.contains(AvailabilitySlot.dateOnly(day));
      },
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
    final vendorAsync = ref.watch(vendorByIdProvider(widget.vendorId));
    final bookedAsync = ref.watch(vendorBookedDatesProvider(widget.vendorId));
    final booked = bookedAsync.valueOrNull ?? {};

    return Scaffold(
      appBar: AppBar(title: Text(l10n.bookingTitle)),
      body: vendorAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorState(
          message: e.toString(),
          onRetry: () =>
              ref.invalidate(vendorByIdProvider(widget.vendorId)),
        ),
        data: (vendor) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: GlassPanel(
              padding: const EdgeInsets.all(20),
              radius: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.bookingTitle,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppColors.glacier,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.bookingSubtitle,
                    style: const TextStyle(color: AppColors.inkMuted),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    l10n.bookingVendorLabel,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    vendor.businessName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 20),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.calendar_today,
                      color: AppColors.glacier,
                    ),
                    title: Text(l10n.eventDateLabel),
                    subtitle: Text(
                      _eventDate == null
                          ? l10n.pickDate
                          : formatDay(_eventDate!),
                    ),
                    onTap: () => _pickDate(booked),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _guestsCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: l10n.guestCountLabel,
                      prefixIcon: const Icon(Icons.group_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _messageCtrl,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: l10n.messageLabel,
                      hintText: l10n.messageHint,
                      prefixIcon: const Icon(Icons.notes_outlined),
                    ),
                  ),
                  const SizedBox(height: 28),
                  OutlinedButton.icon(
                    onPressed: _loading ? null : _submit,
                    icon: const Icon(Icons.arrow_back),
                    label: Text(l10n.confirmRequest),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
