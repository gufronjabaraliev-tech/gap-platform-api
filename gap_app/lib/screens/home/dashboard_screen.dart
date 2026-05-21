import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_currency.dart';
import '../../models/participant_dashboard.dart';
import '../../providers/auth_provider.dart';
import '../../providers/groups_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/money_format.dart';
import '../../widgets/gap_hero_header.dart';
import '../../widgets/theme_toggle_button.dart';
import '../group/group_home_screen.dart';
import '../group/group_report_screen.dart';
import '../group/participant_group_screen.dart';

/// Rangli va animatsiyali asosiy Dashboard.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>().user;
    if (auth == null) return;
    await context.read<GroupsProvider>().loadMyGroups(
          auth.id,
          phone: auth.phone,
        );
    if (!mounted) return;
    _entrance.forward(from: 0);
  }

  Animation<double> _interval(double start, double end) {
    return CurvedAnimation(
      parent: _entrance,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
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
    if (user == null) return const SizedBox.shrink();

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
            title: 'Dashboard',
            subtitle: user.name,
            actions: const [ThemeToggleButton(iconColor: Colors.white)],
          ),
          Expanded(
            child: groups.isLoading && groups.myGroups.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _load,
                    color: cs.primary,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                      children: [
                        if (dashboard.gapCount == 0)
                          FadeTransition(
                            opacity: _interval(0, 0.4),
                            child: _EmptyDashboard(gap: gap),
                          )
                        else ...[
                          _FadeSlide(
                            animation: _interval(0, 0.35),
                            child: _WelcomeBanner(
                              name: user.name,
                              gapCount: dashboard.gapCount,
                              activeCount: dashboard.activeCount,
                              gap: gap,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _FadeSlide(
                            animation: _interval(0.12, 0.55),
                            child: _ColorfulOverviewGrid(
                              dashboard: dashboard,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _FadeSlide(
                            animation: _interval(0.28, 0.65),
                            child: _TintedMoneySection(
                              title: 'Jami to\'lagan',
                              icon: GapIcons.payments,
                              gradient: const [
                                Color(0xFF047857),
                                Color(0xFF0D9488),
                              ],
                              totals: dashboard.totalPaidByCurrency,
                              gap: gap,
                              emptyHint:
                                  'Hali hech qaysi GAPga to\'lov qilmagansiz',
                            ),
                          ),
                          const SizedBox(height: 10),
                          _FadeSlide(
                            animation: _interval(0.34, 0.7),
                            child: _TintedMoneySection(
                              title: 'Joriy davr qarzi',
                              icon: Icons.warning_amber_rounded,
                              gradient: const [
                                Color(0xFFD97706),
                                Color(0xFFF59E0B),
                              ],
                              totals: dashboard.currentPeriodDebtByCurrency,
                              gap: gap,
                              emptyHint: 'Joriy davrda qarz yo\'q',
                            ),
                          ),
                          const SizedBox(height: 10),
                          _FadeSlide(
                            animation: _interval(0.4, 0.75),
                            child: _TintedMoneySection(
                              title: 'Kutilayotgan jamg\'arma',
                              icon: GapIcons.brand,
                              gradient: const [
                                Color(0xFF9A7B0C),
                                Color(0xFFD4AF37),
                              ],
                              totals: dashboard.totalExpectedByCurrency,
                              gap: gap,
                              emptyHint: 'Kutilayotgan jamg\'arma yo\'q',
                            ),
                          ),
                          const SizedBox(height: 18),
                          _FadeSlide(
                            animation: _interval(0.5, 0.9),
                            child: Text(
                              'So\'nggi GAPlar',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...dashboard.gaps.take(5).toList().asMap().entries.map(
                            (e) {
                              final row = e.value;
                              return _FadeSlide(
                                animation: _interval(
                                  0.55 + e.key * 0.06,
                                  (0.92).clamp(0.0, 1.0),
                                ),
                                offset: 18,
                                child: _QuickGapTile(
                                  row: row,
                                  gap: gap,
                                  onTap: () => _openGap(row),
                                ),
                              );
                            },
                          ),
                          if (dashboard.gaps.length > 5)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                '+${dashboard.gaps.length - 5} ta boshqa GAP',
                                style: TextStyle(
                                  color: gap.mutedText,
                                  fontSize: 13,
                                ),
                                textAlign: TextAlign.center,
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

class _FadeSlide extends StatelessWidget {
  const _FadeSlide({
    required this.animation,
    required this.child,
    this.offset = 24,
  });

  final Animation<double> animation;
  final Widget child;
  final double offset;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final t = animation.value;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, offset * (1 - t)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class _WelcomeBanner extends StatelessWidget {
  const _WelcomeBanner({
    required this.name,
    required this.gapCount,
    required this.activeCount,
    required this.gap,
  });

  final String name;
  final int gapCount;
  final int activeCount;
  final GapThemeExtension gap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: gap.primaryGradient,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.insights_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Salom, ${name.split(' ').first}!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$gapCount ta GAP · $activeCount ta faol',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ColorfulOverviewGrid extends StatelessWidget {
  const _ColorfulOverviewGrid({required this.dashboard});

  final ParticipantDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    final tiles = [
      (
        GapIcons.groups,
        'Jami',
        '${dashboard.gapCount}',
        [const Color(0xFF047857), const Color(0xFF059669)],
      ),
      (
        Icons.play_circle_fill_rounded,
        'Faol',
        '${dashboard.activeCount}',
        [const Color(0xFF0D9488), const Color(0xFF2DD4BF)],
      ),
      (
        Icons.archive_rounded,
        'Yopilgan',
        '${dashboard.closedCount}',
        [const Color(0xFF64748B), const Color(0xFF94A3B8)],
      ),
      (
        Icons.star_rounded,
        'Olmoqda',
        '${dashboard.receivingNowCount}',
        [const Color(0xFFD97706), const Color(0xFFFBBF24)],
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.35,
      children: tiles.map((t) {
        return _GradientStatCard(
          icon: t.$1,
          label: t.$2,
          value: t.$3,
          colors: t.$4,
        );
      }).toList(),
    );
  }
}

class _GradientStatCard extends StatefulWidget {
  const _GradientStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.colors,
  });

  final IconData icon;
  final String label;
  final String value;
  final List<Color> colors;

  @override
  State<_GradientStatCard> createState() => _GradientStatCardState();
}

class _GradientStatCardState extends State<_GradientStatCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        return Transform.scale(
          scale: 1 + _pulse.value * 0.02,
          child: child,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: widget.colors,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: widget.colors.first.withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(widget.icon, color: Colors.white, size: 26),
            const Spacer(),
            Text(
              widget.value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.88),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TintedMoneySection extends StatelessWidget {
  const _TintedMoneySection({
    required this.title,
    required this.icon,
    required this.gradient,
    required this.totals,
    required this.gap,
    required this.emptyHint,
  });

  final String title;
  final IconData icon;
  final List<Color> gradient;
  final Map<AppCurrency, int> totals;
  final GapThemeExtension gap;
  final String emptyHint;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: gradient.first.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradient),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: gradient.first,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (totals.isEmpty)
            Text(emptyHint, style: TextStyle(color: gap.mutedText, fontSize: 13))
          else
            ...totals.entries.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  formatMoney(e.value, e.key),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: gradient.last,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _QuickGapTile extends StatelessWidget {
  const _QuickGapTile({
    required this.row,
    required this.gap,
    required this.onTap,
  });

  final ParticipantGapRow row;
  final GapThemeExtension gap;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.6)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: cs.primary.withValues(alpha: 0.12),
                  child: Icon(GapIcons.groups, color: cs.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        row.groupName,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        row.statusLabel,
                        style: TextStyle(fontSize: 12, color: gap.mutedText),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyDashboard extends StatelessWidget {
  const _EmptyDashboard({required this.gap});

  final GapThemeExtension gap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cs.primary.withValues(alpha: 0.08),
            AppColors.teal.withValues(alpha: 0.12),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(Icons.rocket_launch_rounded, size: 48, color: cs.primary),
          const SizedBox(height: 12),
          Text(
            'GAPlaringiz shu yerda ko\'rinadi',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: gap.mutedText,
            ),
          ),
        ],
      ),
    );
  }
}
