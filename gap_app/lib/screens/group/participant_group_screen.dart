import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/savings_group.dart';
import '../../providers/groups_provider.dart';
import '../../utils/money_format.dart';
import '../../theme/gap_theme_extension.dart';
import '../../widgets/gap_card.dart';
import '../../widgets/gap_group_scroll_body.dart';
import '../../widgets/group_header.dart';
import 'member_list_screen.dart';
import '../group/schedule_screen.dart';
import '../group/group_chat_screen.dart';
import '../group/status_screen.dart';

/// Ishtirokchi faqat balans va navbatni kuzatadi.
class ParticipantGroupScreen extends StatelessWidget {
  const ParticipantGroupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final groups = context.watch<GroupsProvider>();
    final g = groups.activeGroup!;
    final memberId = groups.activeMemberId;
    final gap = context.gap;
    final cs = Theme.of(context).colorScheme;

    final myPos = g.schedulePositionForMember(memberId);
    final isReceiver = memberId != null && g.isReceiver(memberId);
    final paidEntry = memberId != null ? g.paymentFor(memberId) : null;
    final hasPaid = paidEntry != null;
    return Scaffold(
      body: GapGroupScrollBody(
        header: const GroupHeader(),
        padding: const EdgeInsets.all(16),
        children: [
                  const SizedBox(height: 8),
                  GapCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Jamg\'arma holati',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (g.collectedRawText != null) ...[
                          Text(
                            'Asl to\'lovlar',
                            style: TextStyle(color: gap.mutedText, fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            g.collectedRawText!,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Jami (${g.settlementCurrency.label})',
                            style: TextStyle(color: gap.mutedText, fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                        ],
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Text(
                                formatMoney(g.collectedTotal, g.settlementCurrency),
                                style: TextStyle(
                                  fontSize: g.showDualTotals ? 28 : 36,
                                  fontWeight: FontWeight.w800,
                                  color: cs.primary,
                                ),
                                softWrap: true,
                                maxLines: 2,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6, left: 4),
                              child: Text(
                                '/ ${formatMoney(g.expectedTotalForCurrentReceiver, g.currentReceiverReceiveCurrency)}',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: gap.mutedText,
                                ),
                                softWrap: true,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: !g.canCollectPayments ? 0 : g.paymentProgress,
                            minHeight: 10,
                            backgroundColor: cs.surfaceContainerHighest,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          !g.isScheduleConfigured
                              ? 'Navbat hali sozlanmagan'
                              : '${(g.paymentProgress * 100).round()}% yig\'ildi',
                          style: TextStyle(color: gap.mutedText),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  GapCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sizning balansingiz',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        if (!g.isScheduleConfigured)
                          Text(
                            'Navbat yaratilgach ma\'lumot paydo bo\'ladi',
                            style: TextStyle(color: gap.mutedText),
                          )
                        else if (isReceiver) ...[
                          _BalanceRow(
                            icon: Icons.star_rounded,
                            label: 'Bu davrda siz pul olasiz',
                            value: formatMoney(
                              g.expectedTotalForCurrentReceiver,
                              g.currentReceiverReceiveCurrency,
                            ),
                            color: gap.warning,
                          ),
                        ] else ...[
                          _BalanceRow(
                            icon: hasPaid
                                ? Icons.check_circle_rounded
                                : Icons.schedule_rounded,
                            label: hasPaid
                                ? 'Siz to\'ladingiz'
                                : 'Tavsiya: ${memberId != null ? formatMoney(g.recommendedAmountFor(memberId), g.currencyForMember(memberId)) : formatMoney(g.periodAmount, g.settlementCurrency)}',
                            value: hasPaid
                                ? formatPaymentWithSettlement(g, paidEntry)
                                : '—',
                            color: hasPaid ? gap.success : gap.danger,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  GapCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Navbatingiz',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        if (myPos == null)
                          Text(
                            !g.isScheduleConfigured
                                ? 'Navbat kutilmoqda'
                                : 'Siz navbatda emassiz',
                            style: TextStyle(color: gap.mutedText),
                          )
                        else ...[
                          Text(
                            SavingsGroup.queueNumber(myPos),
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w800,
                              color: cs.primary,
                            ),
                          ),
                          Text(
                            'Jami ${g.schedule.length} kishidan',
                            style: TextStyle(color: gap.mutedText),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Hozir: ${g.currentReceiverName} pul olmoqda (${g.currentPeriodLabel})',
                            style: const TextStyle(height: 1.4),
                          ),
                        ],
                      ],
                    ),
                  ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const GroupChatScreen(),
                    ),
                  ),
                  icon: const Icon(Icons.chat_rounded),
                  label: const Text('Guruh chat'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MemberListScreen(),
                    ),
                  ),
                  icon: const Icon(Icons.groups_rounded),
                  label: const Text('A\'zolar va holat'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ScheduleScreen()),
                  ),
                  icon: const Icon(Icons.format_list_numbered_rounded),
                  label: const Text('To\'liq navbat'),
                ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const StatusScreen()),
                    ),
                    icon: const Icon(Icons.bar_chart_rounded),
                    label: const Text('To\'lovlar holati'),
                  ),
        ],
      ),
    );
  }
}

class _BalanceRow extends StatelessWidget {
  const _BalanceRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
