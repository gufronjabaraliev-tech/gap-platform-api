import 'app_currency.dart';
import 'schedule_mode.dart';
import 'savings_group.dart';

/// Foydalanuvchining bitta jamg'armadagi shaxsiy moliyaviy holati.
class MemberGroupSummary {
  MemberGroupSummary({
    required this.totalPaidSettlement,
    required this.totalPaidRaw,
    required this.hasReceived,
    required this.remainingToPaySettlement,
    required this.futureReceiveSettlement,
    required this.paymentCurrency,
    required this.receiveCurrency,
    this.schedulePosition,
    this.isCurrentReceiver = false,
  });

  final int totalPaidSettlement;
  final String? totalPaidRaw;
  final bool hasReceived;
  final int remainingToPaySettlement;
  final int futureReceiveSettlement;
  final AppCurrency paymentCurrency;
  final AppCurrency receiveCurrency;
  final int? schedulePosition;
  final bool isCurrentReceiver;

  int get totalPaidDisplay => totalPaidSettlement > 0
      ? totalPaidSettlement
      : 0;

  int get remainingDisplay => remainingToPaySettlement;
  int get futureReceiveDisplay => futureReceiveSettlement;

  bool get showRemaining => hasReceived && remainingToPaySettlement > 0;
  bool get showFuture =>
      !hasReceived && futureReceiveSettlement > 0 && !isCurrentReceiver;
  bool get showReceivingNow => isCurrentReceiver && !hasReceived;

  static MemberGroupSummary forMember(SavingsGroup group, String memberId) {
    if (!group.members.containsKey(memberId)) {
      return MemberGroupSummary(
        totalPaidSettlement: 0,
        totalPaidRaw: null,
        hasReceived: false,
        remainingToPaySettlement: 0,
        futureReceiveSettlement: 0,
        paymentCurrency: group.settlementCurrency,
        receiveCurrency: group.settlementCurrency,
      );
    }

    final paidSettlement = _totalPaidSettlement(group, memberId);
    final paidRaw = _paidRawText(group, memberId);
    final received = _hasReceived(group, memberId);
    final remaining = _remainingToPay(group, memberId);
    final isCurrent = group.currentReceiverId == memberId;
    final future = received || isCurrent
        ? 0
        : _futureReceiveSettlement(group, memberId);

    return MemberGroupSummary(
      totalPaidSettlement: paidSettlement,
      totalPaidRaw: paidRaw,
      hasReceived: received,
      remainingToPaySettlement: remaining,
      futureReceiveSettlement: future,
      paymentCurrency: group.currencyForMember(memberId),
      receiveCurrency: group.receiveCurrencyForMember(memberId),
      schedulePosition: group.schedulePositionForMember(memberId),
      isCurrentReceiver: isCurrent,
    );
  }

  static int _totalPaidSettlement(SavingsGroup group, String memberId) {
    var sum = 0;
    for (final periodMap in group.payments.values) {
      final entry = periodMap[memberId];
      if (entry != null) sum += group.settlementAmountFor(entry);
    }
    return sum;
  }

  static String? _paidRawText(SavingsGroup group, String memberId) {
    final by = <AppCurrency, int>{};
    for (final periodMap in group.payments.values) {
      final entry = periodMap[memberId];
      if (entry == null) continue;
      by[entry.currency] = (by[entry.currency] ?? 0) + entry.amount;
    }
    if (by.isEmpty) return null;
    return by.entries
        .map((e) => SavingsGroup.formatMoneySimple(e.value, e.key))
        .join(' + ');
  }

  static bool _hasReceived(SavingsGroup group, String memberId) =>
      group.hasReceivedFund(memberId);

  static String? _receiverAtPeriod(SavingsGroup group, int period) {
    if (group.scheduleMode != ScheduleMode.fixedRandom) return null;
    if (period < 0 || period >= group.schedule.length) return null;
    return group.schedule[period];
  }

  static int _remainingToPay(SavingsGroup group, String memberId) {
    if (group.scheduleMode == ScheduleMode.fixedRandom &&
        group.schedule.isNotEmpty) {
      var owed = 0;
      for (var p = 0; p < group.schedule.length; p++) {
        if (_receiverAtPeriod(group, p) == memberId) continue;
        if (group.payments['$p']?[memberId] == null) {
          owed += group.periodAmount;
        }
      }
      return owed;
    }

    final maxOwed = group.payersCount * group.periodAmount;
    final paid = _totalPaidSettlement(group, memberId);
    final left = maxOwed - paid;
    return left > 0 ? left : 0;
  }

  static int _futureReceiveSettlement(SavingsGroup group, String memberId) {
    if (_hasReceived(group, memberId)) return 0;

    switch (group.scheduleMode) {
      case ScheduleMode.fixedRandom:
        final idx = group.schedule.indexOf(memberId);
        if (idx < 0) return 0;
        if (idx < group.currentPeriod) return 0;
        return group.expectedTotal;
      case ScheduleMode.manual:
      case ScheduleMode.randomEach:
        if (group.hasReceivedFund(memberId)) return 0;
        return group.expectedTotal;
    }
  }
}
