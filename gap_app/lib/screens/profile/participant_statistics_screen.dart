import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_currency.dart';
import '../../models/participant_dashboard.dart';
import '../../theme/gap_icons.dart';
import '../../models/savings_group.dart';
import '../../providers/auth_provider.dart';
import '../../providers/groups_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/money_format.dart';
import '../../widgets/gap_card.dart';
import '../../widgets/gap_hero_header.dart';
import '../../widgets/theme_toggle_button.dart';
import '../group/group_home_screen.dart';
import '../group/group_report_screen.dart';
import '../group/participant_group_screen.dart';

class ParticipantStatisticsScreen extends StatefulWidget {
  const ParticipantStatisticsScreen({
    super.key,
    this.embeddedInShell = false,
  });

  /// Asosiy qobiqdagi Dashboard bo'limi.
  final bool embeddedInShell;

  @override
  State<ParticipantStatisticsScreen> createState() =>
      _ParticipantStatisticsScreenState();
}

class _ParticipantStatisticsScreenState
    extends State<ParticipantStatisticsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>().user;
    if (auth == null) return;
    await context.read<GroupsProvider>().loadMyGroups(
          auth.id,
          phone: auth.phone,
        );
  }

  Future<void> _openGap(ParticipantGapRow row) async {
    final auth = context.read<AuthProvider>().user!;
    final groups = context.read<GroupsProvider>();
    await groups.selectGroup(row.group.id, auth.id, phone: auth.phone);
    if (!mounted) return;

    if (row.isClosed) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const GroupReportScreen()),
      );
    } else {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => row.isResponsible
              ? const GroupHomeScreen()
              : const ParticipantGroupScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final groups = context.watch<GroupsProvider>();
    final user = context.watch<AuthProvider>().user;
    if (user == null) {
      return const SizedBox.shrink();
    }
    final gap = context.gap;
    final cs = Theme.of(context).colorScheme;

    final dashboard = ParticipantDashboard.fromMemberGroups(
      groups: groups.myGroups.map((e) => e.group).toList(),
      memberIds: groups.myGroups.map((e) => e.memberId).toList(),
      isResponsibleFlags:
          groups.myGroups.map((e) => e.isResponsible).toList(),
    );

    return Scaffold(
      body: Column(
        children: [
          GapHeroHeader(
            title: widget.embeddedInShell ? 'Dashboard' : 'Statistika',
            subtitle: user.name,
            leading: widget.embeddedInShell
                ? null
                : IconButton(
                    onPressed: () => Navigator.pop(context),
                    style: IconButton.styleFrom(
                      backgroundColor: gap.glassOverlay,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
            actions: widget.embeddedInShell
                ? const [ThemeToggleButton(iconColor: Colors.white)]
                : const [],
          ),
          Expanded(
            child: groups.isLoading && groups.myGroups.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      children: [
                        if (dashboard.gapCount == 0)
                          _EmptyStats(gap: gap)
                        else ...[
                          _OverviewGrid(dashboard: dashboard, gap: gap, cs: cs),
                          const SizedBox(height: 16),
                          _DashboardMoneyBlock(
                            title: 'Jami to\'lagan',
                            icon: Icons.payments_rounded,
                            totals: dashboard.totalPaidByCurrency,
                            color: cs.primary,
                            gap: gap,
                            emptyHint: 'Hali hech qaysi GAPga to\'lov qilmagansiz',
                            rows: dashboard.gapsWithPayments
                                .map(
                                  (row) => _GapMoneyRow(
                                    groupName: row.groupName,
                                    amountText: row.paidDisplayText,
                                    subtitle: row.statusLabel,
                                    onTap: () => _openGap(row),
                                  ),
                                )
                                .toList(),
                          ),
                          const SizedBox(height: 12),
                          _DashboardMoneyBlock(
                            title: 'Joriy davr qarzi',
                            icon: Icons.warning_amber_rounded,
                            totals: dashboard.currentPeriodDebtByCurrency,
                            color: gap.warning,
                            gap: gap,
                            emptyHint: 'Joriy davrda to\'lanmagan qarz yo\'q',
                            rows: dashboard.gapsWithCurrentDebt
                                .map(
                                  (row) => _GapMoneyRow(
                                    groupName: row.groupName,
                                    amountText: row.currentPeriodDebtDisplayText,
                                    subtitle: row.group.currentPeriodLabel,
                                    onTap: () => _openGap(row),
                                  ),
                                )
                                .toList(),
                          ),
                          const SizedBox(height: 12),
                          _DashboardMoneyBlock(
                            title: 'Umumiy qarzdorlik',
                            icon: GapIcons.paymentsOutlined,
                            totals: dashboard.totalDebtByCurrency,
                            color: gap.danger,
                            gap: gap,
                            emptyHint: 'Qolgan qarz yo\'q',
                            rows: dashboard.gapsWithTotalDebt
                                .map(
                                  (row) => _GapMoneyRow(
                                    groupName: row.groupName,
                                    amountText: row.totalDebtDisplayText,
                                    subtitle: row.summary.hasReceived
                                        ? 'Jamg\'arma olgansiz — qolgan to\'lovlar'
                                        : row.statusLabel,
                                    onTap: () => _openGap(row),
                                  ),
                                )
                                .toList(),
                          ),
                          const SizedBox(height: 12),
                          _DashboardMoneyBlock(
                            title: 'Kutilayotgan jamg\'arma',
                            icon: Icons.schedule_rounded,
                            totals: dashboard.totalExpectedByCurrency,
                            color: AppColors.teal,
                            gap: gap,
                            emptyHint: 'Kutilayotgan jamg\'arma yo\'q',
                            rows: dashboard.gapsWithExpected
                                .map(
                                  (row) => _GapMoneyRow(
                                    groupName: row.groupName,
                                    amountText: row.expectedDisplayText!,
                                    subtitle: row.expectedDetailLabel,
                                    onTap: () => _openGap(row),
                                  ),
                                )
                                .toList(),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Barcha GAPlar',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 10),
                          ...dashboard.gaps.map(
                            (row) => _GapStatCard(
                              row: row,
                              gap: gap,
                              cs: cs,
                              onTap: () => _openGap(row),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _OverviewGrid extends StatelessWidget {
  const _OverviewGrid({
    required this.dashboard,
    required this.gap,
    required this.cs,
  });

  final ParticipantDashboard dashboard;
  final GapThemeExtension gap;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.45,
      children: [
        _StatTile(
          icon: Icons.groups_rounded,
          label: 'Jami GAP',
          value: '${dashboard.gapCount}',
          color: cs.primary,
          gap: gap,
        ),
        _StatTile(
          icon: Icons.play_circle_rounded,
          label: 'Faol',
          value: '${dashboard.activeCount}',
          color: AppColors.teal,
          gap: gap,
        ),
        _StatTile(
          icon: Icons.archive_rounded,
          label: 'Yopilgan',
          value: '${dashboard.closedCount}',
          color: gap.mutedText,
          gap: gap,
        ),
        _StatTile(
          icon: Icons.star_rounded,
          label: 'Hozir olmoqda',
          value: '${dashboard.receivingNowCount}',
          color: gap.warning,
          gap: gap,
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.gap,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final GapThemeExtension gap;

  @override
  Widget build(BuildContext context) {
    return GapCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 26),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: color,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: gap.mutedText),
          ),
        ],
      ),
    );
  }
}

class _GapMoneyRow {
  const _GapMoneyRow({
    required this.groupName,
    required this.amountText,
    this.subtitle,
    this.onTap,
  });

  final String groupName;
  final String amountText;
  final String? subtitle;
  final VoidCallback? onTap;
}

class _DashboardMoneyBlock extends StatelessWidget {
  const _DashboardMoneyBlock({
    required this.title,
    required this.icon,
    required this.totals,
    required this.color,
    required this.gap,
    required this.emptyHint,
    required this.rows,
  });

  final String title;
  final IconData icon;
  final Map<AppCurrency, int> totals;
  final Color color;
  final GapThemeExtension gap;
  final String emptyHint;
  final List<_GapMoneyRow> rows;

  @override
  Widget build(BuildContext context) {
    final hasTotals = totals.isNotEmpty;
    final hasRows = rows.isNotEmpty;

    return GapCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (hasTotals) ...[
            Text(
              'Jami',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: gap.mutedText,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 4),
            ...totals.entries.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  formatMoney(e.value, e.key),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ] else
            Text(
              emptyHint,
              style: TextStyle(fontSize: 13, color: gap.mutedText, height: 1.35),
            ),
          if (hasRows) ...[
            const SizedBox(height: 12),
            Divider(height: 1, color: color.withValues(alpha: 0.2)),
            const SizedBox(height: 8),
            Text(
              'GAP bo\'yicha',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: gap.mutedText,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 6),
            ...rows.map(
              (row) => _GapMoneyBreakdownTile(row: row, color: color, gap: gap),
            ),
          ],
        ],
      ),
    );
  }
}

class _GapMoneyBreakdownTile extends StatelessWidget {
  const _GapMoneyBreakdownTile({
    required this.row,
    required this.color,
    required this.gap,
  });

  final _GapMoneyRow row;
  final Color color;
  final GapThemeExtension gap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: row.onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.groupName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    if (row.subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        row.subtitle!,
                        style: TextStyle(fontSize: 11, color: gap.mutedText),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                row.amountText,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: color,
                ),
              ),
              if (row.onTap != null) ...[
                const SizedBox(width: 2),
                Icon(Icons.chevron_right_rounded, size: 20, color: gap.mutedText),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _GapStatCard extends StatelessWidget {
  const _GapStatCard({
    required this.row,
    required this.gap,
    required this.cs,
    required this.onTap,
  });

  final ParticipantGapRow row;
  final GapThemeExtension gap;
  final ColorScheme cs;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final g = row.group;
    final s = row.summary;
    final statusColor = _statusColor(row.statusKind, gap, cs);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GapCard(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    row.groupName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: gap.mutedText),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _Chip(
                  label: row.statusLabel,
                  color: statusColor,
                ),
                if (row.isResponsible)
                  _Chip(label: 'Masul', color: gap.warning)
                else
                  _Chip(label: 'Ishtirokchi', color: cs.primary),
                _Chip(
                  label: g.scheduleMode.label,
                  color: gap.mutedText,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _DetailLine(
              icon: Icons.payments_rounded,
              label: 'To\'lagan',
              value: s.totalPaidRaw ??
                  formatMoney(
                    g.fromSettlementAmount(
                      s.totalPaidSettlement,
                      s.paymentCurrency,
                    ),
                    s.paymentCurrency,
                  ),
              gap: gap,
            ),
            if (row.currentPeriodDebtSettlement > 0) ...[
              const SizedBox(height: 6),
              _DetailLine(
                icon: Icons.error_outline_rounded,
                label: 'Joriy davr qarzi',
                value: formatMoney(
                  row.currentPeriodDebtSettlement,
                  g.settlementCurrency,
                ),
                valueColor: gap.warning,
                gap: gap,
              ),
            ],
            if (s.showRemaining && s.remainingToPaySettlement > 0) ...[
              const SizedBox(height: 6),
              _DetailLine(
                icon: GapIcons.paymentsOutlined,
                label: 'Qolgan qarz (olgansiz)',
                value: formatMoney(
                  g.fromSettlementAmount(
                    s.remainingToPaySettlement,
                    s.paymentCurrency,
                  ),
                  s.paymentCurrency,
                ),
                valueColor: gap.danger,
                gap: gap,
              ),
            ],
            if (s.showReceivingNow) ...[
              const SizedBox(height: 6),
              _DetailLine(
                icon: Icons.trending_up_rounded,
                label: 'Hozir oladi',
                value: formatMoney(
                  g.expectedTotalForCurrentReceiver,
                  g.currentReceiverReceiveCurrency,
                ),
                valueColor: AppColors.teal,
                gap: gap,
              ),
            ] else if (s.showFuture) ...[
              const SizedBox(height: 6),
              _DetailLine(
                icon: Icons.hourglass_top_rounded,
                label: s.schedulePosition != null
                    ? 'Kutilmoqda (${SavingsGroup.queueNumber(s.schedulePosition!)})'
                    : 'Kutilayotgan jamg\'arma',
                value: formatMoney(
                  g.fromSettlementAmount(
                    s.futureReceiveSettlement,
                    s.receiveCurrency,
                  ),
                  s.receiveCurrency,
                ),
                valueColor: AppColors.secondaryDeep,
                gap: gap,
              ),
            ],
            if (!g.isClosed && g.gapSessionActive && g.canCollectPayments) ...[
              const SizedBox(height: 8),
              Text(
                'Joriy oluvchi: ${g.currentReceiverName}',
                style: TextStyle(fontSize: 12, color: gap.mutedText),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _statusColor(
    ParticipantGapStatusKind kind,
    GapThemeExtension gap,
    ColorScheme cs,
  ) {
    return switch (kind) {
      ParticipantGapStatusKind.closed => gap.mutedText,
      ParticipantGapStatusKind.receivingNow => gap.warning,
      ParticipantGapStatusKind.received => gap.success,
      ParticipantGapStatusKind.waitingTurn => AppColors.secondaryDeep,
      ParticipantGapStatusKind.active => cs.primary,
      ParticipantGapStatusKind.idle => gap.mutedText,
    };
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({
    required this.icon,
    required this.label,
    required this.value,
    required this.gap,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final GapThemeExtension gap;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: gap.mutedText),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 11, color: gap.mutedText)),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: valueColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _EmptyStats extends StatelessWidget {
  const _EmptyStats({required this.gap});

  final GapThemeExtension gap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 48),
      child: Column(
        children: [
          Icon(Icons.analytics_outlined, size: 64, color: gap.mutedText),
          const SizedBox(height: 16),
          Text(
            'Hali GAP yo\'q',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Jamg\'armaga qo\'shilgach statistika shu yerda ko\'rinadi.',
            textAlign: TextAlign.center,
            style: TextStyle(color: gap.mutedText, height: 1.4),
          ),
        ],
      ),
    );
  }
}
