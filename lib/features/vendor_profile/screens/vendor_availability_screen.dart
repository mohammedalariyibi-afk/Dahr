import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/category_labels.dart';
import '../../../core/models/models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/widgets.dart';
import '../providers/vendor_provider.dart';

class VendorAvailabilityScreen extends ConsumerStatefulWidget {
  const VendorAvailabilityScreen({super.key});

  @override
  ConsumerState<VendorAvailabilityScreen> createState() =>
      _VendorAvailabilityScreenState();
}

class _VendorAvailabilityScreenState
    extends ConsumerState<VendorAvailabilityScreen> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
  }

  Future<void> _toggle(DateTime day, Set<DateTime> booked) async {
    final key = AvailabilitySlot.dateOnly(day);
    final today = AvailabilitySlot.dateOnly(DateTime.now());
    if (key.isBefore(today)) return;
    final next = booked.contains(key)
        ? AvailabilityStatus.available
        : AvailabilityStatus.booked;
    await ref.read(vendorAvailabilityProvider.notifier).upsertDate(key, next);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(vendorAvailabilityProvider);
    final locale = Localizations.localeOf(context).toString();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.availabilityTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final now = DateTime.now();
          final picked = await showDatePicker(
            context: context,
            initialDate: now,
            firstDate: now,
            lastDate: now.add(const Duration(days: 365 * 2)),
          );
          if (picked == null) return;
          await ref
              .read(vendorAvailabilityProvider.notifier)
              .upsertDate(picked, AvailabilityStatus.booked);
        },
        icon: const Icon(Icons.add),
        label: Text(l10n.markBooked),
      ),
      body: AsyncBody<List<AvailabilitySlot>>(
        value: async,
        onRetry: () =>
            ref.read(vendorAvailabilityProvider.notifier).refresh(),
        builder: (context, slots) {
          final booked = AvailabilitySlot.bookedDays(slots);
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              Text(l10n.availabilityHint),
              const SizedBox(height: 12),
              Row(
                children: [
                  _LegendDot(color: AppColors.burgundy, label: l10n.legendBooked),
                  const SizedBox(width: 16),
                  _LegendDot(
                    color: AppColors.creamDark,
                    label: l10n.legendAvailable,
                    outlined: true,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _MonthHeader(
                month: _month,
                locale: locale,
                onPrev: () => setState(() {
                  _month = DateTime(_month.year, _month.month - 1);
                }),
                onNext: () => setState(() {
                  _month = DateTime(_month.year, _month.month + 1);
                }),
              ),
              const SizedBox(height: 8),
              _MonthGrid(
                month: _month,
                booked: booked,
                onDayTap: (day) => _toggle(day, booked),
              ),
              const SizedBox(height: 24),
              if (booked.isEmpty)
                Text(l10n.noBookedDates)
              else ...[
                Text(
                  l10n.legendBooked,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                ...(() {
                  final days = booked.toList()
                    ..sort((a, b) => a.compareTo(b));
                  return days.map(
                    (d) => Card(
                      child: ListTile(
                        title: Text(formatDay(d)),
                        trailing: Switch(
                          value: true,
                          activeColor: AppColors.burgundy,
                          onChanged: (_) => _toggle(d, booked),
                        ),
                      ),
                    ),
                  );
                })(),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({
    required this.color,
    required this.label,
    this.outlined = false,
  });

  final Color color;
  final String label;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: outlined ? Colors.transparent : color,
            border: Border.all(color: AppColors.burgundy, width: 1.5),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({
    required this.month,
    required this.locale,
    required this.onPrev,
    required this.onNext,
  });

  final DateTime month;
  final String locale;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final label = DateFormat.yMMMM(locale).format(month);
    return Row(
      children: [
        IconButton(
          onPressed: onPrev,
          icon: const Icon(Icons.chevron_left),
        ),
        Expanded(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        IconButton(
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.booked,
    required this.onDayTap,
  });

  final DateTime month;
  final Set<DateTime> booked;
  final ValueChanged<DateTime> onDayTap;

  @override
  Widget build(BuildContext context) {
    final first = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final startWeekday = first.weekday % 7; // Sunday = 0
    final today = AvailabilitySlot.dateOnly(DateTime.now());
    final cells = startWeekday + daysInMonth;
    final rows = (cells / 7).ceil();

    return Column(
      children: [
        Row(
          children: List.generate(7, (i) {
            final sample = DateTime.utc(2023, 1, 1).add(Duration(days: i));
            final label = DateFormat.E(
              Localizations.localeOf(context).toString(),
            ).format(sample);
            return Expanded(
              child: Center(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.inkMuted,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        ...List.generate(rows, (r) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: List.generate(7, (c) {
                final index = r * 7 + c;
                final dayNum = index - startWeekday + 1;
                if (dayNum < 1 || dayNum > daysInMonth) {
                  return const Expanded(child: SizedBox(height: 40));
                }
                final day = DateTime(month.year, month.month, dayNum);
                final isBooked = booked.contains(day);
                final past = day.isBefore(today);
                return Expanded(
                  child: InkWell(
                    onTap: past ? null : () => onDayTap(day),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isBooked
                            ? AppColors.burgundy
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isBooked
                              ? AppColors.burgundy
                              : AppColors.border,
                        ),
                      ),
                      child: Text(
                        '$dayNum',
                        style: TextStyle(
                          color: past
                              ? AppColors.inkFaint
                              : isBooked
                                  ? AppColors.onBurgundy
                                  : AppColors.ink,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          );
        }),
      ],
    );
  }
}
