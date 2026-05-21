import 'package:flutter/material.dart';

import '../models/savings_group.dart';
import '../theme/gap_theme_extension.dart';
import '../utils/money_format.dart';
import 'gap_sliding_text.dart';

/// Jamg'arma holati — ixcham (boshqaruv) yoki to'liq.
class FundBanner extends StatelessWidget {
  const FundBanner({
    super.key,
    required this.group,
    this.compact = false,
  });

  final SavingsGroup group;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) return _CompactFundBanner(group: group);
    return _FullFundBanner(group: group);
  }
}

class _CompactFundBanner extends StatelessWidget {
  const _CompactFundBanner({required this.group});
  final SavingsGroup group;

  @override
  Widget build(BuildContext context) {
    final gap = context.gap;
    final settlement = group.settlementCurrency;
    final pct = (group.paymentProgress * 100).round();
    final raw = group.collectedRawText;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: gap.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: gap.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                group.currentGapRoundLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  group.currentPeriodLabel,
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
              ),
              if (group.isScheduleConfigured)
                GapSlidingText(
                  text: group.currentReceiverName,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.start,
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (raw != null && group.showDualTotals) ...[
            Text(
              'Asl: $raw',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
          ],
          Text(
            formatMoney(group.collectedTotal, settlement),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          Text(
            'Maqsad: ${formatMoney(group.expectedTotalForCurrentReceiver, group.currentReceiverReceiveCurrency)}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          if (!group.gapSessionActive) ...[
            Text(
              group.isNextGapDue
                  ? 'START kutilyapti'
                  : 'GAP yopiq · ${group.nextGapDueDateLabel ?? "kutilmoqda"}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
          ],
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: group.canAcceptPayments ? group.paymentProgress : 0,
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.25),
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          if (group.canAcceptPayments)
            Text(
              'To\'langan: ${group.paidCount} ta ishtirokchi · '
              'Qolgan: ${group.unpaidPayersCount} ta · $pct%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            )
          else if (!group.gapSessionActive)
            const Text(
              'To\'lovlar qabul qilinmaydi',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            )
          else
            const Text(
              'Navbat sozlanmagan',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
        ],
      ),
    );
  }
}

class _FullFundBanner extends StatelessWidget {
  const _FullFundBanner({required this.group});
  final SavingsGroup group;

  @override
  Widget build(BuildContext context) {
    final gap = context.gap;
    final pct = (group.paymentProgress * 100).round();
    final settlement = group.settlementCurrency;
    final raw = group.collectedRawText;
    final showDual = group.showDualTotals && raw != null;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: gap.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: gap.heroShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                group.currentGapRoundLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: gap.glassOverlay,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  group.currentPeriodLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (showDual) ...[
            Text(
              'Asl to\'lovlar',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              raw,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Jami (${settlement.label})',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
          ],
          Text(
            formatMoney(group.collectedTotal, settlement),
            style: TextStyle(
              color: Colors.white,
              fontSize: showDual ? 32 : 40,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
            ),
          ),
          Text(
            'Maqsad (${group.currentReceiverReceiveCurrency.label}): '
            '${formatMoney(group.expectedTotalForCurrentReceiver, group.currentReceiverReceiveCurrency)}',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.85)),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: !group.canAcceptPayments ? 0 : group.paymentProgress,
              minHeight: 10,
              backgroundColor: Colors.white.withValues(alpha: 0.25),
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'To\'langan: ${group.paidCount} ta',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  softWrap: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Qolgan: ${group.unpaidPayersCount} ta · $pct%',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  textAlign: TextAlign.end,
                  softWrap: true,
                ),
              ),
            ],
          ),
          if (group.isScheduleConfigured) ...[
            const SizedBox(height: 14),
            Divider(color: Colors.white.withValues(alpha: 0.2), height: 1),
            const SizedBox(height: 10),
            GapSlidingText(
              text: 'Pul oluvchi: ${group.currentReceiverName}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (group.currentReceiverId != null)
              Text(
                'Qabul qiladi: ${group.currentReceiverReceiveCurrency.label}'
                "${group.receivePreferenceFor(group.currentReceiverId!) == null ? ' (farqi yo\'q)' : ''}",
                style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
              ),
          ],
        ],
      ),
    );
  }
}
