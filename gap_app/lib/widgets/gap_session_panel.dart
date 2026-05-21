import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/savings_group.dart';
import '../providers/auth_provider.dart';
import '../providers/groups_provider.dart';
import '../screens/group/gap_calendar_screen.dart';
import '../screens/main_shell_screen.dart';
import '../theme/app_colors.dart';
import '../theme/gap_theme_extension.dart';
import '../utils/gap_navigation.dart';
import '../utils/money_format.dart';
import 'confirm_dialog.dart';
import 'gap_card.dart';
import 'gap_sliding_text.dart';
import 'pay_gap_reactivation_sheet.dart';

Future<void> handOverGapFund(BuildContext context) async {
  final groups = context.read<GroupsProvider>();
  final g = groups.activeGroup!;

  if (g.mandatoryUnpaidPayerIds.isNotEmpty) {
    final names = g.mandatoryUnpaidPayerIds
        .map(g.displayNameFor)
        .join(', ');
    showGapSnackBar(
      context,
      'Majburiy to\'lov: $names',
      isError: true,
    );
    return;
  }

  final optionalUnpaid = g.optionalUnpaidCount;
  final pos = g.currentReceiverQueuePosition;
  final queueLabel = pos != null ? SavingsGroup.queueNumber(pos) : null;
  final optionalNote = optionalUnpaid > 0
      ? '\n\nHali $optionalUnpaid kishi ixtiyoriy to\'lamagan — faqat yig\'ilgan summa topshiriladi.'
      : '';
  final ok = await showGapConfirmDialog(
    context,
    title: 'Jamg\'armani topshirish',
    message:
        '${formatMoney(g.collectedTotal, g.settlementCurrency)} summani '
        '${queueLabel != null ? "$queueLabel — " : ""}${g.currentReceiverName}ga topshirasizmi?$optionalNote\n\n'
        '${g.isFinalGapPeriod ? "Bu oxirgi navbat — jamg\'arma yakunlanadi va GAP to\'xtaydi." : "Bu GAP navbati yopiladi."}',
    isDanger: false,
    confirmLabel: 'Topshirish',
  );
  if (ok != true || !context.mounted) return;

  final result = await groups.handOverFund(force: true);
  if (!context.mounted) return;
  if (result != null && result.startsWith('mandatory:')) {
    showGapSnackBar(
      context,
      'Avval majburiy to\'lovlarni qabul qiling',
      isError: true,
    );
    return;
  }
  if (result == '__group_closed__' ||
      groups.activeGroup?.isClosed == true) {
    await handleGapFinalizedReturnToGroups(context);
    return;
  }
  showGapSnackBar(
    context,
    'Jamg\'arma topshirildi — bu navbat yopildi. Keyingi GAP kunini belgilang.',
  );
}

Future<void> startGapSessionFromUi(BuildContext context) async {
  final groups = context.read<GroupsProvider>();
  final g = groups.activeGroup!;
  final receiver = g.currentReceiverName;

  if (g.isStartScheduledForFuture) {
    final early = await showGapConfirmDialog(
      context,
      title: 'Bugun boshlash',
      message:
          'Kalendarda keyingi GAP: ${g.nextGapDueDateLabel}.\n\n'
          'Baribir bugun boshlaysizmi?',
      confirmLabel: 'Ha, bugun',
    );
    if (early != true || !context.mounted) return;
  }

  if (g.pendingNewCycleSetup && !g.isNewCycleSetupReady) {
    showGapSnackBar(
      context,
      'Avval a\'zolar, navbat va pul oluvchini sozlang',
      isError: true,
    );
    return;
  }

  final ok = await showGapConfirmDialog(
    context,
    title: g.pendingNewCycleSetup ? 'Yangi GAPni boshlash' : 'GAP ni boshlash',
    message: g.canCollectPayments
        ? 'Navbatdagi $receiver uchun ${g.currentPeriodLabel} jamg\'armasi boshlanadi.'
        : 'START bosiladi. So\'ng Navbatdan pul oluvchini tanlang.',
  );
  if (ok != true || !context.mounted) return;

  final err = await groups.startGapSession();
  if (!context.mounted) return;
  if (err != null) {
    showGapSnackBar(context, err, isError: true);
    return;
  }
  showGapSnackBar(context, 'GAP boshlandi — boshqaruv paneli faol');
}

/// Oxirgi navbat topshirilgach: GAP yopiladi, jamg'armalar ro'yxatiga qaytish.
Future<void> handleGapFinalizedReturnToGroups(BuildContext context) async {
  final groups = context.read<GroupsProvider>();
  final auth = context.read<AuthProvider>().user;
  final name = groups.activeGroup?.name ?? 'GAP';

  if (!context.mounted) return;
  navigateToMyGroupsCleared(context);

  groups.clearActive();
  if (auth != null) {
    await groups.loadMyGroups(auth.id, phone: auth.phone);
  }

  final snackCtx = MainShellScreen.globalKey.currentContext;
  if (snackCtx != null && snackCtx.mounted) {
    showGapSnackBar(
      snackCtx,
      '$name yakunlandi — barcha ishtirokchilar jamg\'arma oldi',
    );
  }
}

/// Boshqaruv panelidan qayta yoqish.
Future<void> openGapReactivationFlow(BuildContext context) async {
  final groups = context.read<GroupsProvider>();
  final g = groups.activeGroup!;

  final paid = await PayGapReactivationSheet.show(
    context,
    groupName: g.name,
  );
  if (paid != true || !context.mounted) return;

  final err = await groups.reactivateGroup();
  if (!context.mounted) return;
  if (err != null) {
    showGapSnackBar(context, err, isError: true);
    return;
  }
  showGapSnackBar(context, 'GAP qayta yoqildi');
  navigateToGroupHomeCleared(context);
}

/// To‘lovlar sahifasida: topshirish, START, qayta yoqish.
class GapSessionPanel extends StatelessWidget {
  const GapSessionPanel({
    super.key,
    required this.group,
    this.hideHandOver = false,
  });

  final SavingsGroup group;

  /// To‘lovlar ro‘yxatidan keyin alohida ko‘rsatiladi.
  final bool hideHandOver;

  Future<void> _reactivate(BuildContext context) async {
    await openGapReactivationFlow(context);
  }

  @override
  Widget build(BuildContext context) {
    final groups = context.watch<GroupsProvider>();
    final canEdit = groups.canEditActive;
    final gap = context.gap;
    final cs = Theme.of(context).colorScheme;

    if (group.isClosed) {
      if (!groups.isResponsibleActive) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GapInfoBanner(
            icon: Icons.lock_rounded,
            message:
                'GAP to\'xtatilgan — barcha ishtirokchilar pul olgan. Masul qayta yoqishi kerak.',
          ),
        );
      }
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: GapCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'GAP tsikli yakunlandi',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Har bir ishtirokchi jamg\'arma olgan. Yangi davr uchun to\'lov qiling.',
                style: TextStyle(color: gap.mutedText, height: 1.4),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: () => _reactivate(context),
                icon: const Icon(Icons.restart_alt_rounded),
                label: const Text('GAPni qayta yoqish (to\'lov)'),
              ),
            ],
          ),
        ),
      );
    }

    if (!hideHandOver && group.canHandOverFund && canEdit) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: GapHandOverFundCard(
          group: group,
          onHandOver: () => handOverGapFund(context),
        ),
      );
    }

    if (group.canStartGapSession && canEdit) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: GapInfoBanner(
          icon: Icons.home_rounded,
          message:
              'Keyingi GAPni boshlash uchun boshqaruv panelidagi START tugmasini bosing.',
          tone: GapBannerTone.info,
        ),
      );
    }

    if (group.isWaitingForNextGap) {
      final due = group.nextGapDueDateLabel;
      final banner = GapInfoBanner(
        icon: Icons.hourglass_top_rounded,
        message: due != null
            ? 'Navbat yopiq. Keyingi GAP: $due — shu kuni START.'
            : 'Navbat yopiq. Kalendarda keyingi GAP kunini belgilang.',
        tone: due != null ? GapBannerTone.info : GapBannerTone.warning,
      );
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: canEdit
            ? GapCard(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const GapCalendarScreen(
                      promptPickNext: true,
                    ),
                  ),
                ),
                child: banner,
              )
            : banner,
      );
    }

    return const SizedBox.shrink();
  }
}

/// Barcha to‘lovlar tugagach — navbatdagi oluvchiga jamg‘arma topshirish.
class GapHandOverFundCard extends StatefulWidget {
  const GapHandOverFundCard({
    super.key,
    required this.group,
    required this.onHandOver,
  });

  final SavingsGroup group;
  final VoidCallback onHandOver;

  @override
  State<GapHandOverFundCard> createState() => _GapHandOverFundCardState();
}

class _GapHandOverFundCardState extends State<GapHandOverFundCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseScale;
  late final Animation<double> _glowOpacity;

  SavingsGroup get group => widget.group;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _pulseScale = Tween<double>(begin: 1, end: 1.028).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _glowOpacity = Tween<double>(begin: 0.28, end: 0.62).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _syncPulse();
  }

  @override
  void didUpdateWidget(GapHandOverFundCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.group.allMandatoryObligationsSatisfied !=
        group.allMandatoryObligationsSatisfied) {
      _syncPulse();
    }
  }

  void _syncPulse() {
    if (group.allMandatoryObligationsSatisfied) {
      if (!_pulseCtrl.isAnimating) _pulseCtrl.repeat(reverse: true);
    } else {
      _pulseCtrl
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gap = context.gap;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pos = group.currentReceiverQueuePosition;
    final queueLabel =
        pos != null ? SavingsGroup.queueNumber(pos) : null;
    final ready = group.allMandatoryObligationsSatisfied;

    final btnBg = isDark
        ? AppColors.primaryDark.withValues(alpha: 0.88)
        : AppColors.primaryDark.withValues(alpha: 0.82);
    final btnFg = AppColors.gold;
    final btnBorder = AppColors.gold.withValues(alpha: 0.5);

    return GapCard(
      gradient: gap.primaryGradient,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            ready ? 'Topshirish mumkin' : 'Majburiy to\'lovlar kutilmoqda',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            () {
              if (!ready) {
                final n = group.mandatoryUnpaidPayerIds.length;
                return 'Avval $n kishi majburiy to\'lovni qilishi kerak.';
              }
              final opt = group.optionalUnpaidCount;
              final base = queueLabel != null
                  ? '$queueLabel — ${group.currentReceiverName}ga '
                  : '${group.currentReceiverName}ga ';
              if (opt > 0) {
                return '${base}yig\'ilgan ${formatMoney(group.collectedTotal, group.settlementCurrency)} topshiriladi. '
                    '($opt kishi ixtiyoriy to\'lamagan — navbati keyinroq).';
              }
              if (group.isFinalGapPeriod) {
                return '${base}topshiring. Oxirgi navbat — GAP yakunlanadi.';
              }
              return '${base}topshiring. Shu navbat yopiladi.';
            }(),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 13,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (context, child) {
              return Transform.scale(
                scale: ready ? _pulseScale.value : 1,
                child: child,
              );
            },
            child: DecoratedBox(
              decoration: ready
                  ? BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.gold
                              .withValues(alpha: _glowOpacity.value),
                          blurRadius: 14,
                          spreadRadius: 0,
                        ),
                      ],
                    )
                  : const BoxDecoration(),
              child: FilledButton(
                onPressed: ready ? widget.onHandOver : null,
                style: FilledButton.styleFrom(
                  backgroundColor: btnBg,
                  foregroundColor: btnFg,
                  disabledBackgroundColor:
                      Colors.white.withValues(alpha: 0.12),
                  disabledForegroundColor:
                      Colors.white.withValues(alpha: 0.45),
                  elevation: 0,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: ready
                          ? btnBorder
                          : Colors.white.withValues(alpha: 0.2),
                      width: 1.2,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.volunteer_activism_rounded),
                    const SizedBox(width: 8),
                    Flexible(
                      child: GapSlidingText(
                        text: queueLabel != null
                            ? 'Jamg\'armani topshirish ($queueLabel)'
                            : 'Jamg\'armani topshirish',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: ready ? btnFg : null,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
