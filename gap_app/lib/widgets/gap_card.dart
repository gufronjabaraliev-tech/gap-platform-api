import 'package:flutter/material.dart';

import '../theme/gap_theme_extension.dart';

class GapCard extends StatelessWidget {
  const GapCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.gradient,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final gap = context.gap;
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: gradient == null ? cs.surface : null,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            gradient: gradient,
            color: gradient == null ? cs.surface : null,
            borderRadius: BorderRadius.circular(20),
            boxShadow: gap.cardShadow,
            border: Border.all(
              color: cs.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class GapInfoBanner extends StatelessWidget {
  const GapInfoBanner({
    super.key,
    required this.icon,
    required this.message,
    this.tone = GapBannerTone.info,
  });

  final IconData icon;
  final String message;
  final GapBannerTone tone;

  @override
  Widget build(BuildContext context) {
    final gap = context.gap;
    final (bg, fg, border) = switch (tone) {
      GapBannerTone.info => (
          Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          Theme.of(context).colorScheme.primary,
          Theme.of(context).colorScheme.primary.withValues(alpha: 0.25),
        ),
      GapBannerTone.success => (
          gap.success.withValues(alpha: 0.12),
          gap.success,
          gap.success.withValues(alpha: 0.3),
        ),
      GapBannerTone.warning => (
          gap.warning.withValues(alpha: 0.12),
          gap.warning,
          gap.warning.withValues(alpha: 0.3),
        ),
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Icon(icon, color: fg, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: fg, height: 1.4, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

enum GapBannerTone { info, success, warning }
