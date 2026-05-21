import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/savings_group.dart';
import '../../providers/groups_provider.dart';
import '../../theme/gap_theme_extension.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/gap_card.dart';
import '../../widgets/fund_banner.dart';
import '../../widgets/gap_session_panel.dart' show openGapReactivationFlow, startGapSessionFromUi;
import '../../widgets/group_header.dart';
import '../../widgets/invite_share_sheet.dart';
import '../../widgets/gap_group_scroll_body.dart';
import '../../widgets/menu_card.dart';
import '../../widgets/new_cycle_setup_card.dart';
import 'group_settings_screen.dart';
import 'group_report_screen.dart';
import 'member_list_screen.dart';
import 'payment_screen.dart';
import 'schedule_screen.dart';
import 'set_amount_screen.dart';
import 'gap_calendar_screen.dart';
import 'group_chat_screen.dart';
import 'status_screen.dart';
import '../rates/bank_rates_screen.dart';

class GroupHomeScreen extends StatelessWidget {
  const GroupHomeScreen({super.key});

  Future<void> _openSchedule(BuildContext context) async {
    final g = context.read<GroupsProvider>().activeGroup!;
    if (g.memberCount < 2) {
      final goMembers = await showGapConfirmDialog(
        context,
        title: 'Avval a\'zolar qo\'shing',
        message:
            'Navbat yaratish uchun kamida 2 ta ishtirokchi kerak.\n\n'
            '«A\'zolar» tugmasiga o\'ting va ishtirokchilarni qo\'shing.',
        confirmLabel: 'A\'zolar bo\'limi',
        isDanger: false,
      );
      if (goMembers == true && context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MemberListScreen()),
        );
      }
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ScheduleScreen()),
    );
  }

  void _requireManagement(
    BuildContext context,
    SavingsGroup g,
    VoidCallback action,
  ) {
    if (g.isManagementUnlocked || g.isInNewCycleSetupPhase) {
      action();
      return;
    }
    showGapSnackBar(
      context,
      'Avval START tugmasini bosing',
      isError: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final groups = context.watch<GroupsProvider>();
    final g = groups.activeGroup;
    if (g == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final canEdit = groups.canEditActive;
    final managementOn = g.isManagementUnlocked;
    final setupPhase = g.isInNewCycleSetupPhase;
    final managementOrSetup = managementOn || setupPhase;
    final memberId = groups.activeMemberId;
    final myPos = g.schedulePositionForMember(memberId);

    final gap = context.gap;
    final cs = Theme.of(context).colorScheme;
    final menuColors = gap.menuColors;
    var colorIdx = 0;
    Color nextColor() => menuColors[colorIdx++ % menuColors.length];

    return Scaffold(
      body: GapGroupScrollBody(
        header: const GroupHeader(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
        children: [
                FundBanner(group: g, compact: true),
                if (g.needsCycleReactivation && groups.isResponsibleActive) ...[
                  const SizedBox(height: 12),
                  GapCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.emoji_events_rounded,
                                color: gap.warning, size: 28),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'GAP yakunlandi',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Barcha ishtirokchilar jamg\'arma oldi. '
                          'Yangi davr uchun tarif to\'lovi va qayta yoqish kerak.',
                          style: TextStyle(
                            color: gap.mutedText,
                            height: 1.4,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 14),
                        FilledButton.icon(
                          onPressed: () => openGapReactivationFlow(context),
                          icon: const Icon(Icons.restart_alt_rounded),
                          label: const Text('GAPni qayta yoqish (to\'lov)'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (setupPhase && groups.isResponsibleActive) ...[
                  const SizedBox(height: 12),
                  if (!g.canStartGapSession)
                    NewCycleSetupCard(
                      group: g,
                      onMembers: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MemberListScreen(),
                        ),
                      ),
                      onScheduleMode: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const GroupSettingsScreen(),
                        ),
                      ),
                      onNavbat: () => _openSchedule(context),
                    )
                  else ...[
                    const SizedBox(height: 4),
                    GapCard(
                      gradient: gap.primaryGradient,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.play_circle_fill_rounded,
                                  color: Colors.white),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Yangi GAPni boshlash',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (g.canCollectPayments) ...[
                            const SizedBox(height: 8),
                            Text(
                              '${g.currentPeriodLabel} — ${g.currentReceiverName}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 13,
                              ),
                            ),
                          ],
                          const SizedBox(height: 14),
                          FilledButton.icon(
                            onPressed: () => startGapSessionFromUi(context),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: cs.primary,
                              minimumSize: const Size(double.infinity, 48),
                            ),
                            icon: const Icon(Icons.play_arrow_rounded),
                            label: const Text('START'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ] else if (canEdit && g.canStartGapSession) ...[
                  const SizedBox(height: 12),
                  GapCard(
                    gradient: gap.primaryGradient,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.play_circle_fill_rounded,
                                color: Colors.white),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Keyingi GAPni boshlash',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (g.canCollectPayments)
                          Text(
                            '${g.currentPeriodLabel} — ${g.currentReceiverName}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 13,
                            ),
                          ),
                        const SizedBox(height: 14),
                        FilledButton.icon(
                          onPressed: () => startGapSessionFromUi(context),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: cs.primary,
                            minimumSize: const Size(double.infinity, 48),
                          ),
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: const Text('START'),
                        ),
                      ],
                    ),
                  ),
                ] else if (canEdit &&
                    g.canStartGapSession &&
                    g.nextGapDueDate == null) ...[
                  const SizedBox(height: 8),
                  GapCard(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const GapCalendarScreen(),
                      ),
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.event_rounded, color: cs.primary),
                      title: const Text('Keyingi GAP kuni'),
                      subtitle: const Text('Kalendarda belgilang'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                    ),
                  ),
                ],
                if (g.nextGapDueDate != null && !g.canStartGapSession)
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 4),
                    child: GapCard(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const GapCalendarScreen(),
                        ),
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.calendar_month_rounded,
                            color: cs.primary),
                        title: const Text('Keyingi GAP kuni'),
                        subtitle: Text(g.nextGapDueDateLabel!),
                        trailing: const Icon(Icons.chevron_right_rounded),
                      ),
                    ),
                  ),
                if (myPos != null && g.isScheduleConfigured)
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 4),
                    child: GapCard(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading:
                            Icon(Icons.timeline_rounded, color: cs.primary),
                        title: const Text('Sizning navbatingiz'),
                        subtitle: Text(
                          '${SavingsGroup.queueNumber(myPos)} — ${g.currentPeriodLabel}: ${g.currentReceiverName}',
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                GridView.count(
                  crossAxisCount: menuGridColumnCount(context),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 6,
                  padding: EdgeInsets.zero,
                  childAspectRatio: 0.8,
                  children: [
                    MenuCard(
                      icon: Icons.people_rounded,
                      label: 'A\'zolar',
                      color: nextColor(),
                      badge: canEdit ? null : '${g.memberCount}',
                      isAddBadge: canEdit,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MemberListScreen(),
                        ),
                      ),
                    ),
                    MenuCard(
                      icon: Icons.format_list_numbered_rounded,
                      label: 'Navbat',
                      color: nextColor(),
                      onTap: () => _openSchedule(context),
                    ),
                    if ((canEdit &&
                            (managementOn || g.canStartGapSession)) ||
                        (groups.isResponsibleActive && g.isClosed) ||
                        (!canEdit && !g.isClosed && g.gapSessionActive))
                      MenuCard(
                        icon: Icons.payment_rounded,
                        label: 'To\'lovlar',
                        color: nextColor(),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PaymentScreen(),
                          ),
                        ),
                      ),
                    MenuCard(
                      icon: Icons.calendar_month_rounded,
                      label: 'Kalendar',
                      color: nextColor(),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const GapCalendarScreen(),
                        ),
                      ),
                    ),
                    MenuCard(
                      icon: Icons.summarize_rounded,
                      label: 'Hisobot',
                      color: nextColor(),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const GroupReportScreen(),
                        ),
                      ),
                    ),
                    MenuCard(
                      icon: Icons.bar_chart_rounded,
                      label: 'Holat',
                      color: nextColor(),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const StatusScreen(),
                        ),
                      ),
                    ),
                    MenuCard(
                      icon: Icons.chat_rounded,
                      label: 'Chat',
                      color: nextColor(),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const GroupChatScreen(),
                        ),
                      ),
                    ),
                    if (canEdit)
                      MenuCard(
                        icon: Icons.qr_code_2_rounded,
                        label: 'Taklif',
                        color: nextColor(),
                        enabled: managementOrSetup,
                        onTap: () => _requireManagement(
                          context,
                          g,
                          () => InviteShareSheet.show(
                            context,
                            groupName: g.name,
                            inviteCode: g.inviteCode,
                          ),
                        ),
                      ),
                    if (canEdit)
                      MenuCard(
                        icon: Icons.tune_rounded,
                        label: 'Summa',
                        color: nextColor(),
                        enabled: managementOrSetup,
                        onTap: () => _requireManagement(
                          context,
                          g,
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SetAmountScreen(),
                            ),
                          ),
                        ),
                      ),
                    MenuCard(
                      icon: Icons.currency_exchange_rounded,
                      label: 'Bank kurslari',
                      color: nextColor(),
                      enabled: managementOn,
                      onTap: () => _requireManagement(
                        context,
                        g,
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const BankRatesScreen(),
                          ),
                        ),
                      ),
                    ),
                    if (groups.isResponsibleActive)
                      MenuCard(
                        icon: Icons.settings_rounded,
                        label: 'Sozlamalar',
                        color: nextColor(),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const GroupSettingsScreen(),
                          ),
                        ),
                      ),
                  ],
                ),
        ],
      ),
    );
  }
}
