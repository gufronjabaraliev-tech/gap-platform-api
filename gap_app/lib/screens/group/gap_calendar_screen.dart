import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../models/savings_group.dart';
import '../../providers/groups_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/gap_theme_extension.dart';
import '../../utils/gap_date_format.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/gap_card.dart';
import '../../widgets/gap_group_scroll_body.dart';
import '../../widgets/group_header.dart';

class GapCalendarScreen extends StatefulWidget {
  const GapCalendarScreen({super.key, this.promptPickNext = false});

  /// Jamg'arish tugagach kalendarga yo'naltirish.
  final bool promptPickNext;

  @override
  State<GapCalendarScreen> createState() => _GapCalendarScreenState();
}

class _GapCalendarScreenState extends State<GapCalendarScreen> {
  CalendarFormat _format = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final g = context.read<GroupsProvider>().activeGroup;
    if (g?.nextGapDueDate != null) {
      _focusedDay = g!.nextGapDueDate!;
      _selectedDay = g.nextGapDueDate;
    }
    if (widget.promptPickNext) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        showGapSnackBar(
          context,
          'Bugun jamg\'arma yakunlandi. Keyingi GAP kunini tanlang.',
        );
      });
    }
  }

  bool _canPickDate(SavingsGroup g, GroupsProvider groups) {
    if (!groups.canEditActive) return false;
    if (g.isClosed) return false;
    return g.isWaitingForNextGap ||
        g.nextGapDueDate != null ||
        g.lastGapCollectionDate != null;
  }

  bool _isSelectableDay(SavingsGroup g, DateTime day) {
    if (!_canPickDate(g, context.read<GroupsProvider>())) return false;
    final d = gapDateOnly(day);
    final today = gapDateOnly(DateTime.now());
    return d.isAfter(today);
  }

  Future<void> _saveDate(SavingsGroup g) async {
    final picked = _selectedDay;
    if (picked == null) return;
    setState(() => _saving = true);
    final groups = context.read<GroupsProvider>();
    final err = await groups.setNextGapDueDate(picked);
    if (!mounted) return;
    setState(() => _saving = false);
    if (err != null) {
      showGapSnackBar(context, err, isError: true);
      return;
    }
    showGapSnackBar(
      context,
      'Keyingi GAP: ${formatGapDate(picked, withWeekday: true)}. Eslatmalar yoqildi.',
    );
    if (widget.promptPickNext && mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final groups = context.watch<GroupsProvider>();
    final g = groups.activeGroup!;
    final canPick = _canPickDate(g, groups);
    final gap = context.gap;
    final cs = Theme.of(context).colorScheme;
    final today = gapDateOnly(DateTime.now());

    return Scaffold(
      body: GapGroupScrollBody(
        header: const GroupHeader(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
                GapCard(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.today_rounded,
                          color: cs.primary,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bugun',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(
                                    color: gap.mutedText,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              formatGapDate(today, withWeekday: true),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (g.nextGapDueDate != null)
                  GapCard(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.notifications_active_rounded,
                          color: cs.primary),
                      title: const Text('Keyingi jamg\'arma'),
                      subtitle: Text(g.nextGapDueDateLabel!),
                      trailing: g.gapCollectedToday && canPick
                          ? TextButton(
                              onPressed: _saving ? null : () => _saveDate(g),
                              child: _saving
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Saqlash'),
                            )
                          : null,
                    ),
                  ),
                GapCard(
                  padding: const EdgeInsets.all(8),
                  child: TableCalendar<void>(
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2035, 12, 31),
                    focusedDay: _focusedDay,
                    calendarFormat: _format,
                    startingDayOfWeek: StartingDayOfWeek.monday,
                    selectedDayPredicate: (day) =>
                        _selectedDay != null && isSameDay(_selectedDay, day),
                    enabledDayPredicate: (day) => _isSelectableDay(g, day),
                    onFormatChanged: (f) => setState(() => _format = f),
                    onDaySelected: (selected, focused) {
                      if (!_isSelectableDay(g, selected)) return;
                      setState(() {
                        _selectedDay = gapDateOnly(selected);
                        _focusedDay = focused;
                      });
                    },
                    onPageChanged: (focused) => _focusedDay = focused,
                    calendarStyle: CalendarStyle(
                      todayDecoration: const BoxDecoration(),
                      selectedDecoration: const BoxDecoration(),
                      disabledTextStyle: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.25),
                      ),
                      weekendTextStyle: TextStyle(
                        color: cs.error.withValues(alpha: 0.85),
                      ),
                    ),
                    headerStyle: HeaderStyle(
                      formatButtonVisible: true,
                      titleCentered: true,
                      formatButtonDecoration: BoxDecoration(
                        border: Border.all(color: cs.outline.withValues(alpha: 0.4)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    calendarBuilders: CalendarBuilders(
                      defaultBuilder: (context, day, focusedDay) {
                        return _calendarDayCell(
                          day: day,
                          gap: gap,
                          cs: cs,
                          group: g,
                          enabled: _isSelectableDay(g, day),
                          isSelected: _selectedDay != null &&
                              isSameDay(_selectedDay, day),
                          isToday: isSameDay(day, today),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 16,
                  runSpacing: 6,
                  children: [
                    _LegendDot(
                      color: cs.primary.withValues(alpha: 0.2),
                      border: cs.primary,
                      label: 'Bugun',
                    ),
                    _LegendDot(
                      color: AppColors.secondary.withValues(alpha: 0.35),
                      label: 'Kutilayotgan GAP',
                    ),
                    _LegendDot(
                      color: cs.primary,
                      label: 'Tanlangan kun',
                    ),
                  ],
                ),
                if (g.lastGapCollectionDate != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Oxirgi jamg\'arma: ${formatGapDate(g.lastGapCollectionDate!, withWeekday: true)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: gap.mutedText,
                        ),
                  ),
                ],
                if (canPick && _selectedDay != null) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _saving ? null : () => _saveDate(g),
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save_rounded),
                      label: Text(
                        'Keyingi GAP: ${formatGapDate(_selectedDay!, withWeekday: true)}',
                      ),
                    ),
                  ),
                ],
                if (!kIsWeb)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      'Eslatmalar: 3 kun oldin, 1 kun oldin va GAP kuni soat 09:00 da.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: gap.mutedText,
                          ),
                    ),
                  ),
        ],
      ),
    );
  }
}

Widget _calendarDayCell({
  required DateTime day,
  required GapThemeExtension gap,
  required ColorScheme cs,
  required SavingsGroup group,
  required bool enabled,
  required bool isSelected,
  required bool isToday,
}) {
  final due = group.nextGapDueDate;
  final isDue = due != null && isSameDay(due, day);

  BoxDecoration? decoration;
  Color textColor;

  if (isSelected) {
    decoration = BoxDecoration(
      gradient: gap.primaryGradient,
      shape: BoxShape.circle,
    );
    textColor = Colors.white;
  } else if (isDue) {
    decoration = BoxDecoration(
      color: AppColors.secondary.withValues(alpha: 0.4),
      shape: BoxShape.circle,
      border: Border.all(color: AppColors.secondaryDeep, width: 2),
    );
    textColor = const Color(0xFF422006);
  } else if (isToday) {
    decoration = BoxDecoration(
      color: cs.primary.withValues(alpha: 0.15),
      shape: BoxShape.circle,
      border: Border.all(color: cs.primary, width: 2),
    );
    textColor = cs.primary;
  } else if (!enabled) {
    textColor = cs.onSurface.withValues(alpha: 0.25);
  } else {
    textColor = cs.onSurface;
  }

  return Center(
    child: Container(
      margin: const EdgeInsets.all(5),
      width: 38,
      height: 42,
      decoration: decoration,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${day.day}',
            style: TextStyle(
              color: textColor,
              fontWeight:
                  isToday || isSelected || isDue ? FontWeight.w800 : null,
              fontSize: 14,
            ),
          ),
          if (isToday && !isSelected)
            Text(
              'Bugun',
              style: TextStyle(
                color: cs.primary,
                fontSize: 8,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            )
          else if (isDue && !isSelected)
            Text(
              'GAP',
              style: TextStyle(
                color: AppColors.secondaryDeep,
                fontSize: 8,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
        ],
      ),
    ),
  );
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({
    required this.color,
    required this.label,
    this.border,
  });

  final Color color;
  final Color? border;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: border != null ? Border.all(color: border!, width: 1.5) : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}
