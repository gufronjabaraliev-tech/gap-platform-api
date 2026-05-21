import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/savings_group.dart';
import '../../providers/auth_provider.dart';
import '../../providers/groups_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/money_format.dart';
import '../../utils/pin_util.dart';
import '../../config/gap_pricing.dart';
import '../../widgets/gap_card.dart';
import '../../widgets/gap_sliding_text.dart';
import '../../widgets/gap_hero_header.dart';
import '../../utils/gap_navigation.dart';
import '../../utils/route_observer.dart';
import '../../widgets/gap_session_panel.dart' show openGapReactivationFlow;
import '../../widgets/remote_ad_banner.dart';
import '../../widgets/theme_toggle_button.dart';
import '../group/group_home_screen.dart';
import '../group/group_report_screen.dart';
import '../group/participant_group_screen.dart';
import '../profile/profile_screen.dart';
import 'create_group_screen.dart';
import 'join_group_screen.dart';

class MyGroupsScreen extends StatefulWidget {
  const MyGroupsScreen({super.key, this.embeddedInShell = false});

  /// Asosiy qobiqdagi Jamg'armalar bo'limi.
  final bool embeddedInShell;

  @override
  State<MyGroupsScreen> createState() => _MyGroupsScreenState();
}

enum _GroupsListTab { boshqaruv, ishtirok }

class _MyGroupsScreenState extends State<MyGroupsScreen> with RouteAware {
  _GroupsListTab _tab = _GroupsListTab.boshqaruv;
  late final PageController _tabPageController;

  @override
  void initState() {
    super.initState();
    _tabPageController = PageController(initialPage: _tab.index);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.embeddedInShell) return;
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      gapRouteObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    _tabPageController.dispose();
    if (!widget.embeddedInShell) {
      gapRouteObserver.unsubscribe(this);
    }
    super.dispose();
  }

  void _selectTab(_GroupsListTab tab, {bool animate = true}) {
    if (_tab == tab) return;
    setState(() => _tab = tab);
    if (!_tabPageController.hasClients) return;
    if (animate) {
      _tabPageController.animateToPage(
        tab.index,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    } else {
      _tabPageController.jumpToPage(tab.index);
    }
  }

  @override
  void didPopNext() {
    _load();
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    if (auth.user == null) return;
    final groups = context.read<GroupsProvider>();
    await groups.loadMyGroups(
      auth.user!.id,
      phone: auth.user!.phone,
    );
    if (!mounted) return;
    if (!mounted) return;
    final nextTab = groups.responsibleGroups.isNotEmpty
        ? _GroupsListTab.boshqaruv
        : groups.participantGroups.isNotEmpty
            ? _GroupsListTab.ishtirok
            : _tab;
    _selectTab(nextTab, animate: false);
  }

  Future<void> _openGroup(GroupListItem item) async {
    final auth = context.read<AuthProvider>().user!;
    final groups = context.read<GroupsProvider>();
    await groups.selectGroup(item.group.id, auth.id, phone: auth.phone);
    if (!mounted) return;
    if (item.group.isClosed) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const GroupReportScreen()),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => item.isResponsible
            ? const GroupHomeScreen()
            : const ParticipantGroupScreen(),
      ),
    );
  }

  Future<void> _reactivateClosedGroup(GroupListItem item) async {
    if (!item.isResponsible) return;
    final auth = context.read<AuthProvider>().user!;
    final groups = context.read<GroupsProvider>();
    await groups.selectGroup(item.group.id, auth.id, phone: auth.phone);
    if (!mounted) return;

    await openGapReactivationFlow(context);
    if (!mounted) return;

    await _load();
    if (!mounted) return;

    if (groups.activeGroup != null && !groups.activeGroup!.isClosed && mounted) {
      navigateToGroupHomeCleared(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final groups = context.watch<GroupsProvider>();
    final user = auth.user;
    if (user == null) {
      return const SizedBox.shrink();
    }
    final gap = context.gap;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: Column(
        children: [
          GapHeroHeader(
            title: 'Jamg\'armalar',
            subtitle: '${user.name} · ${formatPhoneDisplay(user.phone)}',
            actions: [
              if (!widget.embeddedInShell)
                IconButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: gap.glassOverlay,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.person_rounded),
                ),
              const ThemeToggleButton(iconColor: Colors.white),
            ],
          ),
          if (!groups.isLoading && groups.myGroups.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
              child: SegmentedButton<_GroupsListTab>(
                segments: [
                  ButtonSegment(
                    value: _GroupsListTab.boshqaruv,
                    label: Text('Boshqaruv (${groups.responsibleGroups.length})'),
                    icon: const Icon(Icons.shield_rounded, size: 18),
                  ),
                  ButtonSegment(
                    value: _GroupsListTab.ishtirok,
                    label: Text('Ishtirok (${groups.participantGroups.length})'),
                    icon: const Icon(Icons.groups_rounded, size: 18),
                  ),
                ],
                selected: {_tab},
                onSelectionChanged: (selected) => _selectTab(selected.first),
              ),
            ),
          Expanded(
            child: groups.isLoading
                ? const Center(child: CircularProgressIndicator())
                : groups.myGroups.isEmpty
                    ? _EmptyGroups(
                        onCreate: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CreateGroupScreen(),
                          ),
                        ).then((_) => _load()),
                        onJoin: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const JoinGroupScreen(),
                          ),
                        ).then((_) => _load()),
                      )
                    : PageView(
                        controller: _tabPageController,
                        onPageChanged: (i) => setState(
                          () => _tab = _GroupsListTab.values[i],
                        ),
                        children: [
                          _GroupsTabPage(
                            active: groups.responsibleGroups,
                            closed: groups.closedGroups
                                .where((i) => i.isResponsible)
                                .toList(),
                            emptyTitle: 'Boshqaradigan GAP yo\'q',
                            emptyHint:
                                'Yangi jamg\'arma yarating yoki Ishtirok sahifasiga suring',
                            gap: gap,
                            cs: cs,
                            onRefresh: _load,
                            onOpen: _openGroup,
                            onReactivate: _reactivateClosedGroup,
                          ),
                          _GroupsTabPage(
                            active: groups.participantGroups,
                            closed: groups.closedGroups
                                .where((i) => !i.isResponsible)
                                .toList(),
                            emptyTitle: 'Ishtirokchi GAP yo\'q',
                            emptyHint:
                                'Taklif kodi bilan qo\'shiling yoki Boshqaruv sahifasiga suring',
                            gap: gap,
                            cs: cs,
                            onRefresh: _load,
                            onOpen: _openGroup,
                          ),
                        ],
                      ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Expanded(
              child: FloatingActionButton.extended(
                heroTag: 'join',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const JoinGroupScreen()),
                ).then((_) => _load()),
                backgroundColor: AppColors.teal,
                extendedPadding: const EdgeInsets.symmetric(horizontal: 12),
                extendedIconLabelSpacing: 6,
                icon: const Icon(Icons.group_add_rounded, size: 20),
                label: const Text(
                  'Qo\'shilish',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FloatingActionButton.extended(
                heroTag: 'create',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
                ).then((_) => _load()),
                extendedPadding: const EdgeInsets.symmetric(horizontal: 12),
                extendedIconLabelSpacing: 6,
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text(
                  'Yangi',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupsTabPage extends StatelessWidget {
  const _GroupsTabPage({
    required this.active,
    required this.closed,
    required this.emptyTitle,
    required this.emptyHint,
    required this.gap,
    required this.cs,
    required this.onRefresh,
    required this.onOpen,
    this.onReactivate,
  });

  final List<GroupListItem> active;
  final List<GroupListItem> closed;
  final String emptyTitle;
  final String emptyHint;
  final GapThemeExtension gap;
  final ColorScheme cs;
  final Future<void> Function() onRefresh;
  final Future<void> Function(GroupListItem item) onOpen;
  final Future<void> Function(GroupListItem item)? onReactivate;

  @override
  Widget build(BuildContext context) {
    if (active.isEmpty && closed.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.sizeOf(context).height * 0.12),
            Icon(
              Icons.inbox_rounded,
              size: 56,
              color: cs.primary.withValues(alpha: 0.35),
            ),
            const SizedBox(height: 16),
            Text(
              emptyTitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                emptyHint,
                textAlign: TextAlign.center,
                style: TextStyle(color: gap.mutedText, height: 1.45),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          const RemoteAdBanner(),
          ...active.map(
            (item) => _FundTile(
              item: item,
              gap: gap,
              cs: cs,
              onTap: () => onOpen(item),
            ),
          ),
          if (closed.isNotEmpty) ...[
            if (active.isNotEmpty) const SizedBox(height: 12),
            _SectionTitle(
              icon: Icons.archive_rounded,
              title: 'Yopilgan',
              color: gap.mutedText,
            ),
            ...closed.map(
              (item) => _ClosedFundTile(
                item: item,
                gap: gap,
                cs: cs,
                onTap: () => onOpen(item),
                onReactivate: onReactivate != null && item.isResponsible
                    ? () => onReactivate!(item)
                    : null,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.icon,
    required this.title,
    required this.color,
  });

  final IconData icon;
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _FundTile extends StatelessWidget {
  const _FundTile({
    required this.item,
    required this.gap,
    required this.cs,
    required this.onTap,
  });

  final GroupListItem item;
  final GapThemeExtension gap;
  final ColorScheme cs;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final g = item.group;
    final pos = item.mySchedulePosition;
    final s = item.mySummary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GapCard(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: item.isResponsible
                          ? [
                              AppColors.secondary,
                              AppColors.secondaryDeep,
                            ]
                          : [cs.primary, cs.secondary],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    item.isResponsible
                        ? Icons.shield_rounded
                        : Icons.visibility_rounded,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GapSlidingText(
                        text: g.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        '${g.cycleType.label} · ${formatMoney(g.periodAmount, g.settlementCurrency)}',
                        style: TextStyle(color: gap.mutedText, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: gap.mutedText),
              ],
            ),
            const SizedBox(height: 12),
            _StatRow(
              label: 'Siz to\'lagansiz',
              value: s.totalPaidRaw ??
                  formatMoney(
                    g.fromSettlementAmount(
                      s.totalPaidSettlement,
                      s.paymentCurrency,
                    ),
                    s.paymentCurrency,
                  ),
              valueStyle: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: cs.primary,
              ),
              gap: gap,
            ),
            if (s.showRemaining) ...[
              const SizedBox(height: 8),
              _StatRow(
                label: 'Qolgan to\'lov (olgansiz)',
                value: formatMoney(
                  g.fromSettlementAmount(
                    s.remainingDisplay,
                    s.paymentCurrency,
                  ),
                  s.paymentCurrency,
                ),
                valueStyle: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: gap.warning,
                ),
                gap: gap,
              ),
            ],
            if (s.showReceivingNow) ...[
              const SizedBox(height: 8),
              _StatRow(
                label: 'Hozir sizning navbatingiz',
                value: formatMoney(
                  g.fromSettlementAmount(
                    g.expectedTotal,
                    s.receiveCurrency,
                  ),
                  s.receiveCurrency,
                ),
                valueStyle: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.teal,
                ),
                gap: gap,
              ),
            ] else if (s.showFuture) ...[
              const SizedBox(height: 8),
              _StatRow(
                label: pos != null
                    ? 'Kutayotgan (navbat ${SavingsGroup.queueNumber(pos)})'
                    : 'Kutayotgan jamg\'arma',
                value: formatMoney(
                  g.fromSettlementAmount(
                    s.futureReceiveDisplay,
                    s.receiveCurrency,
                  ),
                  s.receiveCurrency,
                ),
                valueStyle: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondaryDeep,
                ),
                gap: gap,
              ),
            ],
            if (item.isResponsible &&
                g.isScheduleConfigured &&
                g.canCollectPayments) ...[
              const SizedBox(height: 10),
              Text(
                'Joriy davr: ${g.currentReceiverName} · '
                '${formatMoney(g.collectedTotal, g.settlementCurrency)} / '
                '${formatMoney(g.expectedTotal, g.settlementCurrency)}',
                style: TextStyle(color: gap.mutedText, fontSize: 12),
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: g.paymentProgress,
                  minHeight: 5,
                  backgroundColor: cs.surfaceContainerHighest,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                if (pos != null)
                  _Tag(label: 'Navbat ${SavingsGroup.queueNumber(pos)}', color: cs.secondary),
                if (item.isResponsible)
                  _Tag(label: 'Boshqaruv', color: gap.warning)
                else
                  _Tag(label: 'Kuzatuv', color: cs.primary),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ClosedFundTile extends StatelessWidget {
  const _ClosedFundTile({
    required this.item,
    required this.gap,
    required this.cs,
    required this.onTap,
    this.onReactivate,
  });

  final GroupListItem item;
  final GapThemeExtension gap;
  final ColorScheme cs;
  final VoidCallback onTap;
  final VoidCallback? onReactivate;

  @override
  Widget build(BuildContext context) {
    final g = item.group;
    final s = item.mySummary;
    final closed = g.closedAt;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GapCard(
        onTap: onReactivate == null ? onTap : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: gap.mutedText.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(Icons.archive_rounded, color: gap.mutedText),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GapSlidingText(
                            text: g.name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            closed != null
                                ? 'Yopilgan: ${_formatClosedDate(closed)}'
                                : 'Yopilgan · tsikl yakunlangan',
                            style: TextStyle(color: gap.mutedText, fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'To\'lagansiz: ${s.totalPaidRaw ?? formatMoney(g.fromSettlementAmount(s.totalPaidSettlement, s.paymentCurrency), s.paymentCurrency)}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: gap.mutedText),
                  ],
                ),
              ),
            ),
            if (onReactivate != null) ...[
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: onReactivate,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 44),
                ),
                icon: const Icon(Icons.restart_alt_rounded),
                label: Text(
                  'GAPni qayta yoqish (${GapPricing.reactivationPriceLabel})',
                ),
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.center,
                child: TextButton.icon(
                  onPressed: onTap,
                  icon: const Icon(Icons.summarize_outlined, size: 18),
                  label: const Text('Hisobotni ko\'rish'),
                ),
              ),
            ] else ...[
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Hisobotni ko\'rish · PDF',
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _formatClosedDate(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    return '$d.$m.${dt.year}';
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.label,
    required this.value,
    required this.valueStyle,
    required this.gap,
  });

  final String label;
  final String value;
  final TextStyle valueStyle;
  final GapThemeExtension gap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: gap.mutedText,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(value, style: valueStyle),
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _EmptyGroups extends StatelessWidget {
  const _EmptyGroups({required this.onCreate, required this.onJoin});

  final VoidCallback onCreate;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    final gap = context.gap;
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(GapIcons.brandOutlined, size: 72, color: cs.primary.withValues(alpha: 0.4)),
            const SizedBox(height: 20),
            Text('Jamg\'armalar yo\'q', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Masul bo\'lib yarating yoki taklif kodi bilan qo\'shiling',
              textAlign: TextAlign.center,
              style: TextStyle(color: gap.mutedText, height: 1.45),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Jamg\'arma yaratish'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: onJoin,
              icon: const Icon(Icons.group_add_rounded),
              label: const Text('Taklif kodi'),
            ),
          ],
        ),
      ),
    );
  }
}
