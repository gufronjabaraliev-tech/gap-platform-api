import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/group_member.dart';
import '../../models/member_group_summary.dart';
import '../../models/savings_group.dart';
import '../../theme/gap_icons.dart';
import '../../providers/groups_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/gap_theme_extension.dart';
import '../../utils/money_format.dart';
import '../../utils/pin_util.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/gap_card.dart';
import '../../widgets/gap_sliding_text.dart';
import '../../widgets/group_header.dart';
import '../../widgets/gap_group_scroll_body.dart';
import '../../widgets/member_avatar.dart';
import '../../widgets/member_currency_sheet.dart';
import '../../widgets/member_detail_sheet.dart';
import 'add_member_screen.dart';

/// A'zolar va ishtirokchilar — bitta ro'yxat: boshqaruv + moliyaviy holat.
class MemberListScreen extends StatefulWidget {
  const MemberListScreen({super.key});

  @override
  State<MemberListScreen> createState() => _MemberListScreenState();
}

class _MemberListScreenState extends State<MemberListScreen> {
  Future<void> _pickMemberPrefs(
    BuildContext context,
    GroupsProvider groups,
    String memberId,
    GroupMember m,
  ) async {
    await showMemberCurrencyPrefsSheet(
      context: context,
      memberName: m.displayName,
      currentPayment: m.paymentCurrency,
      currentReceive: m.receiveCurrency,
      onPayment: (c) async {
        await groups.setMemberPaymentCurrency(memberId, c);
        if (context.mounted) {
          showGapSnackBar(
            context,
            c == null ? 'To\'lov: farqi yo\'q' : 'To\'lov: ${c.label}',
          );
        }
      },
      onReceive: (c) async {
        await groups.setMemberReceiveCurrency(memberId, c);
        if (context.mounted) {
          showGapSnackBar(
            context,
            c == null ? 'Qabul: farqi yo\'q' : 'Qabul: ${c.label}',
          );
        }
      },
    );
  }

  Future<void> _removeMember(
    BuildContext context,
    GroupsProvider groups,
    String memberId,
    GroupMember m,
    bool rosterConfirmed,
  ) async {
    if (rosterConfirmed) {
      final ok = await showGapConfirmDialog(
        context,
        title: 'A\'zoni o\'chirish',
        message:
            '${m.displayName} ro\'yxatdan olib tashlanadi. Navbat va to\'lovlar ham yangilanadi.\n\nBu amalni bekor qilib bo\'lmaydi.',
        confirmLabel: 'Davom etish',
      );
      if (ok != true || !context.mounted) return;

      final typed = await showGapTypedConfirmDialog(
        context,
        title: 'Yakuniy tasdiq',
        message: 'Tasodifiy bosishdan himoya uchun a\'zo ismini aniq yozing.',
        typeLabel: 'A\'zo ismi',
        expectedText: m.displayName,
      );
      if (!typed || !context.mounted) return;
    } else {
      final ok = await showGapConfirmDialog(
        context,
        title: 'O\'chirish',
        message: '${m.displayName} ni o\'chirmoqchimisiz?',
      );
      if (ok != true || !context.mounted) return;
    }

    final err = await groups.removeMember(memberId);
    if (!context.mounted) return;
    if (err != null) {
      showGapSnackBar(context, err, isError: true);
    } else {
      showGapSnackBar(context, 'O\'chirildi');
    }
  }

  Future<void> _confirmRoster(BuildContext context, GroupsProvider groups) async {
    final g = groups.activeGroup!;
    final names = g.members.values
        .map((m) => '• ${m.displayName}')
        .join('\n');
    final ok = await showGapConfirmDialog(
      context,
      title: 'A\'zolarni tasdiqlash',
      message:
          'Quyidagi ${g.memberCount} kishi jamoada qoladi:\n\n$names\n\n'
          'Tasdiqlangach a\'zoni o\'chirish qiyinroq bo\'ladi (tasodifiy bosishdan himoya).',
      confirmLabel: 'Tasdiqlash',
      isDanger: false,
    );
    if (ok != true || !context.mounted) return;
    final err = await groups.confirmMembersRoster();
    if (!context.mounted) return;
    if (err != null) {
      showGapSnackBar(context, err, isError: true);
    } else {
      showGapSnackBar(context, 'A\'zolar tasdiqlandi');
    }
  }

  List<String> _sortedMemberIds(SavingsGroup g) {
    final ids = g.members.keys.toList();
    final showRosterOrder = g.isScheduleConfigured ||
        g.gapSessionActive ||
        g.isClosed ||
        g.membersRosterConfirmed;

    if (!showRosterOrder) {
      ids.sort(
        (a, b) => g.displayNameFor(a).compareTo(g.displayNameFor(b)),
      );
      return ids;
    }

    ids.sort((a, b) {
      final sa = MemberGroupSummary.forMember(g, a);
      final sb = MemberGroupSummary.forMember(g, b);
      if (sa.isCurrentReceiver != sb.isCurrentReceiver) {
        return sa.isCurrentReceiver ? -1 : 1;
      }
      if (sa.hasReceived != sb.hasReceived) return sa.hasReceived ? 1 : -1;
      return g.displayNameFor(a).compareTo(g.displayNameFor(b));
    });
    return ids;
  }

  @override
  Widget build(BuildContext context) {
    final groups = context.watch<GroupsProvider>();
    final g = groups.activeGroup!;
    final myId = groups.activeMemberId;
    final canEdit = groups.canEditActive;
    final rosterConfirmed = g.membersRosterConfirmed;
    final gap = context.gap;
    final cs = Theme.of(context).colorScheme;

    final memberIds = _sortedMemberIds(g);
    final showRosterStats = g.isScheduleConfigured ||
        g.gapSessionActive ||
        g.isClosed ||
        g.membersRosterConfirmed;

    final receivedCount = g.membersWhoReceivedFund.length;
    final notReceivedCount = g.membersWhoNotReceivedFund.length;
    var totalContributed = 0;
    for (final id in memberIds) {
      totalContributed += g.totalContributedSettlement(id);
    }

    return Scaffold(
      body: GapGroupScrollBody(
        header: const GroupHeader(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          if (showRosterStats) ...[
            GapCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Jamoa',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _SummaryChip(
                        icon: Icons.people_rounded,
                        label: '${g.memberCount} kishi',
                        color: cs.primary,
                      ),
                      _SummaryChip(
                        icon: Icons.check_circle_rounded,
                        label: 'Olgan: $receivedCount',
                        color: gap.success,
                      ),
                      _SummaryChip(
                        icon: Icons.hourglass_empty_rounded,
                        label: 'Olmagan: $notReceivedCount',
                        color: cs.outline,
                      ),
                      _SummaryChip(
                        icon: Icons.payments_rounded,
                        label:
                            'Jami: ${formatMoney(totalContributed, g.settlementCurrency)}',
                        color: AppColors.teal,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (rosterConfirmed)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GapCard(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.verified_rounded, color: cs.primary),
                  title: const Text('A\'zolar tasdiqlangan'),
                  subtitle: Text(
                    'O\'chirish uchun qo\'shimcha tasdiq kerak',
                    style: TextStyle(color: gap.mutedText, fontSize: 12),
                  ),
                ),
              ),
            ),
          ...memberIds.map(
            (id) => _UnifiedMemberTile(
              group: g,
              memberId: id,
              isSelf: id == myId,
              isMasul: g.isResponsibleMember(id),
              canEdit: canEdit,
              rosterConfirmed: rosterConfirmed,
              showRosterStats: showRosterStats,
              gap: gap,
              cs: cs,
              onDetail: canEdit
                  ? () => MemberDetailSheet.show(
                        context,
                        group: g,
                        memberId: id,
                        member: g.members[id]!,
                      )
                  : null,
              onCurrency: canEdit && !g.isResponsibleMember(id)
                  ? () => _pickMemberPrefs(
                        context,
                        groups,
                        id,
                        g.members[id]!,
                      )
                  : null,
              onRemove: canEdit && !g.isResponsibleMember(id)
                  ? () => _removeMember(
                        context,
                        groups,
                        id,
                        g.members[id]!,
                        rosterConfirmed,
                      )
                  : null,
            ),
          ),
          if (canEdit) ...[
            const SizedBox(height: 8),
            if (!rosterConfirmed && g.memberCount >= 2)
              FilledButton.icon(
                onPressed: () => _confirmRoster(context, groups),
                icon: const Icon(Icons.verified_user_rounded),
                label: const Text('A\'zolarni tasdiqlash'),
              ),
            if (!rosterConfirmed && g.memberCount >= 2)
              const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddMemberScreen()),
              ),
              icon: const Icon(Icons.person_add_rounded),
              label: const Text('A\'zo qo\'shish'),
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _UnifiedMemberTile extends StatelessWidget {
  const _UnifiedMemberTile({
    required this.group,
    required this.memberId,
    required this.isSelf,
    required this.isMasul,
    required this.canEdit,
    required this.rosterConfirmed,
    required this.showRosterStats,
    required this.gap,
    required this.cs,
    this.onDetail,
    this.onCurrency,
    this.onRemove,
  });

  final SavingsGroup group;
  final String memberId;
  final bool isSelf;
  final bool isMasul;
  final bool canEdit;
  final bool rosterConfirmed;
  final bool showRosterStats;
  final GapThemeExtension gap;
  final ColorScheme cs;
  final VoidCallback? onDetail;
  final VoidCallback? onCurrency;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final m = group.members[memberId]!;
    final summary = MemberGroupSummary.forMember(group, memberId);
    final contributed = group.totalContributedSettlement(memberId);
    final received = group.totalReceivedSettlement(memberId);
    final pos = summary.schedulePosition;
    final status = showRosterStats
        ? _RosterStatus.from(group, memberId, summary)
        : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GapCard(
        onTap: onDetail,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MemberAvatar(
                  displayName: m.displayName,
                  member: m,
                  phone: m.phone,
                  linkedUserId: m.linkedUserId,
                  radius: 26,
                  backgroundColor: status?.avatarColor(cs, gap, isSelf) ??
                      (isMasul ? gap.warning : cs.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: GapSlidingText(
                              text: m.displayName,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: isSelf ? gap.warning : null,
                              ),
                            ),
                          ),
                          if (isSelf)
                            _Badge(label: 'SIZ', color: gap.warning),
                          if (isMasul) ...[
                            const SizedBox(width: 4),
                            _Badge(label: 'Masul', color: gap.warning),
                          ],
                        ],
                      ),
                      if (m.phone != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          formatPhoneDisplay(m.phone!),
                          style: TextStyle(fontSize: 12, color: gap.mutedText),
                        ),
                      ],
                      if (m.isPending)
                        Text(
                          'Kutilmoqda (hali kirmagan)',
                          style: TextStyle(color: gap.warning, fontSize: 12),
                        ),
                      if (pos != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Navbat ${SavingsGroup.queueNumber(pos)}',
                          style: TextStyle(fontSize: 11, color: gap.mutedText),
                        ),
                      ],
                      if (!showRosterStats) ...[
                        const SizedBox(height: 4),
                        Text(
                          m.paymentPrefLabel,
                          style: TextStyle(
                            color: gap.mutedText,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          m.receivePrefLabel,
                          style: TextStyle(
                            color: gap.mutedText,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (canEdit && !isMasul && (onCurrency != null || onRemove != null))
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert_rounded, color: gap.mutedText),
                    onSelected: (v) {
                      if (v == 'currency') onCurrency?.call();
                      if (v == 'delete') onRemove?.call();
                    },
                    itemBuilder: (ctx) => [
                      if (onCurrency != null)
                        const PopupMenuItem(
                          value: 'currency',
                          child: Row(
                            children: [
                              Icon(Icons.currency_exchange_rounded),
                              SizedBox(width: 8),
                              Text('Valyuta'),
                            ],
                          ),
                        ),
                      if (onRemove != null)
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, color: gap.danger),
                              const SizedBox(width: 8),
                              Text(
                                'O\'chirish',
                                style: TextStyle(color: gap.danger),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
              ],
            ),
            if (status != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: status.chipBackground,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: status.chipBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(status.icon, size: 16, color: status.chipForeground),
                    const SizedBox(width: 6),
                    Text(
                      status.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: status.chipForeground,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              _AmountRow(
                icon: Icons.payments_rounded,
                label: 'Jamg\'armaga to\'lagan',
                value: summary.totalPaidRaw ??
                    formatMoney(contributed, group.settlementCurrency),
                sub: contributed > 0 && summary.totalPaidRaw != null
                    ? '≈ ${formatMoney(contributed, group.settlementCurrency)}'
                    : null,
                valueColor: cs.onSurface,
                gap: gap,
              ),
              if (status.hasReceived) ...[
                const SizedBox(height: 6),
                _AmountRow(
                  icon: GapIcons.payments,
                  label: 'Jamg\'arma olgan',
                  value: formatMoney(
                    received > 0
                        ? received
                        : group.fromSettlementAmount(
                            group.expectedTotal,
                            group.receiveCurrencyForMember(memberId),
                          ),
                    received > 0
                        ? group.settlementCurrency
                        : group.receiveCurrencyForMember(memberId),
                  ),
                  valueColor: gap.success,
                  gap: gap,
                ),
              ] else if (summary.isCurrentReceiver) ...[
                const SizedBox(height: 6),
                _AmountRow(
                  icon: Icons.trending_up_rounded,
                  label: 'Kutilayotgan summa',
                  value: formatMoney(
                    group.expectedTotalForCurrentReceiver,
                    group.currentReceiverReceiveCurrency,
                  ),
                  valueColor: cs.primary,
                  gap: gap,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  const _AmountRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.valueColor,
    required this.gap,
    this.sub,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? sub;
  final Color valueColor;
  final GapThemeExtension gap;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: gap.mutedText),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 11, color: gap.mutedText),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: valueColor,
                ),
              ),
              if (sub != null)
                Text(
                  sub!,
                  style: TextStyle(fontSize: 11, color: gap.mutedText),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RosterStatus {
  const _RosterStatus({
    required this.label,
    required this.icon,
    required this.chipBackground,
    required this.chipBorder,
    required this.chipForeground,
    required this.hasReceived,
    required this.avatarColor,
  });

  final String label;
  final IconData icon;
  final Color chipBackground;
  final Color chipBorder;
  final Color chipForeground;
  final bool hasReceived;
  final Color Function(ColorScheme cs, GapThemeExtension gap, bool isSelf)
      avatarColor;

  factory _RosterStatus.from(
    SavingsGroup group,
    String memberId,
    MemberGroupSummary summary,
  ) {
    if (summary.isCurrentReceiver && !summary.hasReceived) {
      return _RosterStatus(
        label: 'Hozir jamg\'arma olmoqda',
        icon: Icons.star_rounded,
        chipBackground: const Color(0x1A2196F3),
        chipBorder: const Color(0x662196F3),
        chipForeground: const Color(0xFF1565C0),
        hasReceived: false,
        avatarColor: (cs, gap, isSelf) => cs.primary,
      );
    }
    if (summary.hasReceived) {
      return _RosterStatus(
        label: 'Jamg\'arma olgan',
        icon: Icons.verified_rounded,
        chipBackground: const Color(0x1A2E7D32),
        chipBorder: const Color(0x662E7D32),
        chipForeground: const Color(0xFF2E7D32),
        hasReceived: true,
        avatarColor: (cs, gap, isSelf) => const Color(0xFF2E7D32),
      );
    }
    return _RosterStatus(
      label: 'Hali jamg\'arma olmagan',
      icon: Icons.radio_button_unchecked_rounded,
      chipBackground: const Color(0x1A757575),
      chipBorder: const Color(0x4D9E9E9E),
      chipForeground: const Color(0xFF616161),
      hasReceived: false,
      avatarColor: (cs, gap, isSelf) => isSelf ? gap.warning : cs.outline,
    );
  }
}
