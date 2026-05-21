import 'package:flutter/material.dart';

import '../config/gap_pricing.dart';
import '../theme/gap_theme_extension.dart';

/// GAP tsikli tugagach qayta yoqish uchun to‘lov (hozircha sinov).
class PayGapReactivationSheet extends StatelessWidget {
  const PayGapReactivationSheet({super.key, required this.groupName});

  final String groupName;

  static Future<bool?> show(BuildContext context, {required String groupName}) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => PayGapReactivationSheet(groupName: groupName),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gap = context.gap;
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        8,
        24,
        24 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'GAPni qayta yoqish',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '"$groupName"',
            textAlign: TextAlign.center,
            style: TextStyle(color: gap.mutedText),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.primaryContainer.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  GapPricing.reactivationPriceLabel,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: cs.primary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Barcha ishtirokchilar bir marta pul olgach GAP to\'xtaydi. '
                  'Yangi jamg\'arma davrini boshlash uchun to\'lov.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'To\'lov tizimi tez orada ulanadi. Hozircha sinov rejimida tasdiqlash.',
            style: TextStyle(fontSize: 11, color: gap.mutedText, height: 1.35),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Qayta boshlash (to\'lov)'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Bekor qilish'),
          ),
        ],
      ),
    );
  }
}
