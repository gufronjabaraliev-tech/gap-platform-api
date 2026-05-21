import 'package:flutter/material.dart';

import '../models/savings_group.dart';
import '../models/schedule_mode.dart';
import '../theme/gap_theme_extension.dart';
import 'gap_card.dart';

/// Qayta yoqilgach START dan oldin: a'zolar, navbat turi, navbat.
class NewCycleSetupCard extends StatelessWidget {
  const NewCycleSetupCard({
    super.key,
    required this.group,
    required this.onMembers,
    required this.onScheduleMode,
    required this.onNavbat,
  });

  final SavingsGroup group;
  final VoidCallback onMembers;
  final VoidCallback onScheduleMode;
  final VoidCallback onNavbat;

  @override
  Widget build(BuildContext context) {
    final gap = context.gap;
    final cs = Theme.of(context).colorScheme;

    return GapCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Yangi GAPni sozlash',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 12),
          _StepRow(
            done: group.hasEnoughMembers,
            label: 'Kamida 2 ta a\'zo',
            actionLabel: 'A\'zolar',
            onAction: onMembers,
            gap: gap,
            cs: cs,
          ),
          const SizedBox(height: 8),
          _StepRow(
            done: true,
            label: 'Navbat turi: ${group.scheduleMode.label}',
            actionLabel: 'O\'zgartirish',
            onAction: onScheduleMode,
            gap: gap,
            cs: cs,
          ),
          const SizedBox(height: 8),
          _StepRow(
            done: group.isNavbatReadyForNewCycle,
            label: _navbatStepLabel(group),
            actionLabel: 'Navbat',
            onAction: onNavbat,
            gap: gap,
            cs: cs,
          ),
          if (group.isNewCycleSetupReady) ...[
            const SizedBox(height: 12),
            Text(
              'Hammasi tayyor — START bosing.',
              style: TextStyle(
                color: gap.success,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _navbatStepLabel(SavingsGroup g) {
    return switch (g.scheduleMode) {
      ScheduleMode.fixedRandom => g.schedule.isNotEmpty
          ? 'GAP navbati tuzilgan'
          : 'GAP navbatini joriy qiling',
      ScheduleMode.manual => g.activeReceiverId != null
          ? 'Birinchi pul oluvchi belgilangan'
          : 'Pul oluvchini tanlang',
      ScheduleMode.randomEach => g.activeReceiverId != null
          ? 'Pul oluvchi belgilangan'
          : 'Pul oluvchini tanlang',
    };
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.done,
    required this.label,
    required this.actionLabel,
    required this.onAction,
    required this.gap,
    required this.cs,
  });

  final bool done;
  final String label;
  final String actionLabel;
  final VoidCallback onAction;
  final GapThemeExtension gap;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          done ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
          color: done ? gap.success : gap.mutedText,
          size: 22,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: done ? FontWeight.w600 : FontWeight.w500,
              color: done ? cs.onSurface : gap.mutedText,
            ),
          ),
        ),
        TextButton(
          onPressed: onAction,
          child: Text(actionLabel),
        ),
      ],
    );
  }
}
