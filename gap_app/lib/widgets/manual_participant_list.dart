import 'package:flutter/material.dart';

import '../models/savings_group.dart';
import '../theme/gap_theme_extension.dart';
import 'gap_sliding_text.dart';
import 'member_avatar.dart';

/// Ixtiyoriy navbat: barcha ishtirokchilar va pul oluvchini tanlash.
class ManualParticipantList extends StatelessWidget {
  const ManualParticipantList({
    super.key,
    required this.group,
    required this.myMemberId,
    required this.canSelect,
    this.onSelect,
    this.compact = false,
  });

  final SavingsGroup group;
  final String? myMemberId;
  final bool canSelect;
  final void Function(String memberId, String displayName)? onSelect;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final gap = context.gap;
    final cs = Theme.of(context).colorScheme;

    final memberIds = group.members.keys.toList()
      ..sort((a, b) {
        final aReceived = group.hasReceivedFund(a);
        final bReceived = group.hasReceivedFund(b);
        if (aReceived != bReceived) return aReceived ? 1 : -1;
        return group.displayNameFor(a).compareTo(group.displayNameFor(b));
      });

    if (memberIds.isEmpty) {
      return Text(
        'Ishtirokchilar yo\'q.',
        style: TextStyle(color: gap.mutedText),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!compact) ...[
          Row(
            children: [
              Icon(Icons.people_rounded, size: 22, color: cs.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Ishtirokchilar ro\'yxati',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (group.gapSessionActive)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    group.currentPeriodLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: cs.primary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
        ],
        if (_helperText() != null) ...[
          Text(
            _helperText()!,
            style: TextStyle(fontSize: 12, color: gap.mutedText, height: 1.35),
          ),
          SizedBox(height: compact ? 8 : 10),
        ] else
          SizedBox(height: compact ? 4 : 6),
        ...memberIds.map((id) => _memberTile(context, gap, cs, id)),
        if (canSelect && group.eligibleReceiverIds.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Barcha ishtirokchilar pul olgan.',
              style: TextStyle(color: gap.success, fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
  }

  String? _helperText() {
    if (canSelect) return null;
    if (group.activeReceiverId != null && !group.gapSessionActive) {
      return 'START bosing, keyin to\'lovlar.';
    }
    return null;
  }

  Widget _memberTile(
    BuildContext context,
    GapThemeExtension gap,
    ColorScheme cs,
    String id,
  ) {
    final m = group.members[id]!;
    final received = group.hasReceivedFund(id);
    final isCurrent = group.activeReceiverId == id;
    final isSelf = id == myMemberId;
    final selectable = canSelect && !received && !isCurrent;

    return Card(
      margin: EdgeInsets.only(bottom: compact ? 6 : 8),
      color: received
          ? cs.surfaceContainerHighest.withValues(alpha: 0.5)
          : isCurrent
              ? cs.primaryContainer.withValues(alpha: 0.35)
              : null,
      child: ListTile(
        enabled: selectable || isCurrent || received,
        onTap: selectable && onSelect != null
            ? () => onSelect!(id, m.displayName)
            : null,
        leading: MemberAvatar(
          displayName: m.displayName,
          member: m,
          phone: m.phone,
          linkedUserId: m.linkedUserId,
          radius: compact ? 20 : 24,
          backgroundColor: received
              ? gap.mutedText
              : isCurrent
                  ? cs.primary
                  : isSelf
                      ? gap.warning
                      : cs.primary,
        ),
        title: GapSlidingText(
          text: m.displayName,
          style: TextStyle(
            fontWeight: isCurrent || isSelf ? FontWeight.w700 : FontWeight.w500,
            color: received ? gap.mutedText : null,
            decoration: received ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: received
            ? Text(
                'Jamg\'arma olgan — tanlashdan tashqari',
                style: TextStyle(color: gap.mutedText, fontSize: 12),
              )
            : isCurrent
                ? Text(
                    'Joriy davr pul oluvchisi',
                    style: TextStyle(color: cs.primary, fontSize: 12),
                  )
                : selectable
                    ? Text(
                        'Tanlash uchun bosing',
                        style: TextStyle(
                          color: cs.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    : null,
        trailing: received
            ? Icon(Icons.check_circle, color: gap.success, size: 22)
            : isCurrent
                ? Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: cs.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'JORIY',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  )
                : selectable
                    ? Icon(Icons.touch_app_rounded, color: cs.primary)
                    : null,
      ),
    );
  }
}
