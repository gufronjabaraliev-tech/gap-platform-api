import '../utils/gap_date_format.dart';
import '../utils/pin_util.dart';
import 'app_currency.dart';
import 'cycle_type.dart';
import 'group_member.dart';
import 'payment_entry.dart';
import 'reciprocal_obligation.dart';
import 'schedule_mode.dart';

class SavingsGroup {
  SavingsGroup({
    required this.id,
    required this.name,
    required this.responsibleUserId,
    required this.cycleType,
    required this.periodAmount,
    required this.inviteCode,
    AppCurrency? settlementCurrency,
    Map<String, double>? exchangeRates,
    Map<String, GroupMember>? members,
    List<String>? schedule,
    ScheduleMode? scheduleMode,
    this.activeReceiverId,
    List<String>? completedReceiverIds,
    this.currentPeriod = 0,
    Map<String, Map<String, PaymentEntry>>? payments,
    this.createdAt,
    this.isClosed = false,
    this.closedAt,
    this.membersRosterConfirmed = false,
    this.nextGapDueDate,
    this.lastGapCollectionDate,
    this.gapSessionActive = true,
    List<int>? handedOverPeriods,
    this.discretionaryReceiveGrantAvailable = true,
    this.discretionaryReceiveGrantUsed = false,
    this.discretionaryReceiverOverride,
    this.pendingNewCycleSetup = false,
    this.pendingCycleClosure = false,
  })  : settlementCurrency = settlementCurrency ?? AppCurrency.uzs,
        exchangeRates = exchangeRates ?? _defaultRatesFor(settlementCurrency ?? AppCurrency.uzs),
        members = members ?? {},
        schedule = schedule ?? [],
        scheduleMode = scheduleMode ?? ScheduleMode.fixedRandom,
        completedReceiverIds = completedReceiverIds ?? [],
        payments = payments ?? {},
        handedOverPeriods = handedOverPeriods ?? [];

  final String id;
  final String name;
  String responsibleUserId;
  CycleType cycleType;
  /// Tavsiya etilgan summa — [settlementCurrency] da.
  int periodAmount;
  final String inviteCode;
  /// Pul oluvchi oladigan / jami hisob-kitob valyutasi.
  AppCurrency settlementCurrency;
  /// 1 birlik [valyuta] = necha [settlementCurrency] (masalan USD→so'm: 12500).
  Map<String, double> exchangeRates;
  Map<String, GroupMember> members;
  List<String> schedule;
  ScheduleMode scheduleMode;
  /// Ixtiyoriy / har gal tasodifiy: joriy davr pul oluvchisi.
  String? activeReceiverId;
  /// Ushbu davrda allaqachon pul olgan a'zolar.
  List<String> completedReceiverIds;
  int currentPeriod;
  /// Davr -> a'zo id -> to'lov
  Map<String, Map<String, PaymentEntry>> payments;
  final DateTime? createdAt;
  bool isClosed;
  DateTime? closedAt;
  /// Masul a'zolar ro'yxatini tasdiqlagach o'chirish qiyinlashadi.
  bool membersRosterConfirmed;
  /// Keyingi GAP jamg'arish kuni (faqat sana).
  DateTime? nextGapDueDate;
  /// Oxirgi marta jamg'arish tugagan kun (to'liq to'langan yoki topshirilgan).
  DateTime? lastGapCollectionDate;
  /// Joriy GAP sessiyasi — to'lov qabul qilinadi.
  bool gapSessionActive;
  /// Jamg'arma puli topshirilgan davrlar.
  List<int> handedOverPeriods;
  /// GAP navbat: 1 marta istalgan ishtirokchiga olish huquqi berish mumkin.
  bool discretionaryReceiveGrantAvailable;
  bool discretionaryReceiveGrantUsed;
  /// Joriy davr uchun navbatdan tashqari pul oluvchi (ixtiyoriy huquq).
  String? discretionaryReceiverOverride;

  /// Tsikl yakunlab qayta yoqilgach — START dan oldin a'zolar va navbat sozlanadi.
  bool pendingNewCycleSetup;

  /// Barcha ishtirokchilar pul oldi — qayta yoqish tasdiqlanmaguncha yopilmaydi.
  bool pendingCycleClosure;

  bool get needsCycleReactivation => isClosed || pendingCycleClosure;

  bool get canUseDiscretionaryReceive =>
      scheduleMode == ScheduleMode.fixedRandom &&
      discretionaryReceiveGrantAvailable &&
      !discretionaryReceiveGrantUsed &&
      !isClosed &&
      schedule.isNotEmpty;

  bool get isCurrentPeriodHandedOver =>
      handedOverPeriods.contains(currentPeriod);

  bool get canAcceptPayments =>
      !isClosed &&
      gapSessionActive &&
      !isCurrentPeriodHandedOver &&
      canCollectPayments;

  bool get allCurrentPayersPaid =>
      canCollectPayments && payersCount > 0 && paidCount >= payersCount;

  /// Majburiy qaytarish to'lovi bajarilganmi (summa yetarli).
  bool isMandatoryObligationSatisfied(String payerId) {
    final obligation = mandatoryPaymentFor(payerId);
    if (obligation == null) return true;
    final pay = paymentFor(payerId);
    if (pay == null) return false;
    return settlementAmountFor(pay) >= settlementAmountFor(obligation.entry);
  }

  /// Joriy davrda majburiy to'lov qilmaganlar (qaytarish majburiyati).
  List<String> get mandatoryUnpaidPayerIds {
    final recv = currentReceiverId;
    if (recv == null) return [];
    return members.keys
        .where((id) => id != recv && !isMandatoryObligationSatisfied(id))
        .where((id) => mandatoryPaymentFor(id) != null)
        .toList();
  }

  bool get allMandatoryObligationsSatisfied =>
      mandatoryUnpaidPayerIds.isEmpty;

  /// To'lamagan, lekin majburiyati yo'q (ixtiyoriy to'lovchi).
  List<String> get optionalUnpaidPayerIds {
    final recv = currentReceiverId;
    if (recv == null) return [];
    return members.keys
        .where((id) =>
            id != recv &&
            paymentFor(id) == null &&
            mandatoryPaymentFor(id) == null &&
            !isPayerExemptFromPayingCurrentReceiver(id))
        .toList();
  }

  /// Hisobotda ko'rsatiladigan yakunlangan davrlar.
  List<int> get reportPeriodIndexes {
    final set = <int>{};
    set.addAll(handedOverPeriods);
    for (final k in payments.keys) {
      final p = int.tryParse(k);
      if (p != null) set.add(p);
    }
    switch (scheduleMode) {
      case ScheduleMode.fixedRandom:
        for (var i = 0; i < schedule.length; i++) {
          if (handedOverPeriods.contains(i) || payments.containsKey('$i')) {
            set.add(i);
          }
        }
      case ScheduleMode.manual:
      case ScheduleMode.randomEach:
        for (var i = 0; i < completedReceiverIds.length; i++) {
          set.add(i);
        }
    }
    return set.toList()..sort();
  }

  int get optionalUnpaidCount => optionalUnpaidPayerIds.length;

  /// Majburiy to'lovlar bajarilgan bo'lsa, yig'ilgan summa topshiriladi (hamma to'lamagan bo'lsa ham).
  bool get canHandOverFund =>
      !isClosed &&
      gapSessionActive &&
      !isCurrentPeriodHandedOver &&
      canCollectPayments &&
      allMandatoryObligationsSatisfied &&
      collectedTotal > 0;

  bool get isWaitingForNextGap => !isClosed && !gapSessionActive;

  /// START bosilgandan keyin: to'lovlar, summa, taklif va boshqaruv.
  bool get isManagementUnlocked => isClosed || gapSessionActive;

  bool get isNextGapDue {
    final due = nextGapDueDate;
    if (due == null) return true;
    final today = gapDateOnly(DateTime.now());
    final dueOnly = gapDateOnly(due);
    return !dueOnly.isAfter(today);
  }

  /// Kalendarda kelajak kun belgilangan (START baribir chiqadi, tasdiq so'raladi).
  bool get isStartScheduledForFuture {
    final due = nextGapDueDate;
    if (due == null) return false;
    return gapDateOnly(due).isAfter(gapDateOnly(DateTime.now()));
  }

  bool get hasEnoughMembers => memberCount >= 2;

  /// Navbat va (kerak bo'lsa) birinchi pul oluvchi tayyor.
  bool get isNavbatReadyForNewCycle {
    switch (scheduleMode) {
      case ScheduleMode.fixedRandom:
        return schedule.isNotEmpty;
      case ScheduleMode.manual:
      case ScheduleMode.randomEach:
        return activeReceiverId != null;
    }
  }

  bool get isNewCycleSetupReady =>
      hasEnoughMembers && isNavbatReadyForNewCycle;

  bool get isInNewCycleSetupPhase =>
      pendingNewCycleSetup && !gapSessionActive && !isClosed;

  /// Jamg'arma topshirilgach yoki yangi tsikl sozlangach START.
  bool get canStartGapSession {
    if (isClosed || gapSessionActive || !isWaitingForNextGap) return false;
    if (pendingNewCycleSetup) return isNewCycleSetupReady;
    return lastGapCollectionDate != null;
  }

  bool get gapCollectedToday {
    final last = lastGapCollectionDate;
    if (last == null) return false;
    return gapSameDay(last, DateTime.now());
  }

  bool get shouldPromptNextGapDate =>
      !isClosed && isWaitingForNextGap && nextGapDueDate == null;

  String? get nextGapDueDateLabel {
    final d = nextGapDueDate;
    if (d == null) return null;
    return formatGapDate(d, withWeekday: true);
  }

  void markGapCollectedToday() {
    lastGapCollectionDate = gapDateOnly(DateTime.now());
  }

  static Map<String, double> _defaultRatesFor(AppCurrency settlement) {
    final rates = <String, double>{};
    for (final c in AppCurrency.values) {
      if (c == settlement) continue;
      rates[c.code] = AppCurrency.rateBetween(c, settlement);
    }
    return rates;
  }

  int get memberCount => members.length;
  int get payersCount => memberCount > 0 ? memberCount - 1 : 0;

  Map<String, String> get memberNames => {
        for (final e in members.entries) e.key: e.value.displayName,
      };

  bool get isFixedScheduleMode => scheduleMode == ScheduleMode.fixedRandom;

  bool get isScheduleConfigured {
    switch (scheduleMode) {
      case ScheduleMode.fixedRandom:
        return schedule.isNotEmpty;
      case ScheduleMode.manual:
        return members.length >= 2;
      case ScheduleMode.randomEach:
        return activeReceiverId != null ||
            completedReceiverIds.isNotEmpty ||
            currentPeriod > 0;
    }
  }

  bool get canCollectPayments => currentReceiverId != null;

  String? get currentReceiverId {
    switch (scheduleMode) {
      case ScheduleMode.fixedRandom:
        if (discretionaryReceiverOverride != null) {
          return discretionaryReceiverOverride;
        }
        if (schedule.isEmpty || currentPeriod >= schedule.length) return null;
        return schedule[currentPeriod];
      case ScheduleMode.manual:
      case ScheduleMode.randomEach:
        return activeReceiverId;
    }
  }

  /// Navbatdagi rasmiy oluvchi (ixtiyoriy belgilashdan farqli).
  String? get scheduledReceiverId {
    if (scheduleMode != ScheduleMode.fixedRandom) return currentReceiverId;
    if (schedule.isEmpty || currentPeriod >= schedule.length) return null;
    return schedule[currentPeriod];
  }

  bool get isDiscretionaryReceiverActive =>
      scheduleMode == ScheduleMode.fixedRandom &&
      discretionaryReceiverOverride != null;

  /// Ishtirokchi ushbu GAP tsiklida kamida 1 marta jamg'arma olgan.
  bool hasReceivedFund(String memberId) {
    if (!members.containsKey(memberId)) return false;
    if (completedReceiverIds.contains(memberId)) return true;

    switch (scheduleMode) {
      case ScheduleMode.fixedRandom:
        final idx = schedule.indexOf(memberId);
        if (idx >= 0 && idx < currentPeriod) return true;
        for (final p in handedOverPeriods) {
          if (receiverForPeriod(p) == memberId) return true;
        }
        return false;
      case ScheduleMode.manual:
      case ScheduleMode.randomEach:
        return false;
    }
  }

  List<String> get membersWhoReceivedFund =>
      members.keys.where(hasReceivedFund).toList();

  List<String> get membersWhoNotReceivedFund =>
      members.keys.where((id) => !hasReceivedFund(id)).toList();

  /// A'zo barcha davrlarda jamg'armaga qo'shgan jami (asosiy valyutada).
  int totalContributedSettlement(String memberId) {
    var sum = 0;
    for (final periodMap in payments.values) {
      final entry = periodMap[memberId];
      if (entry != null) sum += settlementAmountFor(entry);
    }
    return sum;
  }

  /// A'zo olgan jamg'arma jami (topshirilgan davrlar bo'yicha).
  int totalReceivedSettlement(String memberId) {
    var sum = 0;
    for (final p in handedOverPeriods) {
      if (receiverForPeriod(p) == memberId) {
        sum += fromSettlementAmount(
          expectedTotal,
          receiveCurrencyForMember(memberId),
        );
      }
    }
    return sum;
  }

  List<String> get eligibleReceiverIds =>
      members.keys.where((id) => !hasReceivedFund(id)).toList();

  bool get allMembersReceived =>
      eligibleReceiverIds.isEmpty && members.isNotEmpty;

  /// Oxirgi navbat (topshirilgach GAP yopiladi).
  bool get isFinalGapPeriod {
    if (members.isEmpty) return false;
    switch (scheduleMode) {
      case ScheduleMode.fixedRandom:
        return schedule.isNotEmpty &&
            currentPeriod >= schedule.length - 1;
      case ScheduleMode.manual:
      case ScheduleMode.randomEach:
        return eligibleReceiverIds.length <= 1;
    }
  }

  /// Barcha davrlar topshirilgan va har kim pul olgan — faqat shundan keyin yopiladi.
  bool get isCycleComplete {
    if (isClosed) return true;
    if (members.isEmpty) return false;
    if (!allMembersReceived) return false;
    switch (scheduleMode) {
      case ScheduleMode.fixedRandom:
        if (schedule.isEmpty) return false;
        return handedOverPeriods.length >= schedule.length;
      case ScheduleMode.manual:
      case ScheduleMode.randomEach:
        return completedReceiverIds.length >= members.length &&
            !gapSessionActive;
    }
  }

  String? receiverForPeriod(int period) {
    switch (scheduleMode) {
      case ScheduleMode.fixedRandom:
        if (period == currentPeriod &&
            discretionaryReceiverOverride != null) {
          return discretionaryReceiverOverride;
        }
        if (period < 0 || period >= schedule.length) return null;
        return schedule[period];
      case ScheduleMode.manual:
      case ScheduleMode.randomEach:
        if (period < completedReceiverIds.length) {
          return completedReceiverIds[period];
        }
        if (period == currentPeriod) return activeReceiverId;
        return null;
    }
  }

  /// [payerId] pul olgan davrda [currentReceiverId] unga bergan summa —
  /// hozir shuncha qaytarishi kerak (masalan: Ali Valiga $100 bergan → Vali Aliga $100).
  ReciprocalObligation? reciprocalObligationForPayer({
    required String currentReceiverId,
    required String payerId,
  }) {
    if (currentReceiverId == payerId) return null;

    PaymentEntry? found;
    var foundPeriod = -1;

    for (var p = 0; p < currentPeriod; p++) {
      final pastReceiver = receiverForPeriod(p);
      if (pastReceiver != payerId) continue;
      final entry = payments['$p']?[currentReceiverId];
      if (entry == null) continue;
      if (p > foundPeriod) {
        foundPeriod = p;
        found = entry;
      }
    }

    if (found == null || foundPeriod < 0) return null;

    return ReciprocalObligation(
      entry: found,
      sourcePeriod: foundPeriod,
      payerMemberId: payerId,
      currentReceiverId: currentReceiverId,
    );
  }

  /// Joriy oluvchi pul olgan davrda [payerId] to'lamagan bo'lsa,
  /// o'z navbatida shu kishidan pul olinmaydi.
  bool isPayerExemptFromPayingCurrentReceiver(String payerId) {
    final recv = currentReceiverId;
    if (recv == null || payerId == recv) return false;

    for (var p = 0; p < currentPeriod; p++) {
      final pastReceiver = receiverForPeriod(p);
      if (pastReceiver != payerId) continue;
      if (payments['$p']?[recv] == null) return true;
    }
    return false;
  }

  /// Oldin olgan summani qaytarish majburiyati (yo'q bo'lsa null).
  ReciprocalObligation? mandatoryPaymentFor(String payerId) {
    if (isPayerExemptFromPayingCurrentReceiver(payerId)) return null;
    final recv = currentReceiverId;
    if (recv == null) return null;
    return reciprocalObligationForPayer(
      currentReceiverId: recv,
      payerId: payerId,
    );
  }

  bool periodIsFullyPaid(int period) {
    final receiver = receiverForPeriod(period);
    final pmap = payments['$period'];
    if (pmap == null || pmap.isEmpty) return false;
    var paidPayers = 0;
    for (final id in members.keys) {
      if (id == receiver) continue;
      if (pmap.containsKey(id)) paidPayers++;
    }
    return paidPayers >= payersCount;
  }

  List<int> get completedPeriodIndexes {
    final keys = payments.keys.map((k) => int.tryParse(k)).whereType<int>().toList()
      ..sort();
    return keys;
  }

  String displayNameFor(String memberId) =>
      members[memberId]?.displayName ?? '-';

  String get currentReceiverName {
    final id = currentReceiverId;
    if (id == null) return '-';
    return displayNameFor(id);
  }

  Map<String, PaymentEntry>? get _currentPeriodPayments =>
      payments['$currentPeriod'];

  int get paidCount => _currentPeriodPayments?.length ?? 0;

  int get unpaidPayersCount {
    if (!canCollectPayments) return 0;
    final left = payersCount - paidCount;
    return left > 0 ? left : 0;
  }

  /// Navbat / davr raqami: №1, №2, ...
  static String queueNumber(int oneBased) => '№$oneBased';

  /// Jamg'arma davri raqami: №1, №2, ...
  static String gapPeriodRef(int oneBasedPeriod) => queueNumber(oneBasedPeriod);

  int? get currentReceiverQueuePosition {
    final id = currentReceiverId;
    if (id == null) return null;
    return schedulePositionForMember(id);
  }

  String periodLabelFor(int periodIndex) =>
      '${cycleType.label} ${gapPeriodRef(periodIndex + 1)}';

  /// Joriy jamg'arma davri (masalan: GAP 2/7 yoki GAP n3).
  String get currentGapRoundLabel {
    if (scheduleMode == ScheduleMode.fixedRandom && schedule.isNotEmpty) {
      return 'GAP ${currentPeriod + 1} / ${schedule.length}';
    }
    return 'GAP ${gapPeriodRef(currentPeriod + 1)}';
  }

  /// Joriy davr raqami.
  String get currentPeriodLabel => periodLabelFor(currentPeriod);

  List<String> get currentPeriodPaidPayerNames {
    final receiverId = currentReceiverId;
    final pmap = _currentPeriodPayments;
    if (pmap == null || receiverId == null) return [];
    return pmap.keys.map(displayNameFor).toList();
  }

  int get expectedTotal => payersCount * periodAmount;

  /// Barcha to'lovlar asosiy valyutada (har bir to'lovning kursi bilan).
  int get collectedTotal {
    final p = _currentPeriodPayments;
    if (p == null || p.isEmpty) return 0;
    return p.values.fold(0, (sum, entry) => sum + settlementAmountFor(entry));
  }

  /// Bitta to'lovni asosiy valyutaga (saqlangan yoki guruh kursi bilan).
  int settlementAmountFor(PaymentEntry entry) {
    if (entry.currency == settlementCurrency) return entry.amount;
    final rate = entry.exchangeRate ?? rateFor(entry.currency);
    return (entry.amount * rate).round();
  }

  double effectiveRateFor(PaymentEntry entry) {
    if (entry.currency == settlementCurrency) return 1;
    return entry.exchangeRate ?? rateFor(entry.currency);
  }

  double get paymentProgress {
    if (expectedTotal <= 0) return 0;
    final ratio = collectedTotal / expectedTotal;
    return ratio > 1 ? 1 : ratio;
  }

  PaymentEntry? paymentFor(String payerId, [int? period]) {
    return payments['${period ?? currentPeriod}']?[payerId];
  }

  bool hasPaid(String payerId) => paymentFor(payerId) != null;

  /// A'zo to'laydigan valyuta. null pref → guruh asosiy valyutasi.
  AppCurrency currencyForMember(String memberId) {
    return members[memberId]?.paymentCurrency ?? settlementCurrency;
  }

  /// Navbatda qabul qilish valyutasi. null pref → farqi yo'q (asosiy valyuta).
  AppCurrency receiveCurrencyForMember(String memberId) {
    return members[memberId]?.receiveCurrency ?? settlementCurrency;
  }

  AppCurrency? receivePreferenceFor(String memberId) =>
      members[memberId]?.receiveCurrency;

  AppCurrency? paymentPreferenceFor(String memberId) =>
      members[memberId]?.paymentCurrency;

  /// Joriy pul oluvchi qabul valyutasi.
  AppCurrency get currentReceiverReceiveCurrency {
    final id = currentReceiverId;
    if (id == null) return settlementCurrency;
    return receiveCurrencyForMember(id);
  }

  /// Joriy davr maqsadi — pul oluvchi qabul valyutasida.
  int get expectedTotalForCurrentReceiver {
    final id = currentReceiverId;
    if (id == null) return expectedTotal;
    return fromSettlementAmount(expectedTotal, receiveCurrencyForMember(id));
  }

  /// Tavsiya summa — a'zo to'lov valyutasida.
  int recommendedAmountFor(String memberId) {
    final currency = currencyForMember(memberId);
    return fromSettlementAmount(periodAmount, currency);
  }

  /// 1 [from] = necha [settlementCurrency].
  double rateFor(AppCurrency from) {
    if (from == settlementCurrency) return 1;
    return exchangeRates[from.code] ??
        AppCurrency.rateBetween(from, settlementCurrency);
  }

  int toSettlementAmount(int amount, AppCurrency from) {
    if (from == settlementCurrency) return amount;
    final rate = rateFor(from);
    return (amount * rate).round();
  }

  int fromSettlementAmount(int settlementAmount, AppCurrency to) {
    if (to == settlementCurrency) return settlementAmount;
    final rate = rateFor(to);
    if (rate <= 0) return settlementAmount;
    return (settlementAmount / rate).round();
  }

  /// Valyuta bo'yicha yig'ilgan (asl summalar).
  Map<AppCurrency, int> get collectedByCurrency {
    final p = _currentPeriodPayments;
    final map = <AppCurrency, int>{};
    if (p == null) return map;
    for (final e in p.values) {
      map[e.currency] = (map[e.currency] ?? 0) + e.amount;
    }
    return map;
  }

  /// Asl to'langan summalar (har bir valyutada).
  String? get collectedRawText {
    final p = _currentPeriodPayments;
    if (p == null || p.isEmpty) return null;
    final by = collectedByCurrency;
    return by.entries
        .map((e) => formatMoneySimple(e.value, e.key))
        .join(' + ');
  }

  /// Asl + asosiy valyutada jami ko'rinishi kerakmi.
  bool get showDualTotals {
    final p = _currentPeriodPayments;
    if (p == null || p.isEmpty) return false;
    final by = collectedByCurrency;
    if (by.length > 1) return true;
    if (by.length == 1 && !by.containsKey(settlementCurrency)) return true;
    return p.values.any((e) => e.currency != settlementCurrency);
  }

  @Deprecated('Use collectedRawText')
  String? get collectedBreakdownText => collectedRawText;

  static String formatMoneySimple(int amount, AppCurrency currency) {
    final n = amount.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]} ',
        );
    return '$n ${currency.symbol}';
  }

  /// A'zo joriy masul (kalit yoki bog'langan user bo'yicha).
  bool isResponsibleMember(String memberId) {
    if (memberId == responsibleUserId) return true;
    return members[memberId]?.linkedUserId == responsibleUserId;
  }

  String? memberIdForUser({
    required String userId,
    String? phone,
    List<String>? allPhones,
  }) {
    if (members.containsKey(userId)) return userId;
    final phones = <String>{
      if (phone != null) normalizePhone(phone),
      ...?allPhones?.map(normalizePhone),
    };
    for (final e in members.entries) {
      if (e.value.linkedUserId == userId) return e.key;
      if (e.value.phone != null && phones.contains(e.value.phone)) {
        return e.key;
      }
    }
    return null;
  }

  int? schedulePositionForMember(String? memberId) {
    if (memberId == null) return null;
    if (scheduleMode == ScheduleMode.fixedRandom) {
      final index = schedule.indexOf(memberId);
      return index >= 0 ? index + 1 : null;
    }
    if (activeReceiverId == memberId) return currentPeriod + 1;
    final done = completedReceiverIds.indexOf(memberId);
    if (done >= 0) return done + 1;
    return null;
  }

  bool isReceiver(String memberId) => currentReceiverId == memberId;

  GroupMember? memberByPhone(String phone) {
    final normalized = normalizePhone(phone);
    for (final m in members.values) {
      if (m.phone == normalized) return m;
    }
    return null;
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'responsibleUserId': responsibleUserId,
        'cycleType': cycleType.storageKey,
        'periodAmount': periodAmount,
        'settlementCurrency': settlementCurrency.code,
        'exchangeRates': exchangeRates,
        'inviteCode': inviteCode,
        'members': members.map((k, v) => MapEntry(k, v.toMap())),
        'schedule': schedule,
        'scheduleMode': scheduleMode.storageKey,
        if (activeReceiverId != null) 'activeReceiverId': activeReceiverId,
        'completedReceiverIds': completedReceiverIds,
        'currentPeriod': currentPeriod,
        'payments': payments.map(
          (period, payers) => MapEntry(
            period,
            payers.map((id, entry) => MapEntry(id, entry.toMap())),
          ),
        ),
        'createdAt': (createdAt ?? DateTime.now()).toIso8601String(),
        'isClosed': isClosed,
        if (closedAt != null) 'closedAt': closedAt!.toIso8601String(),
        'membersRosterConfirmed': membersRosterConfirmed,
        if (nextGapDueDate != null)
          'nextGapDueDate': gapDateOnly(nextGapDueDate!).toIso8601String(),
        if (lastGapCollectionDate != null)
          'lastGapCollectionDate':
              gapDateOnly(lastGapCollectionDate!).toIso8601String(),
        'gapSessionActive': gapSessionActive,
        'handedOverPeriods': handedOverPeriods,
        'discretionaryReceiveGrantAvailable': discretionaryReceiveGrantAvailable,
        'discretionaryReceiveGrantUsed': discretionaryReceiveGrantUsed,
        if (discretionaryReceiverOverride != null)
          'discretionaryReceiverOverride': discretionaryReceiverOverride,
        'pendingNewCycleSetup': pendingNewCycleSetup,
        'pendingCycleClosure': pendingCycleClosure,
      };

  factory SavingsGroup.fromMap(Map<dynamic, dynamic> map) {
    final periodAmount = map['periodAmount'] as int? ?? 100;
    final settlement = AppCurrency.fromCode(map['settlementCurrency'] as String?);
    final legacyUsd = map['settlementCurrency'] == null;

    final rawRates = map['exchangeRates'] as Map<dynamic, dynamic>?;
    final exchangeRates = <String, double>{};
    if (rawRates != null && rawRates.isNotEmpty) {
      rawRates.forEach((k, v) {
        if (v is num) exchangeRates[k.toString()] = v.toDouble();
      });
    } else {
      exchangeRates.addAll(_defaultRatesFor(settlement));
    }

    final rawPayments = map['payments'] as Map<dynamic, dynamic>? ?? {};
    final payments = <String, Map<String, PaymentEntry>>{};
    rawPayments.forEach((weekKey, weekValue) {
      if (weekValue is Map) {
        payments[weekKey.toString()] = {};
        weekValue.forEach((id, value) {
          final memberId = id.toString();
          if (value is Map) {
            payments[weekKey.toString()]![memberId] =
                PaymentEntry.fromMap(value);
          } else if (value is int) {
            payments[weekKey.toString()]![memberId] = PaymentEntry.legacy(
              value,
              legacyUsd ? AppCurrency.usd : settlement,
            );
          } else if (value == true) {
            payments[weekKey.toString()]![memberId] = PaymentEntry.legacy(
              periodAmount,
              legacyUsd ? AppCurrency.usd : settlement,
            );
          }
        });
      }
    });

    final members = <String, GroupMember>{};
    final rawMembers = map['members'] as Map<dynamic, dynamic>?;
    if (rawMembers != null && rawMembers.isNotEmpty) {
      rawMembers.forEach((k, v) {
        if (v is Map) {
          members[k.toString()] = GroupMember.fromMap(v);
        }
      });
    } else {
      final legacy = map['memberNames'] as Map<dynamic, dynamic>? ?? {};
      legacy.forEach((k, v) {
        final id = k.toString();
        members[id] = GroupMember(id: id, displayName: v.toString());
      });
    }

    return SavingsGroup(
      id: map['id'] as String,
      name: map['name'] as String,
      responsibleUserId: map['responsibleUserId'] as String,
      cycleType: CycleType.fromString(map['cycleType'] as String?),
      periodAmount: periodAmount,
      inviteCode: map['inviteCode'] as String,
      settlementCurrency: settlement,
      exchangeRates: exchangeRates,
      members: members,
      schedule: List<String>.from(
        (map['schedule'] as List<dynamic>? ?? []).map((e) => e.toString()),
      ),
      scheduleMode: ScheduleMode.fromString(map['scheduleMode'] as String?),
      activeReceiverId: map['activeReceiverId'] as String?,
      completedReceiverIds: List<String>.from(
        (map['completedReceiverIds'] as List<dynamic>? ?? [])
            .map((e) => e.toString()),
      ),
      currentPeriod: map['currentPeriod'] as int? ?? 0,
      payments: payments,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String)
          : null,
      isClosed: map['isClosed'] as bool? ?? false,
      closedAt: map['closedAt'] != null
          ? DateTime.tryParse(map['closedAt'] as String)
          : null,
      membersRosterConfirmed: map['membersRosterConfirmed'] as bool? ?? false,
      nextGapDueDate: _dateFromMap(map['nextGapDueDate']),
      lastGapCollectionDate: _dateFromMap(map['lastGapCollectionDate']),
      gapSessionActive: map['gapSessionActive'] as bool? ?? true,
      handedOverPeriods: List<int>.from(
        (map['handedOverPeriods'] as List<dynamic>? ?? [])
            .map((e) => (e as num).toInt()),
      ),
      discretionaryReceiveGrantAvailable:
          map['discretionaryReceiveGrantAvailable'] as bool? ?? true,
      discretionaryReceiveGrantUsed:
          map['discretionaryReceiveGrantUsed'] as bool? ?? false,
      discretionaryReceiverOverride:
          map['discretionaryReceiverOverride'] as String?,
      pendingNewCycleSetup:
          map['pendingNewCycleSetup'] as bool? ?? false,
      pendingCycleClosure: map['pendingCycleClosure'] as bool? ?? false,
    );
  }

  static DateTime? _dateFromMap(dynamic raw) {
    if (raw == null) return null;
    final parsed = DateTime.tryParse(raw.toString());
    if (parsed == null) return null;
    return gapDateOnly(parsed);
  }
}
