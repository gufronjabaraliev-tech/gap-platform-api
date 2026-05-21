import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/savings_group.dart';
import '../../providers/groups_provider.dart';
import '../../services/bank_rates_service.dart';
import '../../theme/gap_theme_extension.dart';
import '../../utils/money_format.dart';
import '../../widgets/gap_card.dart';
import '../../widgets/gap_group_scroll_body.dart';
import '../../widgets/group_header.dart';
import '../../widgets/member_avatar.dart';
import '../../widgets/gap_session_panel.dart';
import '../../widgets/gap_sliding_text.dart';
import '../../widgets/payment_entry_sheet.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({
    super.key,
    this.initialPayerId,
    this.openPaymentSheetOnLoad = false,
  });

  /// Navbatdan tanlangach avtomatik ochiladigan to'lovchi.
  final String? initialPayerId;

  final bool openPaymentSheetOnLoad;

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _openedInitialSheet = false;

  @override
  void initState() {
    super.initState();
    BankRatesService.instance.ensureLoaded();
  }

  Future<void> _openPaymentSheet(SavingsGroup g, String payerId) async {
    final ok = await showPaymentEntrySheet(
      context: context,
      group: g,
      payerId: payerId,
    );
    if (ok == true && mounted) {
      setState(() {});
    }
  }

  void _maybeOpenInitialSheet(SavingsGroup g) {
    if (_openedInitialSheet || !widget.openPaymentSheetOnLoad) return;
    if (!g.canAcceptPayments) return;
    final payerId = widget.initialPayerId ?? suggestNextPayerId(g);
    if (payerId == null) return;
    _openedInitialSheet = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _openPaymentSheet(g, payerId);
    });
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
    final gap = context.gap;
    final cs = Theme.of(context).colorScheme;
    final canEdit = groups.canEditActive;
    _maybeOpenInitialSheet(g);

    if (canEdit && !g.isManagementUnlocked && !g.isClosed && !g.canStartGapSession) {
      return Scaffold(
        body: GapGroupScrollBodyFill(
          header: const GroupHeader(),
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              'To\'lovlar START bosilgandan keyin ochiladi.\n\n'
              'Hozircha Navbat, Kalendar va Hisobotlarni ko\'rishingiz mumkin.',
              textAlign: TextAlign.center,
              style: TextStyle(color: gap.mutedText, height: 1.5),
            ),
          ),
        ),
      );
    }

    if (!g.isScheduleConfigured) {
      return Scaffold(
        body: GapGroupScrollBodyFill(
          header: const GroupHeader(),
          padding: const EdgeInsets.all(24),
          child: const Center(
            child: Text(
              'Avval "Navbat" bo\'limida navbat turini sozlang.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final receiverId = g.currentReceiverId;
    final payers = receiverId != null
        ? g.members.entries.where((e) => e.key != receiverId)
        : g.members.entries;
    final showPayerList = g.canAcceptPayments && canEdit && receiverId != null;
    if (!groups.canEditActive) {
      return Scaffold(
        body: GapGroupScrollBodyFill(
          header: const GroupHeader(),
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              'To\'lovni faqat masul qayd etadi.\n'
              'Ishtirokchi sifatida to\'lov kiritish mumkin emas.',
              textAlign: TextAlign.center,
              style: TextStyle(color: gap.mutedText, height: 1.5),
            ),
          ),
        ),
      );
    }

    final receiverPos = g.currentReceiverQueuePosition;
    final receiverTitle = receiverPos != null
        ? '${SavingsGroup.queueNumber(receiverPos)} — ${g.currentReceiverName}'
        : g.currentReceiverName;

    return Scaffold(
      body: GapGroupScrollBody(
        header: const GroupHeader(),
        padding: const EdgeInsets.all(16),
        children: [
                if (receiverId != null)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: gap.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Navbatdagi pul oluvchi',
                          style: TextStyle(color: Colors.white70),
                        ),
                        Text(
                          receiverTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          '${g.currentPeriodLabel}\n'
                          'Oladi (${g.currentReceiverReceiveCurrency.label}): '
                          '${formatMoney(g.expectedTotalForCurrentReceiver, g.currentReceiverReceiveCurrency)}',
                          style: const TextStyle(color: Colors.white70),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                else if (!g.isClosed)
                  GapInfoBanner(
                    icon: Icons.person_search_rounded,
                    message: g.gapSessionActive
                        ? 'Pul oluvchi tanlanmagan. Avval Navbatdan belgilang.'
                        : 'START bosing yoki Navbatdan keyingi pul oluvchini tanlang.',
                    tone: GapBannerTone.warning,
                  ),
                const SizedBox(height: 12),
                if (g.canHandOverFund && canEdit)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GapHandOverFundCard(
                      group: g,
                      onHandOver: () => handOverGapFund(context),
                    ),
                  )
                else
                  GapSessionPanel(group: g, hideHandOver: true),
                if (showPayerList) ...[
                  const SizedBox(height: 8),
                  Text(
                    'To\'lovlar',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 8),
                  ...payers.map((e) {
                    final pay = g.paymentFor(e.key);
                    final memberCur = g.currencyForMember(e.key);
                    final recip = g.mandatoryPaymentFor(e.key);
                    final isMandatory = recip != null && pay == null;
                    final isExempt =
                        g.isPayerExemptFromPayingCurrentReceiver(e.key);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        onTap: isExempt
                            ? null
                            : () => _openPaymentSheet(g, e.key),
                        leading: MemberAvatar(
                          displayName: e.value.displayName,
                          member: e.value,
                          phone: e.value.phone,
                          linkedUserId: e.value.linkedUserId,
                          radius: 22,
                        ),
                        title: GapSlidingText(
                          text: e.value.displayName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: isExempt
                            ? Text(
                                'To\'lov talab qilinmaydi',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: gap.mutedText,
                                  fontWeight: FontWeight.w600,
                                ),
                              )
                            : recip != null && pay == null
                            ? Text(
                                'Majburiy qaytarish',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: gap.warning,
                                  fontWeight: FontWeight.w600,
                                ),
                              )
                            : pay == null
                                ? Text(
                                    'Ixtiyoriy · ${memberCur.label}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: gap.mutedText,
                                    ),
                                  )
                                : Text(
                                    memberCur.label,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: gap.mutedText,
                                    ),
                                  ),
                        trailing: isExempt
                            ? Icon(Icons.block_rounded,
                                color: gap.mutedText, size: 22)
                            : pay != null
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Icon(Icons.check_circle,
                                      color: gap.success, size: 20),
                                  Text(
                                    formatPaymentWithSettlement(g, pay),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: gap.success,
                                    ),
                                  ),
                                ],
                              )
                            : isMandatory
                                ? Text(
                                    formatMoney(
                                      recip.entry.amount,
                                      recip.entry.currency,
                                    ),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: gap.warning,
                                      fontSize: 12,
                                    ),
                                  )
                                : Icon(Icons.add_circle_outline,
                                    color: cs.primary),
                      ),
                    );
                  }),
                ],
                if (g.canCollectPayments && g.paidCount > 0) ...[
                  const SizedBox(height: 20),
                  LinearProgressIndicator(
                    value: g.canAcceptPayments ? g.paymentProgress : 1,
                  ),
                  const SizedBox(height: 8),
                ],
                if (g.canCollectPayments &&
                    g.paidCount > 0 &&
                    g.collectedRawText != null) ...[
                  Text(
                    'Asl: ${g.collectedRawText}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                if (g.canCollectPayments && g.paidCount > 0)
                  Text(
                    'Jami (${g.settlementCurrency.label}): '
                    '${formatMoney(g.collectedTotal, g.settlementCurrency)} / '
                    'maqsad ${formatMoney(g.expectedTotalForCurrentReceiver, g.currentReceiverReceiveCurrency)} '
                    '· ${g.paidCount} kishi',
                    textAlign: TextAlign.center,
                  ),
        ],
      ),
    );
  }
}
