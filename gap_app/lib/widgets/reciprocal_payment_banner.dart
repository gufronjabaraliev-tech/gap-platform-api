import 'package:flutter/material.dart';

import '../models/reciprocal_obligation.dart';
import '../models/savings_group.dart';
import '../theme/gap_theme_extension.dart';
import '../utils/money_format.dart';

/// To'lovchi oldin oluvchiga bergan summa — qaytarish majburiyati eslatmasi.
class ReciprocalPaymentBanner extends StatelessWidget {
  const ReciprocalPaymentBanner({
    super.key,
    required this.group,
    required this.obligation,
  });

  final SavingsGroup group;
  final ReciprocalObligation obligation;

  @override
  Widget build(BuildContext context) {
    final gap = context.gap;
    final cs = Theme.of(context).colorScheme;
    final receiverName = group.displayNameFor(obligation.currentReceiverId);
    final payerName = group.displayNameFor(obligation.payerMemberId);
    final amount = formatMoney(obligation.entry.amount, obligation.entry.currency);
    final periodLabel = group.periodLabelFor(obligation.sourcePeriod);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: gap.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: gap.warning.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history_rounded, color: gap.warning, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Majburiy to\'lov: $amount',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: gap.warning,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$periodLabel da $payerName pul olganida $receiverName unga $amount bergan.',
            style: TextStyle(height: 1.4, color: cs.onSurface.withValues(alpha: 0.85)),
          ),
          const SizedBox(height: 6),
          Text(
            '$payerName ning to\'lov majburiyati: $amount ($receiverName ga qaytarish). '
            'Valyuta va kursni o\'zingiz belgilashingiz mumkin.',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: cs.onSurface,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
