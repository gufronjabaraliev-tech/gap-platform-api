import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/groups_provider.dart';
import '../theme/gap_theme_extension.dart';
import 'gap_hero_header.dart';
import 'theme_toggle_button.dart';

class GroupHeader extends StatelessWidget {
  const GroupHeader({super.key, this.trailingActions});

  final List<Widget>? trailingActions;

  @override
  Widget build(BuildContext context) {
    final groups = context.watch<GroupsProvider>();
    final g = groups.activeGroup!;
    final isMasul = groups.isResponsibleActive;

    return GapHeroHeader(
      title: g.name,
      subtitle: '${g.currentGapRoundLabel} · ${g.cycleType.label}',
      leading: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        style: IconButton.styleFrom(
          backgroundColor: context.gap.glassOverlay,
          foregroundColor: Colors.white,
        ),
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      actions: [
        ...?trailingActions,
        const ThemeToggleButton(iconColor: Colors.white),
        const SizedBox(width: 4),
      ],
      bottom: Row(
        children: [
          GapHeroChip(icon: Icons.people_rounded, label: '${g.memberCount} a\'zo'),
          const SizedBox(width: 8),
          GapHeroChip(icon: Icons.vpn_key_rounded, label: g.inviteCode),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isMasul
                  ? context.gap.warning.withValues(alpha: 0.9)
                  : context.gap.glassOverlay,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Text(
              isMasul ? 'MASUL' : 'KUZATUVCHI',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
