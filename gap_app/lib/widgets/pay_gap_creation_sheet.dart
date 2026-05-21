import 'package:flutter/material.dart';

import '../config/gap_pricing.dart';
import '../theme/gap_theme_extension.dart';

/// Qo‘shimcha GAP yaratish uchun to‘lov (hozircha mahalliy tasdiqlash).
class PayGapCreationSheet extends StatelessWidget {
  const PayGapCreationSheet({super.key});

  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const PayGapCreationSheet(),
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
            'Qo\'shimcha GAP yaratish',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.primaryContainer.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  GapPricing.extraGapPriceLabel,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: cs.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Bitta qo\'shimcha GAP uchun masul bo\'lish huquqi',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: gap.mutedText, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _BenefitRow(
            icon: Icons.check_circle_outline,
            text: 'Birinchi GAP har doim bepul',
          ),
          _BenefitRow(
            icon: Icons.shield_rounded,
            text: 'Yangi jamg\'armada to\'liq masul huquqi',
          ),
          _BenefitRow(
            icon: Icons.groups_rounded,
            text: 'Cheksiz a\'zo va davrlar',
          ),
          const SizedBox(height: 8),
          Text(
            'To\'lov tizimi tez orada ulanadi. Hozircha sinov rejimida tasdiqlash.',
            style: TextStyle(fontSize: 11, color: gap.mutedText, height: 1.35),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('To\'lovni tasdiqlash (sinov)'),
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

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: cs.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
