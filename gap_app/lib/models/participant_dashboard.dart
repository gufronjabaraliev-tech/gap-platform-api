import 'app_currency.dart';
import 'member_group_summary.dart';
import 'savings_group.dart';
import '../utils/money_format.dart';

/// Bitta GAP bo'yicha ishtirokchi statistikasi.
class ParticipantGapRow {
  ParticipantGapRow({
    required this.group,
    required this.memberId,
    required this.isResponsible,
    required this.summary,
    required this.statusLabel,
    required this.statusKind,
    required this.currentPeriodDebtSettlement,
    required this.totalDebtSettlement,
  });

  final SavingsGroup group;
  final String memberId;
  final bool isResponsible;
  final MemberGroupSummary summary;
  final String statusLabel;
  final ParticipantGapStatusKind statusKind;
  final int currentPeriodDebtSettlement;
  final int totalDebtSettlement;

  String get groupName => group.name;
  bool get isClosed => group.isClosed;

  bool get hasPaid => summary.totalPaidSettlement > 0;

  /// Ko'rsatish uchun formatlangan to'lov (ko'p valyuta bo'lsa `+` bilan).
  String get paidDisplayText =>
      summary.totalPaidRaw ??
      formatMoney(
        group.fromSettlementAmount(
          summary.totalPaidSettlement,
          summary.paymentCurrency,
        ),
        summary.paymentCurrency,
      );

  bool get hasCurrentPeriodDebt => currentPeriodDebtSettlement > 0;

  String get currentPeriodDebtDisplayText => formatMoney(
        currentPeriodDebtSettlement,
        group.settlementCurrency,
      );

  bool get hasTotalDebt => totalDebtSettlement > 0;

  String get totalDebtDisplayText => formatMoney(
        group.fromSettlementAmount(
          totalDebtSettlement,
          summary.paymentCurrency,
        ),
        summary.paymentCurrency,
      );

  bool get hasExpected =>
      summary.showReceivingNow || summary.showFuture;

  String? get expectedDisplayText {
    if (summary.showReceivingNow) {
      return formatMoney(
        group.expectedTotalForCurrentReceiver,
        group.currentReceiverReceiveCurrency,
      );
    }
    if (summary.showFuture) {
      return formatMoney(
        group.fromSettlementAmount(
          summary.futureReceiveSettlement,
          summary.receiveCurrency,
        ),
        summary.receiveCurrency,
      );
    }
    return null;
  }

  String? get expectedDetailLabel {
    if (summary.showReceivingNow) return 'Hozir oladi';
    if (summary.showFuture && summary.schedulePosition != null) {
      return 'Navbat ${SavingsGroup.queueNumber(summary.schedulePosition!)}';
    }
    if (summary.showFuture) return 'Navbatda kutilmoqda';
    return null;
  }
}

enum ParticipantGapStatusKind {
  closed,
  receivingNow,
  received,
  waitingTurn,
  active,
  idle,
}

/// Profil statistikasi — barcha GAPlar bo'yicha jamlanma.
class ParticipantDashboard {
  ParticipantDashboard({
    required this.gaps,
    required this.gapCount,
    required this.activeCount,
    required this.closedCount,
    required this.responsibleCount,
    required this.receivingNowCount,
    required this.totalPaidByCurrency,
    required this.totalDebtByCurrency,
    required this.totalExpectedByCurrency,
    required this.currentPeriodDebtByCurrency,
  });

  final List<ParticipantGapRow> gaps;
  final int gapCount;
  final int activeCount;
  final int closedCount;
  final int responsibleCount;
  final int receivingNowCount;
  final Map<AppCurrency, int> totalPaidByCurrency;
  final Map<AppCurrency, int> totalDebtByCurrency;
  final Map<AppCurrency, int> totalExpectedByCurrency;
  final Map<AppCurrency, int> currentPeriodDebtByCurrency;

  int get participantCount => gapCount - responsibleCount;

  List<ParticipantGapRow> get gapsWithPayments =>
      gaps.where((g) => g.hasPaid).toList();

  List<ParticipantGapRow> get gapsWithCurrentDebt =>
      gaps.where((g) => g.hasCurrentPeriodDebt).toList();

  List<ParticipantGapRow> get gapsWithTotalDebt =>
      gaps.where((g) => g.hasTotalDebt).toList();

  List<ParticipantGapRow> get gapsWithExpected =>
      gaps.where((g) => g.hasExpected).toList();

  static ParticipantDashboard fromMemberGroups({
    required List<SavingsGroup> groups,
    required List<String> memberIds,
    required List<bool> isResponsibleFlags,
  }) {
    assert(groups.length == memberIds.length);
    assert(groups.length == isResponsibleFlags.length);

    final gaps = <ParticipantGapRow>[];
    final paid = <AppCurrency, int>{};
    final debt = <AppCurrency, int>{};
    final expected = <AppCurrency, int>{};
    final currentDebt = <AppCurrency, int>{};
    var active = 0;
    var closed = 0;
    var responsible = 0;
    var receivingNow = 0;

    for (var i = 0; i < groups.length; i++) {
      final g = groups[i];
      final memberId = memberIds[i];
      final isResp = isResponsibleFlags[i];
      final summary = MemberGroupSummary.forMember(g, memberId);
      final currency = g.settlementCurrency;

      if (g.isClosed) {
        closed++;
      } else {
        active++;
      }
      if (isResp) responsible++;

      final periodDebt = _currentPeriodDebtSettlement(g, memberId);
      final totalDebt = summary.remainingToPaySettlement;

      final (label, kind) = _status(g, summary);
      if (kind == ParticipantGapStatusKind.receivingNow) receivingNow++;

      gaps.add(
        ParticipantGapRow(
          group: g,
          memberId: memberId,
          isResponsible: isResp,
          summary: summary,
          statusLabel: label,
          statusKind: kind,
          currentPeriodDebtSettlement: periodDebt,
          totalDebtSettlement: totalDebt,
        ),
      );

      if (summary.totalPaidSettlement > 0) {
        paid[currency] =
            (paid[currency] ?? 0) + summary.totalPaidSettlement;
      }
      if (totalDebt > 0) {
        debt[currency] = (debt[currency] ?? 0) + totalDebt;
      }
      if (summary.showReceivingNow) {
        final recv = g.fromSettlementAmount(
          g.expectedTotal,
          summary.receiveCurrency,
        );
        expected[summary.receiveCurrency] =
            (expected[summary.receiveCurrency] ?? 0) + recv;
      } else if (summary.showFuture) {
        final fut = g.fromSettlementAmount(
          summary.futureReceiveSettlement,
          summary.receiveCurrency,
        );
        expected[summary.receiveCurrency] =
            (expected[summary.receiveCurrency] ?? 0) + fut;
      }
      if (periodDebt > 0) {
        currentDebt[currency] = (currentDebt[currency] ?? 0) + periodDebt;
      }
    }

    gaps.sort((a, b) {
      final ak = a.statusKind.index;
      final bk = b.statusKind.index;
      if (a.isClosed != b.isClosed) return a.isClosed ? 1 : -1;
      if (ak != bk) return ak.compareTo(bk);
      return a.groupName.compareTo(b.groupName);
    });

    return ParticipantDashboard(
      gaps: gaps,
      gapCount: groups.length,
      activeCount: active,
      closedCount: closed,
      responsibleCount: responsible,
      receivingNowCount: receivingNow,
      totalPaidByCurrency: paid,
      totalDebtByCurrency: debt,
      totalExpectedByCurrency: expected,
      currentPeriodDebtByCurrency: currentDebt,
    );
  }

  static (String, ParticipantGapStatusKind) _status(
    SavingsGroup g,
    MemberGroupSummary s,
  ) {
    if (g.isClosed) {
      return ('GAP yakunlangan', ParticipantGapStatusKind.closed);
    }
    if (s.showReceivingNow) {
      return ('Hozir jamg\'arma olmoqda', ParticipantGapStatusKind.receivingNow);
    }
    if (s.hasReceived) {
      return ('Jamg\'arma olgan', ParticipantGapStatusKind.received);
    }
    if (s.showFuture) {
      final pos = s.schedulePosition;
      if (pos != null) {
        return (
          'Navbat ${SavingsGroup.queueNumber(pos)} kutilmoqda',
          ParticipantGapStatusKind.waitingTurn,
        );
      }
      return ('Jamg\'arma kutilmoqda', ParticipantGapStatusKind.waitingTurn);
    }
    if (!g.gapSessionActive) {
      return ('Keyingi GAP kutilmoqda', ParticipantGapStatusKind.idle);
    }
    return ('Faol ishtirokchi', ParticipantGapStatusKind.active);
  }

  static int _currentPeriodDebtSettlement(
    SavingsGroup g,
    String memberId,
  ) {
    if (g.isClosed || !g.gapSessionActive) return 0;
    if (g.currentReceiverId == memberId) return 0;
    if (g.paymentFor(memberId) != null) return 0;

    final mandatory = g.mandatoryPaymentFor(memberId);
    if (mandatory != null) {
      return g.settlementAmountFor(mandatory.entry);
    }
    return g.periodAmount;
  }
}
