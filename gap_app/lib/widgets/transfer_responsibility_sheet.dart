import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/group_member.dart';
import '../providers/auth_provider.dart';
import '../providers/groups_provider.dart';
import '../theme/gap_theme_extension.dart';
import '../utils/pin_util.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/gap_sliding_text.dart';
import '../widgets/member_avatar.dart';

/// Masul: a'zolardan tanlaydi → tasdiqlaydi → oddiy ishtirokchiga aylanadi.
Future<bool> showTransferResponsibilitySheet(BuildContext context) async {
  final groups = context.read<GroupsProvider>();
  final g = groups.activeGroup!;

  final members = g.members.entries
      .where((e) => !g.isResponsibleMember(e.key))
      .toList()
    ..sort((a, b) => a.value.displayName.compareTo(b.value.displayName));

  if (members.isEmpty) {
    showGapSnackBar(
      context,
      'Topshirish uchun boshqa a\'zo kerak',
      isError: true,
    );
    return false;
  }

  final eligible = members.where((e) => e.value.isRegistered).toList();
  if (eligible.isEmpty) {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Topshirib bo\'lmaydi'),
        content: const Text(
          'Masullikni faqat ilovaga kirgan a\'zoga topshirish mumkin.\n\n'
          'Boshqa ishtirokchi avval taklif kod bilan qo\'shilishi yoki '
          'telefoni orqali bog\'lanishi kerak.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tushundim'),
          ),
        ],
      ),
    );
    return false;
  }

  final picked = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetCtx) {
      final gap = sheetCtx.gap;
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Text(
                'Masullikni topshirish',
                style: Theme.of(sheetCtx).textTheme.titleLarge,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text(
                '${g.name} — yangi masulni tanlang',
                style: TextStyle(fontSize: 13, color: gap.mutedText, height: 1.35),
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                children: [
                  for (final e in members)
                    _MemberPickTile(
                      entry: e,
                      gap: gap,
                      enabled: e.value.isRegistered,
                      onPick: e.value.isRegistered
                          ? () => Navigator.pop(sheetCtx, e.key)
                          : null,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );

  if (picked == null || !context.mounted) return false;

  final name = g.displayNameFor(picked);
  final ok = await showGapConfirmDialog(
    context,
    title: 'Masullikni topshirish',
    message:
        '$name yangi masul bo\'ladi.\n\n'
        'Siz oddiy ishtirokchi bo\'lib qolasiz — bu GAPda boshqaruv huquqi yo\'qoladi.',
    confirmLabel: 'Topshirish',
    isDanger: true,
  );
  if (ok != true || !context.mounted) return false;

  final auth = context.read<AuthProvider>().user!;
  final err = await groups.transferResponsibility(
    picked,
    actingUserId: auth.id,
    phone: auth.phone,
  );
  if (!context.mounted) return false;
  if (err != null) {
    showGapSnackBar(context, err, isError: true);
    return false;
  }

  showGapSnackBar(context, 'Masullik $name ga topshirildi');
  return true;
}

class _MemberPickTile extends StatelessWidget {
  const _MemberPickTile({
    required this.entry,
    required this.gap,
    required this.enabled,
    this.onPick,
  });

  final MapEntry<String, GroupMember> entry;
  final GapThemeExtension gap;
  final bool enabled;
  final VoidCallback? onPick;

  @override
  Widget build(BuildContext context) {
    final m = entry.value;
    return ListTile(
      enabled: enabled,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: MemberAvatar(
        displayName: m.displayName,
        member: m,
        phone: m.phone,
        linkedUserId: m.linkedUserId,
        radius: 22,
      ),
      title: GapSlidingText(text: m.displayName),
      subtitle: Text(
        enabled
            ? (m.phone != null
                ? formatPhoneDisplay(m.phone!)
                : 'Ilovaga kirgan')
            : 'Avval ilovaga kirishi kerak',
        style: TextStyle(fontSize: 12, color: gap.mutedText),
      ),
      trailing: enabled
          ? Icon(Icons.chevron_right_rounded, color: gap.mutedText)
          : Icon(Icons.lock_outline_rounded, size: 20, color: gap.mutedText),
      onTap: onPick,
    );
  }
}
