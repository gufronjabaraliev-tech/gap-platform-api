import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/savings_group.dart';
import '../models/schedule_mode.dart';
import '../providers/groups_provider.dart';
import '../theme/gap_theme_extension.dart';
import 'confirm_dialog.dart';

/// Navbat turini o'zgartirish — faqat Sozlamalar bo'limidan.
class ScheduleModeSettingsSheet extends StatefulWidget {
  const ScheduleModeSettingsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const ScheduleModeSettingsSheet(),
    );
  }

  @override
  State<ScheduleModeSettingsSheet> createState() =>
      _ScheduleModeSettingsSheetState();
}

class _ScheduleModeSettingsSheetState extends State<ScheduleModeSettingsSheet> {
  ScheduleMode? _selected;

  Future<void> _applyMode(
    BuildContext sheetCtx,
    GroupsProvider groups,
    SavingsGroup g,
    ScheduleMode newMode,
  ) async {
    if (newMode == g.scheduleMode) {
      Navigator.pop(sheetCtx);
      return;
    }

    if (g.isScheduleConfigured) {
      final hasProgress = g.payments.isNotEmpty || g.currentPeriod > 0;
      final ok = await showGapConfirmDialog(
        sheetCtx,
        title: 'Navbat turini o\'zgartirish',
        message: hasProgress
            ? 'Navbat, davr va to\'lovlar holati qayta boshlanadi. Davom etasizmi?'
            : 'Eski navbat va joriy davr holati o\'chadi. Yangi turda qayta sozlashingiz kerak bo\'ladi.',
      );
      if (ok != true || !sheetCtx.mounted) return;
    }

    final err = await groups.setScheduleMode(
      newMode,
      resetState: g.isScheduleConfigured,
    );
    if (!sheetCtx.mounted) return;
    if (err != null) {
      showGapSnackBar(sheetCtx, err, isError: true);
      return;
    }

    showGapSnackBar(sheetCtx, 'Navbat turi: ${newMode.label}');
    if (sheetCtx.mounted) Navigator.pop(sheetCtx);
  }

  @override
  Widget build(BuildContext context) {
    final groups = context.watch<GroupsProvider>();
    final g = groups.activeGroup!;
    final gap = context.gap;
    final mode = _selected ?? g.scheduleMode;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 8,
        bottom: MediaQuery.paddingOf(context).bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Navbat turi',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              'GAP yaratilganda tanlangan uslub. O\'zgartirilsa, navbat qayta boshlanadi.',
              style: TextStyle(fontSize: 13, color: gap.mutedText, height: 1.35),
            ),
            const SizedBox(height: 12),
            ...ScheduleMode.values.map(
              (m) => RadioListTile<ScheduleMode>(
                title: Row(
                  children: [
                    Icon(m.icon, size: 20),
                    const SizedBox(width: 8),
                    Text(m.label),
                  ],
                ),
                subtitle: Text(
                  m.description,
                  style: TextStyle(fontSize: 12, color: gap.mutedText),
                ),
                value: m,
                groupValue: mode,
                onChanged: (v) async {
                  if (v == null) return;
                  setState(() => _selected = v);
                  await _applyMode(context, groups, g, v);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
