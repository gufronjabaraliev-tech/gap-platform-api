import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/gap_icons.dart';

/// Pastki navigatsiya — header rangida, tanlangan tabda doira fon.
class GapBottomNavBar extends StatelessWidget {
  const GapBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const _items = [
    _NavItem(Icons.dashboard_outlined, Icons.dashboard_rounded, 'Dashboard'),
    _NavItem(GapIcons.brandOutlined, GapIcons.brand, 'Jamg\'armalar'),
    _NavItem(Icons.forum_outlined, Icons.forum_rounded, 'Chat'),
    _NavItem(Icons.person_outline_rounded, Icons.person_rounded, 'Profil'),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? const Color(0xFF5EEAD4) : AppColors.primary;
    final surface = Theme.of(context).colorScheme.surface;

    return Material(
      color: surface,
      elevation: 8,
      shadowColor: Colors.black26,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(_items.length, (i) {
              final item = _items[i];
              final selected = i == selectedIndex;
              return Expanded(
                child: InkWell(
                  onTap: () => onSelected(i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: selected ? 44 : 36,
                        height: selected ? 44 : 36,
                        decoration: selected
                            ? BoxDecoration(
                                color: accent.withValues(alpha: 0.18),
                                shape: BoxShape.circle,
                              )
                            : null,
                        alignment: Alignment.center,
                        child: Icon(
                          selected ? item.selected : item.outlined,
                          size: selected ? 26 : 24,
                          color: accent,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w500,
                          color: accent,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.outlined, this.selected, this.label);
  final IconData outlined;
  final IconData selected;
  final String label;
}
