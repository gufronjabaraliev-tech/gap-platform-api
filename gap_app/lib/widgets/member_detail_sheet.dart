import 'package:flutter/material.dart';

import '../models/group_member.dart';
import '../models/member_group_summary.dart';
import '../models/savings_group.dart';
import '../theme/gap_icons.dart';
import '../models/schedule_mode.dart';
import '../theme/app_colors.dart';
import '../theme/gap_theme_extension.dart';
import '../utils/money_format.dart';
import '../utils/pin_util.dart';
import 'gap_sliding_text.dart';
import 'member_avatar.dart';

/// Masul uchun ishtirokchi batafsil: ma'lumot, navbat, balans.
class MemberDetailSheet extends StatelessWidget {
  const MemberDetailSheet({
    super.key,
    required this.group,
    required this.memberId,
    required this.member,
  });

  final SavingsGroup group;
  final String memberId;
  final GroupMember member;

  static Future<void> show(
    BuildContext context, {
    required SavingsGroup group,
    required String memberId,
    required GroupMember member,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => MemberDetailSheet(
        group: group,
        memberId: memberId,
        member: member,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gap = context.gap;
    final cs = Theme.of(context).colorScheme;
    final summary = MemberGroupSummary.forMember(group, memberId);
    final isMasul = group.isResponsibleMember(memberId);
    final pos = summary.schedulePosition;

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
          children: [
            Row(
              children: [
                MemberAvatar(
                  displayName: member.displayName,
                  member: member,
                  phone: member.phone,
                  linkedUserId: member.linkedUserId,
                  radius: 32,
                  backgroundColor: isMasul ? gap.warning : cs.primary,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GapSlidingText(
                        text: member.displayName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      if (isMasul)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Masul',
                            style: TextStyle(
                              color: gap.warning,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      if (member.phone != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          formatPhoneDisplay(member.phone!),
                          style: TextStyle(color: gap.mutedText),
                        ),
                      ],
                      if (member.isPending)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Hali ilovaga kirmagan',
                            style: TextStyle(color: gap.warning, fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _SectionTitle(title: 'GAP dagi holati', icon: GapIcons.payments),
            const SizedBox(height: 8),
            _InfoCard(
              children: [
                _Row(
                  label: 'To\'lagan',
                  value: summary.totalPaidRaw ??
                      formatMoney(
                        group.fromSettlementAmount(
                          summary.totalPaidSettlement,
                          summary.paymentCurrency,
                        ),
                        summary.paymentCurrency,
                      ),
                  valueColor: cs.primary,
                  bold: true,
                ),
                if (summary.showRemaining)
                  _Row(
                    label: 'Qolgan to\'lov',
                    value: formatMoney(
                      group.fromSettlementAmount(
                        summary.remainingDisplay,
                        summary.paymentCurrency,
                      ),
                      summary.paymentCurrency,
                    ),
                    valueColor: gap.warning,
                  ),
                if (summary.showReceivingNow)
                  _Row(
                    label: 'Hozir oladi',
                    value: formatMoney(
                      group.fromSettlementAmount(
                        group.expectedTotalForCurrentReceiver,
                        summary.receiveCurrency,
                      ),
                      summary.receiveCurrency,
                    ),
                    valueColor: AppColors.teal,
                  )
                else if (summary.showFuture)
                  _Row(
                    label: 'Kutilayotgan summa',
                    value: formatMoney(
                      group.fromSettlementAmount(
                        summary.futureReceiveDisplay,
                        summary.receiveCurrency,
                      ),
                      summary.receiveCurrency,
                    ),
                    valueColor: AppColors.secondaryDeep,
                  ),
                if (summary.hasReceived && !summary.showRemaining)
                  _Row(
                    label: 'Pul olish',
                    value: 'Pul olgan',
                    valueColor: gap.success,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _SectionTitle(title: 'Navbat', icon: Icons.format_list_numbered_rounded),
            const SizedBox(height: 8),
            _InfoCard(
              children: [
                if (!group.isScheduleConfigured)
                  _Row(
                    label: 'Navbat',
                    value: 'Hali sozlanmagan',
                    valueColor: gap.mutedText,
                  )
                else ...[
                  _Row(
                    label: 'Navbat raqami',
                    value: pos != null ? SavingsGroup.queueNumber(pos) : '—',
                    valueColor: pos != null ? cs.primary : gap.mutedText,
                    bold: pos != null,
                  ),
                  _Row(
                    label: 'Holat',
                    value: _scheduleStatusLabel(summary, pos),
                    valueColor: _scheduleStatusColor(summary, gap, cs),
                  ),
                  if (group.scheduleMode == ScheduleMode.fixedRandom &&
                      pos != null &&
                      group.schedule.isNotEmpty)
                    _Row(
                      label: 'Jami navbat',
                      value: '${group.schedule.length} kishi',
                      valueColor: gap.mutedText,
                    ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            _SectionTitle(title: 'Valyuta', icon: Icons.currency_exchange_rounded),
            const SizedBox(height: 8),
            _InfoCard(
              children: [
                _Row(label: 'To\'lov', value: member.paymentPrefLabel.replaceFirst('To\'lov: ', '')),
                _Row(label: 'Qabul', value: member.receivePrefLabel.replaceFirst('Qabul: ', '')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _scheduleStatusLabel(MemberGroupSummary s, int? pos) {
    if (!group.isScheduleConfigured) return '—';
    if (s.isCurrentReceiver) return 'Hozir pul olmoqda';
    if (s.hasReceived) return 'Allaqachon pul olgan';
    if (pos != null) {
      if (group.scheduleMode == ScheduleMode.fixedRandom) {
        final idx = group.schedule.indexOf(memberId);
        if (idx > group.currentPeriod) {
          return 'Kutilmoqda (${SavingsGroup.queueNumber(pos)})';
        }
      }
      return 'Navbatda (${SavingsGroup.queueNumber(pos)})';
    }
    return 'Navbatda emas';
  }

  Color _scheduleStatusColor(
    MemberGroupSummary s,
    GapThemeExtension gap,
    ColorScheme cs,
  ) {
    if (s.isCurrentReceiver) return AppColors.teal;
    if (s.hasReceived) return gap.success;
    if (s.schedulePosition != null) return cs.primary;
    return gap.mutedText;
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    this.valueColor,
    this.bold = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final gap = context.gap;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(color: gap.mutedText, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                fontSize: bold ? 16 : 14,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
