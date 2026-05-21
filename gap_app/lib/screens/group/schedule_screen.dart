import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/group_member.dart';
import '../../models/savings_group.dart';
import '../../models/schedule_mode.dart';
import '../../providers/groups_provider.dart';
import '../../theme/gap_theme_extension.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/gap_card.dart';
import '../../widgets/gap_sliding_text.dart';
import '../../widgets/gap_group_scroll_body.dart';
import '../../widgets/group_header.dart';
import '../../widgets/manual_participant_list.dart';
import '../../widgets/member_avatar.dart';
import 'fixed_schedule_shuffle_screen.dart';
import 'random_pick_screen.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  String? _firstReceiverId;
  bool _showFirstReceiverPicker = false;

  void _openScheduleSetupSheet(
    BuildContext context,
    GroupsProvider groups,
    SavingsGroup g,
  ) {
    if (g.scheduleMode == ScheduleMode.manual) return;
    if (g.isScheduleConfigured) return;

    var sheetFirst = _firstReceiverId;
    var showPicker = _showFirstReceiverPicker;
    final gap = context.gap;
    final mode = g.scheduleMode;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (sheetCtx, setSheet) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 8,
                bottom: MediaQuery.viewInsetsOf(sheetCtx).bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Navbatni joriy qilish',
                      style: Theme.of(sheetCtx).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(mode.icon, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            mode.label,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      mode.description,
                      style: TextStyle(fontSize: 13, color: gap.mutedText),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tur GAP yaratilganda belgilangan. O\'zgartirish: Sozlamalar.',
                      style: TextStyle(fontSize: 12, color: gap.mutedText),
                    ),
                    const SizedBox(height: 16),
                    if (mode == ScheduleMode.fixedRandom) ...[
                      Text(
                        'Barcha ishtirokchilar tasodifiy navbatga qo\'yiladi. '
                        'Birinchi oluvchini oldindan belgilash shart emas.',
                        style: TextStyle(fontSize: 13, color: gap.mutedText, height: 1.35),
                      ),
                      const SizedBox(height: 14),
                      FilledButton.icon(
                        onPressed: () async {
                          setState(() {
                            _firstReceiverId = null;
                            _showFirstReceiverPicker = false;
                          });
                          final ok = await _startFixed(groups);
                          if (ok && sheetCtx.mounted) {
                            Navigator.pop(sheetCtx);
                          }
                        },
                        icon: const Icon(Icons.shuffle_rounded),
                        label: const Text('Tasodifiy navbat tuzish'),
                      ),
                      const SizedBox(height: 10),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: showPicker,
                        onChanged: (v) {
                          setSheet(() {
                            showPicker = v;
                            if (!v) {
                              sheetFirst = null;
                            } else if (sheetFirst == null &&
                                g.members.isNotEmpty) {
                              sheetFirst = g.members.keys.first;
                            }
                          });
                          setState(() {
                            _showFirstReceiverPicker = v;
                            if (!v) {
                              _firstReceiverId = null;
                            } else if (_firstReceiverId == null &&
                                g.members.isNotEmpty) {
                              _firstReceiverId = g.members.keys.first;
                            }
                          });
                        },
                        title: const Text(
                          'Birinchi oluvchini o\'zim belgilayman',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        subtitle: Text(
                          'Ixtiyoriy — aks holda hammasi tasodifiy',
                          style: TextStyle(fontSize: 12, color: gap.mutedText),
                        ),
                      ),
                      if (showPicker) ...[
                        const SizedBox(height: 4),
                        DropdownButtonFormField<String>(
                          value: sheetFirst ?? g.members.keys.firstOrNull,
                          decoration: const InputDecoration(
                            labelText: 'Birinchi navbat (1-chi GAP)',
                          ),
                          items: g.members.entries
                              .map(
                                (e) => DropdownMenuItem(
                                  value: e.key,
                                  child: Text(e.value.displayName),
                                ),
                              )
                              .toList(),
                          onChanged: (v) {
                            setSheet(() => sheetFirst = v);
                            setState(() => _firstReceiverId = v);
                          },
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: sheetFirst == null
                              ? null
                              : () async {
                                  setState(() => _firstReceiverId = sheetFirst);
                                  final ok = await _startFixed(
                                    groups,
                                    firstReceiverId: sheetFirst,
                                  );
                                  if (ok && sheetCtx.mounted) {
                                    Navigator.pop(sheetCtx);
                                  }
                                },
                          icon: const Icon(Icons.person_pin_rounded),
                          label: const Text('Shu tartibda navbat tuzish'),
                        ),
                      ],
                    ] else
                      FilledButton.icon(
                        onPressed: () async {
                          Navigator.pop(sheetCtx);
                          if (!context.mounted) return;
                          await _openRandomPick(context, groups);
                        },
                        icon: const Icon(Icons.casino_rounded),
                        label: const Text('Tasodifiy tanlash ekrani'),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final groups = context.watch<GroupsProvider>();
    final g = groups.activeGroup!;
    final canEdit = groups.canEditActive;
    final myMemberId = groups.activeMemberId;
    final gap = context.gap;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: GapGroupScrollBody(
        header: const GroupHeader(),
        padding: const EdgeInsets.all(16),
        children: [
                if (canEdit &&
                    !g.isScheduleConfigured &&
                    g.scheduleMode != ScheduleMode.manual) ...[
                  FilledButton.icon(
                    onPressed: () =>
                        _openScheduleSetupSheet(context, groups, g),
                    icon: const Icon(Icons.auto_awesome_rounded),
                    label: const Text('Navbatni generatsiya qilish'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 52),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Row(
                  children: [
                    Icon(g.scheduleMode.icon, size: 22, color: cs.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            g.scheduleMode.label,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            g.scheduleMode.description,
                            style: TextStyle(
                              fontSize: 12,
                              color: gap.mutedText,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (canEdit)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 8),
                    child: Text(
                      'Usul GAP yaratilganda belgilangan. Turini faqat Sozlamalar bo\'limidan o\'zgartirish mumkin.',
                      style: TextStyle(fontSize: 12, color: gap.mutedText),
                    ),
                  ),
                const SizedBox(height: 4),
                if (g.scheduleMode == ScheduleMode.manual) ...[
                  if (g.members.length < 2)
                    Text(
                      'Ixtiyoriy navbat uchun kamida 2 ta ishtirokchi kerak.',
                      style: TextStyle(color: gap.warning, height: 1.35),
                    )
                  else ...[
                    if (g.activeReceiverId != null) ...[
                      _currentReceiverCard(
                        g,
                        gap,
                        isSelf: g.activeReceiverId == myMemberId,
                      ),
                      const SizedBox(height: 12),
                    ],
                    ManualParticipantList(
                      group: g,
                      myMemberId: myMemberId,
                      canSelect: canEdit &&
                          g.activeReceiverId == null &&
                          !g.isClosed &&
                          g.eligibleReceiverIds.isNotEmpty &&
                          (g.gapSessionActive ||
                              g.pendingNewCycleSetup ||
                              g.canStartGapSession),
                      onSelect: canEdit
                          ? (id, name) =>
                              _selectManualReceiver(context, groups, g, id, name)
                          : null,
                    ),
                  ],
                ] else if (!g.isScheduleConfigured && !canEdit)
                  const Text('Masul hali navbatni sozlamagan')
                else if (!g.isScheduleConfigured && canEdit)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      'Navbat hali generatsiya qilinmagan. Yuqoridagi '
                      '«Navbatni generatsiya qilish» tugmasini bosing.',
                      style: TextStyle(color: gap.mutedText, height: 1.35),
                    ),
                  )
                else if (g.scheduleMode == ScheduleMode.fixedRandom) ...[
                  if (g.schedule.isEmpty)
                    Text(
                      'Navbat tuzilmagan',
                      style: TextStyle(color: gap.mutedText),
                    )
                  else
                    ...g.schedule.asMap().entries.map((e) {
                      final id = e.value;
                      final received = g.hasReceivedFund(id);
                      final isCurrent =
                          !received && g.currentReceiverId == id;
                      final isScheduled =
                          g.scheduledReceiverId == id &&
                          !g.isDiscretionaryReceiverActive;
                      return _scheduleTile(
                        index: e.key,
                        name: g.displayNameFor(id),
                        member: g.members[id],
                        isCurrent: isCurrent,
                        isSelf: id == myMemberId,
                        received: received,
                        gap: gap,
                        cs: cs,
                        subtitle: received
                            ? 'Jamg\'arma olgan — qayta tanlanmaydi'
                            : isCurrent && g.isDiscretionaryReceiverActive
                                ? 'Ixtiyoriy belgilangan (navbat: ${SavingsGroup.queueNumber(e.key + 1)})'
                                : isScheduled && !isCurrent
                                    ? 'Navbatda kutmoqda'
                                    : null,
                      );
                    }),
                  if (canEdit && g.canUseDiscretionaryReceive) ...[
                    const SizedBox(height: 12),
                    GapCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            '1 marta ixtiyoriy belgilash',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Navbat tuzilgach, xohlasangiz joriy GAP uchun '
                            'istalgan ishtirokchini pul oluvchi qilib belgilang. '
                            'Faqat bir marta.',
                            style: TextStyle(
                              fontSize: 12,
                              color: gap.mutedText,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 12),
                          FilledButton.tonalIcon(
                            onPressed: g.isCurrentPeriodHandedOver
                                ? null
                                : () => _grantDiscretionary(context, groups, g),
                            icon: const Icon(Icons.card_giftcard_rounded),
                            label: const Text('Ishtirokchini tanlash'),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (canEdit && g.discretionaryReceiveGrantUsed) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Ixtiyoriy huquq ishlatilgan',
                      style: TextStyle(fontSize: 12, color: gap.mutedText),
                    ),
                  ],
                  if (canEdit && g.schedule.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () => _recreateFixed(context, groups, g),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Navbatni qayta tuzish'),
                    ),
                  ],
                ] else ...[
                  if (g.activeReceiverId != null)
                    _currentReceiverCard(
                      g,
                      gap,
                      isSelf: g.activeReceiverId == myMemberId,
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Joriy davr uchun pul oluvchi tanlanmagan',
                        style: TextStyle(color: gap.warning),
                      ),
                    ),
                  if (g.scheduleMode == ScheduleMode.randomEach &&
                      g.members.length >= 2) ...[
                    const SizedBox(height: 16),
                    _randomEachParticipantList(
                      context,
                      g,
                      myMemberId: myMemberId,
                      gap: gap,
                      cs: cs,
                    ),
                  ],
                    if (canEdit &&
                        !g.gapSessionActive &&
                        !g.pendingNewCycleSetup &&
                        !g.canStartGapSession)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GapInfoBanner(
                          icon: Icons.lock_clock_rounded,
                          message:
                              'Tasodifiy tanlash START bosilgandan keyin ochiladi.',
                          tone: GapBannerTone.info,
                        ),
                      ),
                    if (canEdit) ...[
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: (g.gapSessionActive ||
                                  g.pendingNewCycleSetup ||
                                  g.canStartGapSession) &&
                              g.activeReceiverId == null &&
                              g.eligibleReceiverIds.isNotEmpty
                          ? () => _openRandomPick(context, groups)
                          : null,
                      icon: const Icon(Icons.casino_rounded),
                      label: const Text('Tasodifiy tanlash ekrani'),
                    ),
                  ],
                ],
        ],
      ),
    );
  }

  Widget _randomEachParticipantList(
    BuildContext context,
    SavingsGroup g, {
    required String? myMemberId,
    required GapThemeExtension gap,
    required ColorScheme cs,
  }) {
    final memberIds = g.members.keys.toList()
      ..sort((a, b) {
        final aReceived = g.hasReceivedFund(a);
        final bReceived = g.hasReceivedFund(b);
        if (aReceived != bReceived) return aReceived ? 1 : -1;
        return g.displayNameFor(a).compareTo(g.displayNameFor(b));
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Ishtirokchilar',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Text(
          'Tasodifiy tanlash faqat hali pul olmaganlar orasida.',
          style: TextStyle(fontSize: 12, color: gap.mutedText, height: 1.35),
        ),
        const SizedBox(height: 10),
        ...memberIds.map((id) {
          final m = g.members[id]!;
          final received = g.hasReceivedFund(id);
          final isCurrent = g.activeReceiverId == id;
          final isSelf = id == myMemberId;

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            color: received
                ? cs.surfaceContainerHighest.withValues(alpha: 0.5)
                : isCurrent
                    ? cs.primaryContainer.withValues(alpha: 0.35)
                    : null,
            child: ListTile(
              leading: MemberAvatar(
                displayName: m.displayName,
                member: m,
                phone: m.phone,
                linkedUserId: m.linkedUserId,
                radius: 24,
                backgroundColor: received
                    ? gap.mutedText
                    : isCurrent
                        ? cs.primary
                        : isSelf
                            ? gap.warning
                            : cs.primary,
              ),
              title: GapSlidingText(
                text: m.displayName,
                style: TextStyle(
                  fontWeight: isCurrent || isSelf ? FontWeight.w700 : null,
                  color: received ? gap.mutedText : null,
                  decoration: received ? TextDecoration.lineThrough : null,
                ),
              ),
              subtitle: received
                  ? const Text(
                      'Jamg\'arma olgan — tanlashdan tashqari',
                      style: TextStyle(fontSize: 12),
                    )
                  : isCurrent
                      ? Text(
                          'Joriy pul oluvchi',
                          style: TextStyle(color: cs.primary, fontSize: 12),
                        )
                      : Text(
                          'Tasodifiy tanlashda qatnashishi mumkin',
                          style: TextStyle(color: gap.mutedText, fontSize: 12),
                        ),
              trailing: received
                  ? Icon(Icons.check_circle, color: gap.success, size: 22)
                  : isCurrent
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: cs.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'JORIY',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        )
                      : null,
            ),
          );
        }),
      ],
    );
  }

  Widget _scheduleTile({
    required int index,
    required String name,
    required GroupMember? member,
    required bool isCurrent,
    required bool isSelf,
    required bool received,
    required GapThemeExtension gap,
    required ColorScheme cs,
    String? subtitle,
  }) {
    final onDark = isCurrent;
    final textColor = received
        ? gap.mutedText
        : onDark
            ? Colors.white
            : cs.onSurface;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: isCurrent ? gap.primaryGradient : null,
        color: isCurrent
            ? null
            : received
                ? cs.surfaceContainerHighest.withValues(alpha: 0.55)
                : isSelf
                    ? gap.warning.withValues(alpha: 0.12)
                    : cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: isSelf
            ? Border.all(
                color: onDark ? Colors.white : gap.warning,
                width: 2.5,
              )
            : null,
        boxShadow: [
          if (isSelf)
            BoxShadow(
              color: gap.warning.withValues(alpha: 0.28),
              blurRadius: 10,
              offset: const Offset(0, 2),
            )
          else
            const BoxShadow(color: Color(0x1A000000), blurRadius: 6),
        ],
      ),
      child: Row(
        children: [
          if (member != null)
            MemberAvatar(
              displayName: name,
              member: member,
              phone: member.phone,
              linkedUserId: member.linkedUserId,
              radius: 24,
              backgroundColor: isSelf ? gap.warning : cs.primary,
            )
          else
            CircleAvatar(
              backgroundColor: isSelf ? gap.warning : cs.primaryContainer,
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  color: isSelf ? Colors.white : cs.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GapSlidingText(
                  text: name,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: textColor,
                  ),
                ),
                Text(
                  SavingsGroup.queueNumber(index + 1),
                  style: TextStyle(
                    fontSize: 12,
                    color: onDark
                        ? Colors.white70
                        : gap.mutedText,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: onDark
                          ? Colors.white.withValues(alpha: 0.85)
                          : gap.warning,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (isSelf)
            _selfBadge(
              onDark: onDark,
              gap: gap,
            ),
          if (received)
            Icon(Icons.check_circle_rounded, color: gap.success, size: 22)
          else if (isCurrent) ...[
            if (isSelf) const SizedBox(width: 6),
            Text(
              'JORIY',
              style: TextStyle(
                color: onDark ? Colors.white : cs.primary,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _selfBadge({
    required bool onDark,
    required GapThemeExtension gap,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: onDark ? Colors.white : gap.warning,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'SIZ',
        style: TextStyle(
          color: onDark ? gap.warning : Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 11,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _currentReceiverCard(
    SavingsGroup g,
    GapThemeExtension gap, {
    required bool isSelf,
  }) {
    final id = g.activeReceiverId!;
    final member = g.members[id];
    final name = g.displayNameFor(id);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: gap.primaryGradient,
        borderRadius: BorderRadius.circular(12),
        border: isSelf
            ? Border.all(color: Colors.white, width: 2.5)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (member != null)
                MemberAvatar(
                  displayName: name,
                  member: member,
                  phone: member.phone,
                  linkedUserId: member.linkedUserId,
                  radius: 28,
                  backgroundColor: isSelf
                      ? gap.warning
                      : Colors.white.withValues(alpha: 0.24),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Joriy pul oluvchi',
                      style: TextStyle(color: Colors.white70),
                    ),
                    GapSlidingText(
                      text: name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelf) _selfBadge(onDark: true, gap: gap),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Qabul: ${g.receiveCurrencyForMember(g.activeReceiverId!).label}'
            '${g.receivePreferenceFor(g.activeReceiverId!) == null ? " (farqi yo\'q)" : ""}',
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Future<void> _selectManualReceiver(
    BuildContext context,
    GroupsProvider groups,
    SavingsGroup g,
    String memberId,
    String name,
  ) async {
    final ok = await showGapConfirmDialog(
      context,
      title: 'Pul oluvchini belgilash',
      message:
          '$name joriy davr (${g.currentPeriodLabel}) uchun pul oladi.\n\n'
          'Shu kishiga jamg\'arma yig\'iladi.',
      confirmLabel: 'Belgilash',
      isDanger: false,
    );
    if (ok != true || !context.mounted) return;

    final err = await groups.setActiveReceiver(memberId);
    if (!context.mounted) return;
    if (err != null) {
      showGapSnackBar(context, err, isError: true);
      return;
    }

    if (!context.mounted) return;

    final updated = groups.activeGroup!;
    showGapSnackBar(
      context,
      updated.gapSessionActive
          ? '$name joriy davr uchun pul oluvchi qilib belgilandi. '
              'To\'lovlarni «To\'lovlar» bo\'limidan kiriting.'
          : '$name belgilandi. Boshqaruv panelida START bosing, keyin To\'lovlar.',
    );
  }

  Future<bool> _startFixed(
    GroupsProvider groups, {
    String? firstReceiverId,
  }) async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => FixedScheduleShuffleScreen(
          firstReceiverId: firstReceiverId ?? _firstReceiverId,
        ),
      ),
    );
    if (!mounted) return false;
    if (ok == true) {
      showGapSnackBar(
        context,
        firstReceiverId != null || _firstReceiverId != null
            ? 'GAP navbat tuzildi (birinchi belgilangan)'
            : 'GAP navbat tasodifiy tuzildi',
      );
      setState(() {});
      return true;
    }
    return false;
  }

  Future<void> _openRandomPick(
    BuildContext context,
    GroupsProvider groups,
  ) async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const RandomPickScreen()),
    );
    if (ok == true && mounted) {
      showGapSnackBar(
        context,
        'Tanlandi: ${groups.activeGroup!.currentReceiverName}',
      );
    }
  }

  Future<void> _grantDiscretionary(
    BuildContext context,
    GroupsProvider groups,
    SavingsGroup g,
  ) async {
    final eligible = g.eligibleReceiverIds;
    if (eligible.isEmpty) {
      showGapSnackBar(context, 'Barcha ishtirokchilar pul olgan', isError: true);
      return;
    }

    final picked = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Text(
                  'Ixtiyoriy pul oluvchi',
                  style: Theme.of(ctx).textTheme.titleMedium,
                ),
              ),
              Text(
                'Joriy GAP uchun qaysi ishtirokchi pul oladi? '
                '(Navbatdan qat\'i nazar, 1 marta)',
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              ...eligible.map(
                (id) => ListTile(
                  leading: MemberAvatar(
                    displayName: g.displayNameFor(id),
                    member: g.members[id],
                    phone: g.members[id]?.phone,
                    linkedUserId: g.members[id]?.linkedUserId,
                    radius: 22,
                  ),
                  title: GapSlidingText(text: g.displayNameFor(id)),
                  onTap: () => Navigator.pop(ctx, id),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (picked == null || !context.mounted) return;

    final ok = await showGapConfirmDialog(
      context,
      title: 'Ixtiyoriy huquq',
      message:
          '${g.displayNameFor(picked)} joriy davr uchun pul oluvchi bo\'ladi. '
          'Bu huquq faqat 1 marta ishlatiladi.',
      confirmLabel: 'Tasdiqlash',
    );
    if (ok != true || !context.mounted) return;

    final err = await groups.grantDiscretionaryReceive(picked);
    if (!context.mounted) return;
    if (err != null) {
      showGapSnackBar(context, err, isError: true);
    } else {
      showGapSnackBar(
        context,
        '${g.displayNameFor(picked)} pul oluvchi qilib belgilandi (ixtiyoriy)',
      );
    }
  }

  Future<void> _recreateFixed(
    BuildContext context,
    GroupsProvider groups,
    SavingsGroup g,
  ) async {
    final ok = await showGapConfirmDialog(
      context,
      title: 'Navbatni qayta tuzish',
      message:
          'Eski navbat o\'chadi. Barcha ishtirokchilar yana tasodifiy '
          'tartibga qo\'yiladi. Davom etasizmi?',
    );
    if (ok != true || !context.mounted) return;
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const FixedScheduleShuffleScreen(),
      ),
    );
    if (!context.mounted) return;
    if (saved == true) {
      showGapSnackBar(context, 'Navbat tasodifiy qayta tuzildi');
      setState(() {});
    }
  }
}
