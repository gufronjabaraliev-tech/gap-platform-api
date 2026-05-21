import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/gap_theme_extension.dart';

/// Android asosiy ekrandagi ilovalar kabi: yumaloq ikonka qutisi + ostida nom.
class MenuCard extends StatefulWidget {
  const MenuCard({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.badge,
    this.isAddBadge = false,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final String? badge;
  /// `badge` uchun yashil «+» (a'zo qo'shish).
  final bool isAddBadge;
  final bool enabled;

  @override
  State<MenuCard> createState() => _MenuCardState();
}

class _MenuCardState extends State<MenuCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final gap = context.gap;
    final cs = Theme.of(context).colorScheme;

    final opacity = widget.enabled ? 1.0 : 0.42;

    return GestureDetector(
      onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: widget.enabled ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: widget.enabled ? () => setState(() => _pressed = false) : null,
      onTap: widget.enabled ? widget.onTap : null,
      child: AnimatedScale(
        scale: widget.enabled && _pressed ? 0.92 : 1,
        duration: const Duration(milliseconds: 110),
        child: Opacity(
          opacity: opacity,
          child: LayoutBuilder(
          builder: (context, constraints) {
            final cellW = constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : 72.0;
            final iconSide = (cellW * 0.72).clamp(40.0, 56.0);
            final radius = iconSide * 0.22;

            return Stack(
              clipBehavior: Clip.none,
              fit: StackFit.expand,
              alignment: Alignment.topCenter,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.center,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: cellW),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: iconSide,
                            height: iconSide,
                            child: Stack(
                              clipBehavior: Clip.none,
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: iconSide,
                                  height: iconSide,
                                  decoration: BoxDecoration(
                                    color: widget.color.withValues(alpha: 0.22),
                                    borderRadius: BorderRadius.circular(radius),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.06),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  widget.icon,
                                  color: widget.color,
                                  size: iconSide * 0.48,
                                ),
                                if (widget.isAddBadge)
                                  Positioned(
                                    top: -2,
                                    right: -2,
                                    child: Container(
                                      width: iconSide * 0.3,
                                      height: iconSide * 0.3,
                                      decoration: BoxDecoration(
                                        color: cs.primary,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: cs.surface,
                                          width: 2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.15),
                                            blurRadius: 3,
                                            offset: const Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        Icons.add_rounded,
                                        color: Colors.white,
                                        size: iconSide * 0.2,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          SizedBox(height: iconSide * 0.14),
                          Text(
                            widget.label,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                              height: 1.12,
                              letterSpacing: -0.1,
                              color: cs.onSurface.withValues(alpha: 0.92),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (widget.badge != null && !widget.isAddBadge)
                  Positioned(
                    top: 0,
                    right: math.max(0, (cellW - iconSide) / 2 - 4),
                    child: Container(
                      constraints: BoxConstraints(
                        minWidth: widget.isAddBadge ? 16 : 18,
                        minHeight: widget.isAddBadge ? 16 : 18,
                      ),
                      padding: widget.isAddBadge
                          ? EdgeInsets.zero
                          : const EdgeInsets.symmetric(horizontal: 5),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: widget.isAddBadge ? cs.primary : gap.danger,
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(
                          color: cs.surface,
                          width: 2,
                        ),
                      ),
                      child: widget.isAddBadge
                          ? const Icon(
                              Icons.add_rounded,
                              color: Colors.white,
                              size: 12,
                            )
                          : Text(
                              widget.badge!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
              ],
            );
          },
        ),
        ),
      ),
    );
  }
}

/// Telefon uchun 4 ustun (Android launcher odatda shunday), planshetda 5–6.
int menuGridColumnCount(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  if (width >= 720) return 6;
  if (width >= 520) return 5;
  return 4;
}
