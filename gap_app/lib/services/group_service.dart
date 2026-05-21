import 'dart:math';

import 'package:uuid/uuid.dart';

import '../models/app_currency.dart';
import '../models/cycle_type.dart';
import '../models/group_member.dart';
import '../models/payment_entry.dart';
import '../models/group_membership.dart';
import '../models/member_role.dart';
import '../models/savings_group.dart';
import '../models/schedule_mode.dart';
import '../utils/money_format.dart';
import '../utils/pin_util.dart';
import 'gap_entitlement_service.dart';
import 'local_db_service.dart';

class PhoneMemberLookup {
  PhoneMemberLookup({
    required this.phone,
    this.displayName,
    required this.isRegistered,
  });

  final String phone;
  final String? displayName;
  final bool isRegistered;
}

class GroupService {
  GroupService(this._db, [GapEntitlementService? entitlements])
      : _entitlements = entitlements ?? GapEntitlementService(_db);

  final LocalDbService _db;
  final GapEntitlementService _entitlements;
  final _uuid = const Uuid();

  String _generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random();
    return List.generate(6, (_) => chars[random.nextInt(chars.length)]).join();
  }

  Future<SavingsGroup> createGroup({
    required String userId,
    required String userName,
    required String userPhone,
    required String name,
    required CycleType cycleType,
    required int periodAmount,
    AppCurrency settlementCurrency = AppCurrency.uzs,
    ScheduleMode scheduleMode = ScheduleMode.fixedRandom,
  }) async {
    await _entitlements.consumeCreationCreditIfNeeded(userId);

    final phone = normalizePhone(userPhone);
    final group = SavingsGroup(
      id: _uuid.v4(),
      name: name.trim(),
      responsibleUserId: userId,
      cycleType: cycleType,
      periodAmount: periodAmount,
      settlementCurrency: settlementCurrency,
      scheduleMode: scheduleMode,
      inviteCode: _generateInviteCode(),
      members: {
        userId: GroupMember(
          id: userId,
          displayName: userName,
          phone: phone,
          linkedUserId: userId,
        ),
      },
    );

    await _db.saveGroup(group);
    await _db.saveMembership(
      GroupMembership(
        groupId: group.id,
        userId: userId,
        role: MemberRole.responsible,
      ),
    );
    return group;
  }

  Future<SavingsGroup> joinByInviteCode({
    required String userId,
    required String userName,
    required String userPhone,
    required String inviteCode,
  }) async {
    final group = await _db.findGroupByInviteCode(inviteCode);
    if (group == null) {
      throw Exception('Taklif kodi noto\'g\'ri');
    }

    final phone = normalizePhone(userPhone);
    final existingMember = group.memberByPhone(phone);
    if (existingMember != null) {
      await _linkExistingMemberToUser(
        group: group,
        member: existingMember,
        userId: userId,
        userName: userName,
      );
    } else {
      final existing = await _db.getMembership(group.id, userId);
      if (existing != null) {
        throw Exception('Siz allaqachon bu yig\'imda a\'zosiz');
      }
      group.members[userId] = GroupMember(
        id: userId,
        displayName: userName,
        phone: phone,
        linkedUserId: userId,
      );
      await _db.saveGroup(group);
      await _db.saveMembership(
        GroupMembership(
          groupId: group.id,
          userId: userId,
          role: MemberRole.member,
        ),
      );
    }
    return group;
  }

  Future<PhoneMemberLookup> lookupMemberByPhone(String phone) async {
    final normalized = normalizePhone(phone);
    if (!isValidPhone(phone)) {
      throw Exception('Telefon raqamni to\'g\'ri kiriting');
    }
    final user = await _db.getUserByPhone(normalized);
    return PhoneMemberLookup(
      phone: normalized,
      displayName: user?.name,
      isRegistered: user != null,
    );
  }

  Future<String?> addMemberByPhone({
    required SavingsGroup group,
    required String phone,
    String? displayName,
  }) async {
    final normalized = normalizePhone(phone);
    if (!isValidPhone(phone)) return 'Telefon raqamni to\'g\'ri kiriting';

    final existing = group.memberByPhone(normalized);
    if (existing != null) {
      return '${existing.displayName} allaqachon ro\'yxatda';
    }

    final user = await _db.getUserByPhone(normalized);
    final name = (user?.name ?? displayName?.trim() ?? '');
    if (name.length < 2) {
      return 'Ism familiyani kiriting';
    }

    final memberId =
        user?.id ?? GroupMember.pendingIdForPhone(normalized);
    if (group.isResponsibleMember(memberId)) {
      return 'Masul allaqachon guruhda';
    }

    group.members[memberId] = GroupMember(
      id: memberId,
      displayName: name,
      phone: normalized,
      linkedUserId: user?.id,
    );
    await _db.saveGroup(group);

    if (user != null) {
      final membership = await _db.getMembership(group.id, user.id);
      if (membership == null) {
        await _db.saveMembership(
          GroupMembership(
            groupId: group.id,
            userId: user.id,
            role: MemberRole.member,
          ),
        );
      }
    }
    return null;
  }

  Future<void> _linkExistingMemberToUser({
    required SavingsGroup group,
    required GroupMember member,
    required String userId,
    required String userName,
  }) async {
    final oldId = member.id;
    group.members.remove(oldId);
    group.members[userId] = GroupMember(
      id: userId,
      displayName: userName,
      phone: member.phone,
      linkedUserId: userId,
    );
    _replaceMemberId(group, oldId, userId);
    await _db.saveGroup(group);

    final membership = await _db.getMembership(group.id, userId);
    if (membership == null) {
      await _db.saveMembership(
        GroupMembership(
          groupId: group.id,
          userId: userId,
          role: MemberRole.member,
        ),
      );
    }
  }

  void _replaceMemberId(SavingsGroup group, String oldId, String newId) {
    group.schedule =
        group.schedule.map((id) => id == oldId ? newId : id).toList();
    final newPayments = <String, Map<String, PaymentEntry>>{};
    group.payments.forEach((period, payers) {
      newPayments[period] = {};
      payers.forEach((id, entry) {
        newPayments[period]![id == oldId ? newId : id] = entry;
      });
    });
    group.payments = newPayments;
  }

  Future<String?> confirmMembersRoster(SavingsGroup group) async {
    if (group.members.length < 2) {
      return 'Kamida 2 ta a\'zo kerak';
    }
    if (group.membersRosterConfirmed) {
      return 'A\'zolar allaqachon tasdiqlangan';
    }
    group.membersRosterConfirmed = true;
    await _db.saveGroup(group);
    return null;
  }

  /// Joriy masul boshqaruvni boshqa ishtirokchiga topshiradi.
  Future<String?> transferResponsibility({
    required SavingsGroup group,
    required String fromUserId,
    required String newMemberId,
  }) async {
    final fromMemberId =
        group.memberIdForUser(userId: fromUserId) ?? fromUserId;
    if (!group.isResponsibleMember(fromMemberId)) {
      return 'Faqat joriy masul topshira oladi';
    }
    if (!group.members.containsKey(newMemberId)) {
      return 'A\'zo topilmadi';
    }
    if (group.isResponsibleMember(newMemberId)) {
      return 'Bu ishtirokchi allaqachon masul';
    }

    final newMember = group.members[newMemberId]!;
    final newUserId = newMember.linkedUserId;
    if (newUserId == null) {
      return 'Masullikni faqat ilovaga kirgan a\'zoga topshirish mumkin';
    }
    if (newUserId == fromUserId) {
      return 'O\'zingizga topshirib bo\'lmaydi';
    }

    final oldMembership = await _db.getMembership(group.id, fromUserId);
    final newMembership = await _db.getMembership(group.id, newUserId);

    await _db.saveMembership(
      GroupMembership(
        groupId: group.id,
        userId: fromUserId,
        role: MemberRole.member,
        joinedAt: oldMembership?.joinedAt,
      ),
    );

    await _db.saveMembership(
      GroupMembership(
        groupId: group.id,
        userId: newUserId,
        role: MemberRole.responsible,
        joinedAt: newMembership?.joinedAt ?? DateTime.now(),
      ),
    );

    group.responsibleUserId = newUserId;
    await _db.saveGroup(group);
    return null;
  }

  Future<void> removeMember(SavingsGroup group, String memberId) async {
    if (group.isResponsibleMember(memberId)) {
      throw Exception('Masulni o\'chirib bo\'lmaydi');
    }
    final member = group.members[memberId];
    group.members.remove(memberId);
    group.schedule.remove(memberId);
    group.completedReceiverIds.remove(memberId);
    if (group.activeReceiverId == memberId) {
      group.activeReceiverId = null;
    }
    for (final period in group.payments.values) {
      period.remove(memberId);
    }
    if (group.currentPeriod >= group.schedule.length &&
        group.schedule.isNotEmpty) {
      group.currentPeriod = 0;
    }
    await _db.saveGroup(group);
    if (member?.linkedUserId != null) {
      await _db.deleteMembership(group.id, member!.linkedUserId!);
    }
  }

  void _resetPeriodState(SavingsGroup group) {
    group.currentPeriod = 0;
    group.activeReceiverId = null;
    group.completedReceiverIds = [];
    group.payments = {'0': {}};
    group.discretionaryReceiveGrantAvailable = true;
    group.discretionaryReceiveGrantUsed = false;
    group.discretionaryReceiverOverride = null;
  }

  Future<String?> setScheduleMode(
    SavingsGroup group,
    ScheduleMode mode, {
    bool resetState = true,
  }) async {
    if (resetState && group.members.length < 2) {
      return 'Kamida 2 ta a\'zo kerak';
    }
    group.scheduleMode = mode;
    if (resetState) {
      group.schedule = [];
      _resetPeriodState(group);
    }
    await _db.saveGroup(group);
    return null;
  }

  /// GAP navbat: barcha a'zolar tasodifiy tartibda. [firstReceiverId] ixtiyoriy.
  Future<String?> createFixedSchedule(
    SavingsGroup group, {
    String? firstReceiverId,
    List<String>? predeterminedOrder,
  }) async {
    if (group.members.length < 2) return 'Kamida 2 ta a\'zo kerak';

    final List<String> ordered;
    if (predeterminedOrder != null && predeterminedOrder.isNotEmpty) {
      if (predeterminedOrder.length != group.members.length ||
          !predeterminedOrder.every(group.members.containsKey)) {
        return 'Navbat ro\'yxati noto\'g\'ri';
      }
      ordered = List<String>.from(predeterminedOrder);
    } else {
      final random = Random.secure();
      ordered = <String>[];

      if (firstReceiverId != null) {
        if (!group.members.containsKey(firstReceiverId)) {
          return 'Tanlangan a\'zo topilmadi';
        }
        final rest = group.members.keys
            .where((id) => id != firstReceiverId)
            .toList();
        for (var i = rest.length - 1; i > 0; i--) {
          final j = random.nextInt(i + 1);
          final t = rest[i];
          rest[i] = rest[j];
          rest[j] = t;
        }
        ordered.addAll([firstReceiverId, ...rest]);
      } else {
        ordered.addAll(group.members.keys);
        for (var i = ordered.length - 1; i > 0; i--) {
          final j = random.nextInt(i + 1);
          final t = ordered[i];
          ordered[i] = ordered[j];
          ordered[j] = t;
        }
      }
    }

    group.scheduleMode = ScheduleMode.fixedRandom;
    group.schedule = ordered;
    group.activeReceiverId = null;
    group.completedReceiverIds = [];
    group.currentPeriod = 0;
    group.payments = {};
    for (var i = 0; i < group.schedule.length; i++) {
      group.payments['$i'] = {};
    }
    group.discretionaryReceiveGrantAvailable = true;
    group.discretionaryReceiveGrantUsed = false;
    group.discretionaryReceiverOverride = null;
    await _db.saveGroup(group);
    return null;
  }

  /// GAP navbat: 1 marta istalgan ishtirokchiga joriy davr uchun pul olish huquqi.
  Future<String?> grantDiscretionaryReceive(
    SavingsGroup group,
    String memberId,
  ) async {
    if (group.scheduleMode != ScheduleMode.fixedRandom) {
      return 'Faqat GAP navbat usulida';
    }
    if (!group.discretionaryReceiveGrantAvailable) {
      return 'Ixtiyoriy huquq mavjud emas';
    }
    if (group.discretionaryReceiveGrantUsed) {
      return 'Ixtiyoriy huquq allaqachon ishlatilgan';
    }
    if (!group.members.containsKey(memberId)) return 'A\'zo topilmadi';
    if (group.hasReceivedFund(memberId)) {
      return 'Bu a\'zo allaqachon pul olgan';
    }
    group.discretionaryReceiverOverride = memberId;
    group.discretionaryReceiveGrantUsed = true;
    group.payments.putIfAbsent('${group.currentPeriod}', () => {});
    await _db.saveGroup(group);
    return null;
  }

  @Deprecated('Use createFixedSchedule')
  Future<String?> createSchedule(SavingsGroup group) async {
    return createFixedSchedule(group);
  }

  Future<String?> setActiveReceiver(
    SavingsGroup group,
    String memberId,
  ) async {
    if (!group.members.containsKey(memberId)) return 'A\'zo topilmadi';
    if (group.hasReceivedFund(memberId)) {
      return 'Bu a\'zo allaqachon pul olgan';
    }
    group.activeReceiverId = memberId;
    group.payments.putIfAbsent('${group.currentPeriod}', () => {});
    await _db.saveGroup(group);
    return null;
  }

  Future<String?> pickRandomReceiver(
    SavingsGroup group, {
    String? memberId,
  }) async {
    final eligible = group.eligibleReceiverIds;
    if (eligible.isEmpty) {
      return 'Barcha ishtirokchilar pul olgan';
    }

    final pick = memberId != null && eligible.contains(memberId)
        ? memberId
        : eligible[Random.secure().nextInt(eligible.length)];
    group.activeReceiverId = pick;
    group.payments.putIfAbsent('${group.currentPeriod}', () => {});
    await _db.saveGroup(group);
    return null;
  }

  Future<String?> makePayment(
    SavingsGroup group,
    String payerId,
    int amount,
    AppCurrency currency, {
    double? exchangeRate,
  }) async {
    if (group.isClosed) return 'Jamg\'arma yopilgan';
    if (!group.gapSessionActive) {
      return 'GAP hali boshlanmagan. Masul START tugmasini bosing.';
    }
    if (group.isCurrentPeriodHandedOver) {
      return 'Bu GAP davri yopilgan';
    }
    if (!group.canCollectPayments) return 'Avval pul oluvchini belgilang';
    if (amount < 1) return 'Summa kamida 1 bo\'lishi kerak';
    if (amount > 100000000000) return 'Summa juda katta';

    final receiverId = group.currentReceiverId;
    if (payerId == receiverId) return 'Pul oluvchi to\'lamaydi';
    if (group.isPayerExemptFromPayingCurrentReceiver(payerId)) {
      return 'Bu ishtirokchi oldin pul oluvchiga to\'lamagan — '
          'o\'z navbatida undan pul olinmaydi';
    }

    final mandatory = group.mandatoryPaymentFor(payerId);
    if (mandatory != null) {
      double? rateCheck = exchangeRate;
      if (currency != group.settlementCurrency) {
        rateCheck ??= group.rateFor(currency);
      }
      final entry = PaymentEntry(
        amount: amount,
        currency: currency,
        exchangeRate: rateCheck,
      );
      final paidSettlement = group.settlementAmountFor(entry);
      final requiredSettlement = group.settlementAmountFor(mandatory.entry);
      if (paidSettlement < requiredSettlement) {
        return 'Majburiy to\'lov: kamida '
            '${formatMoney(mandatory.entry.amount, mandatory.entry.currency)}';
      }
    }

    double? rate = exchangeRate;
    if (currency != group.settlementCurrency) {
      rate ??= group.rateFor(currency);
      if (rate <= 0) return 'Valyuta kursi noto\'g\'ri';
    } else {
      rate = null;
    }

    final key = '${group.currentPeriod}';
    group.payments.putIfAbsent(key, () => {});
    group.payments[key]![payerId] = PaymentEntry(
      amount: amount,
      currency: currency,
      exchangeRate: rate,
    );
    await _db.saveGroup(group);
    await _tryCloseIfComplete(group);
    return null;
  }

  Future<String?> handOverFund(SavingsGroup group, {bool force = false}) async {
    if (group.isClosed) return 'Jamg\'arma yopilgan';
    if (!group.isScheduleConfigured) return 'Avval navbatni sozlang';
    if (!group.gapSessionActive) return 'GAP sessiyasi faol emas';
    if (group.isCurrentPeriodHandedOver) return 'Bu GAP allaqachon yopilgan';
    if (!group.canCollectPayments) {
      return 'Pul oluvchi belgilanmagan';
    }

    final mandatoryUnpaid = group.mandatoryUnpaidPayerIds;
    if (!force && mandatoryUnpaid.isNotEmpty) {
      return 'mandatory:${mandatoryUnpaid.length}';
    }

    final period = group.currentPeriod;
    if (!group.handedOverPeriods.contains(period)) {
      group.handedOverPeriods.add(period);
    }
    group.gapSessionActive = false;
    group.markGapCollectedToday();
    group.nextGapDueDate = null;
    group.discretionaryReceiverOverride = null;

    await _advanceAfterHandover(group);
    if (group.pendingCycleClosure) {
      await finalizeCycleClosure(group);
      return '__group_closed__';
    }
    await _db.saveGroup(group);
    return null;
  }

  Future<String?> startGapSession(SavingsGroup group) async {
    if (group.isClosed) return 'Jamg\'arma yopilgan';
    if (group.gapSessionActive) return 'GAP allaqachon boshlangan';
    if (!group.isScheduleConfigured) return 'Avval navbatni sozlang';
    if (!group.isWaitingForNextGap) {
      return 'GAP allaqachon boshlangan';
    }
    if (group.pendingNewCycleSetup) {
      if (!group.isNewCycleSetupReady) {
        return 'Avval a\'zolar, navbat turini va navbatni sozlang';
      }
    } else if (group.lastGapCollectionDate == null) {
      return 'Avval joriy jamg\'armani topshiring';
    }

    group.pendingNewCycleSetup = false;
    group.gapSessionActive = true;
    group.payments.putIfAbsent('${group.currentPeriod}', () => {});
    await _db.saveGroup(group);
    return null;
  }

  /// Topshirishdan keyin navbat/davrni yangilash. true = jamg'arma yopildi.
  Future<bool> _advanceAfterHandover(SavingsGroup group) async {
    switch (group.scheduleMode) {
      case ScheduleMode.fixedRandom:
        if (group.schedule.isEmpty) return false;
        final receiver = group.currentReceiverId;
        if (receiver != null &&
            !group.completedReceiverIds.contains(receiver)) {
          group.completedReceiverIds.add(receiver);
        }
        if (group.currentPeriod >= group.schedule.length - 1) {
          group.pendingCycleClosure = true;
          return true;
        }
        group.discretionaryReceiverOverride = null;
        group.currentPeriod++;
        group.payments.putIfAbsent('${group.currentPeriod}', () => {});
        await _tryCloseIfComplete(group);
        return group.isClosed;

      case ScheduleMode.manual:
      case ScheduleMode.randomEach:
        if (group.activeReceiverId != null &&
            !group.completedReceiverIds.contains(group.activeReceiverId)) {
          group.completedReceiverIds.add(group.activeReceiverId!);
        }
        group.activeReceiverId = null;
        group.discretionaryReceiverOverride = null;
        group.currentPeriod++;
        group.payments.putIfAbsent('${group.currentPeriod}', () => {});
        if (_wouldCompleteCycle(group)) {
          group.pendingCycleClosure = true;
          return true;
        }
        return false;
    }
  }

  bool _wouldCompleteCycle(SavingsGroup group) {
    if (group.members.isEmpty) return false;
    if (!group.allMembersReceived) return false;
    if (group.gapSessionActive) return false;
    switch (group.scheduleMode) {
      case ScheduleMode.fixedRandom:
        return group.schedule.isNotEmpty &&
            group.handedOverPeriods.length >= group.schedule.length;
      case ScheduleMode.manual:
      case ScheduleMode.randomEach:
        return group.completedReceiverIds.length >= group.members.length;
    }
  }

  /// Qayta yoqish bekor qilinganda oxirgi topshirishni qaytaradi.
  Future<String?> rollbackPendingCycleClosure(SavingsGroup group) async {
    if (!group.pendingCycleClosure) return null;

    group.pendingCycleClosure = false;
    group.isClosed = false;
    group.closedAt = null;
    group.gapSessionActive = true;

    switch (group.scheduleMode) {
      case ScheduleMode.fixedRandom:
        // Oxirgi davrda currentPeriod oshirilmaydi — faqat topshirishni bekor qilish.
        group.handedOverPeriods.remove(group.currentPeriod);
        if (group.completedReceiverIds.isNotEmpty) {
          group.completedReceiverIds.removeLast();
        }
        break;
      case ScheduleMode.manual:
      case ScheduleMode.randomEach:
        if (group.currentPeriod > 0) {
          group.currentPeriod--;
        }
        group.handedOverPeriods.remove(group.currentPeriod);
        if (group.completedReceiverIds.isNotEmpty) {
          group.activeReceiverId = group.completedReceiverIds.removeLast();
        }
        break;
    }

    await _db.saveGroup(group);
    return null;
  }

  Future<void> finalizeCycleClosure(SavingsGroup group) async {
    if (!group.pendingCycleClosure) return;
    group.pendingCycleClosure = false;
    await _closeGroup(group);
  }

  Future<String?> setNextGapDueDate(SavingsGroup group, DateTime date) async {
    if (group.isClosed) return 'Jamg\'arma yopilgan';
    final picked = DateTime(date.year, date.month, date.day);
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    if (picked.isBefore(todayOnly)) {
      return 'O\'tgan kunni tanlab bo\'lmaydi';
    }
    if (!group.isWaitingForNextGap &&
        group.nextGapDueDate == null &&
        group.lastGapCollectionDate == null) {
      return 'Avval joriy GAPni topshiring';
    }
    group.nextGapDueDate = picked;
    await _db.saveGroup(group);
    return null;
  }

  void _markPeriodCollected(SavingsGroup group) {
    group.markGapCollectedToday();
    group.nextGapDueDate = null;
  }

  Future<void> _closeGroup(SavingsGroup group) async {
    if (group.isClosed) return;
    group.isClosed = true;
    group.closedAt = DateTime.now();
    group.gapSessionActive = false;
    await _db.saveGroup(group);
  }

  /// Barcha ishtirokchilar pul olgach — yangi tsikl uchun qayta yoqish.
  Future<String?> reactivateGroup(SavingsGroup group) async {
    if (group.pendingCycleClosure) {
      await finalizeCycleClosure(group);
    }
    if (!group.isClosed) return 'GAP hali faol';
    group.isClosed = false;
    group.closedAt = null;
    group.gapSessionActive = false;
    group.currentPeriod = 0;
    group.handedOverPeriods = [];
    group.completedReceiverIds = [];
    group.activeReceiverId = null;
    group.schedule = [];
    group.payments = {};
    group.nextGapDueDate = null;
    group.lastGapCollectionDate = null;
    group.discretionaryReceiveGrantAvailable = true;
    group.discretionaryReceiveGrantUsed = false;
    group.discretionaryReceiverOverride = null;
    group.membersRosterConfirmed = false;
    group.pendingNewCycleSetup = true;
    await _db.saveGroup(group);
    return null;
  }

  Future<void> _tryCloseIfComplete(SavingsGroup group) async {
    if (!group.isClosed && group.isCycleComplete) {
      await _closeGroup(group);
    }
  }

  Future<void> setMemberPaymentCurrency(
    SavingsGroup group,
    String memberId,
    AppCurrency? currency,
  ) async {
    final m = group.members[memberId];
    if (m == null) return;
    m.paymentCurrency = currency;
    await _db.saveGroup(group);
  }

  Future<void> setMemberReceiveCurrency(
    SavingsGroup group,
    String memberId,
    AppCurrency? currency,
  ) async {
    final m = group.members[memberId];
    if (m == null) return;
    m.receiveCurrency = currency;
    await _db.saveGroup(group);
  }

  Future<void> setExchangeRates(
    SavingsGroup group,
    Map<String, double> rates,
  ) async {
    group.exchangeRates.addAll(rates);
    await _db.saveGroup(group);
  }

  Future<void> setSettlementCurrency(
    SavingsGroup group,
    AppCurrency currency,
  ) async {
    group.settlementCurrency = currency;
    final rates = <String, double>{};
    for (final c in AppCurrency.values) {
      if (c == currency) continue;
      rates[c.code] = AppCurrency.rateBetween(c, currency);
    }
    group.exchangeRates = rates;
    await _db.saveGroup(group);
  }

  Future<String> nextPeriod(SavingsGroup group, {bool force = false}) async {
    if (group.isClosed) return 'Jamg\'arma allaqachon yopilgan';
    if (!group.isScheduleConfigured) return 'Avval navbat turini sozlang';
    if (!group.canCollectPayments) return 'Joriy davrda pul oluvchi belgilanmagan';

    final unpaid = group.payersCount - group.paidCount;
    if (!force && unpaid > 0) return 'unpaid:$unpaid';

    _markPeriodCollected(group);

    switch (group.scheduleMode) {
      case ScheduleMode.fixedRandom:
        if (group.schedule.isEmpty) return 'GAP navbat yaratilmagan';
        if (group.currentPeriod >= group.schedule.length - 1) {
          if (!force && !group.periodIsFullyPaid(group.currentPeriod)) {
            return 'Oxirgi davr to\'lovlari tugamagan';
          }
          await _closeGroup(group);
          return 'Jamg\'arma yakunlandi va yopildi';
        }
        group.currentPeriod++;
        group.payments.putIfAbsent('${group.currentPeriod}', () => {});
        await _db.saveGroup(group);
        await _tryCloseIfComplete(group);
        return 'Keyingi ${group.cycleType.periodLabel}. Pul oluvchi: ${group.currentReceiverName}';

      case ScheduleMode.manual:
      case ScheduleMode.randomEach:
        if (group.activeReceiverId == null) {
          return 'Joriy davrda pul oluvchi belgilanmagan';
        }
        if (!group.completedReceiverIds.contains(group.activeReceiverId)) {
          group.completedReceiverIds.add(group.activeReceiverId!);
        }
        group.activeReceiverId = null;
        group.currentPeriod++;
        group.payments.putIfAbsent('${group.currentPeriod}', () => {});
        await _db.saveGroup(group);
        await _tryCloseIfComplete(group);
        if (group.isClosed) {
          return 'Jamg\'arma yakunlandi va yopildi';
        }
        if (group.scheduleMode == ScheduleMode.randomEach) {
          return 'Keyingi ${group.cycleType.periodLabel}. "Tasodifiy tanlash" tugmasini bosing.';
        }
        return 'Keyingi ${group.cycleType.periodLabel}. Pul oluvchini tanlang.';
    }
  }

  Future<void> setPeriodAmount(SavingsGroup group, int amount) async {
    group.periodAmount = amount;
    await _db.saveGroup(group);
  }

  Future<void> setCycleType(SavingsGroup group, CycleType type) async {
    group.cycleType = type;
    await _db.saveGroup(group);
  }
}
