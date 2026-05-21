import 'package:flutter/foundation.dart' show ChangeNotifier, debugPrint;

import '../models/app_currency.dart';
import '../models/cycle_type.dart';
import '../models/schedule_mode.dart';
import '../models/group_membership.dart';
import '../models/gap_creation_eligibility.dart';
import '../utils/pin_util.dart';
import '../models/member_group_summary.dart';
import '../models/savings_group.dart';
import '../services/gap_entitlement_service.dart';
import '../services/gap_notification_service.dart';
import '../services/group_service.dart';
import '../services/local_db_service.dart';
import '../services/member_link_service.dart';

class GroupListItem {
  GroupListItem({
    required this.group,
    required this.membership,
    required this.memberId,
  });

  final SavingsGroup group;
  final GroupMembership membership;
  final String memberId;

  bool get isResponsible => membership.role.isResponsible;
  int? get mySchedulePosition => group.schedulePositionForMember(memberId);
  MemberGroupSummary get mySummary =>
      MemberGroupSummary.forMember(group, memberId);
}

class GroupsProvider extends ChangeNotifier {
  GroupsProvider(this._db, this._groupService, this._memberLink)
      : _entitlements = GapEntitlementService(_db);

  final LocalDbService _db;
  final GroupService _groupService;
  final MemberLinkService _memberLink;
  final GapEntitlementService _entitlements;

  List<GroupListItem> myGroups = [];
  List<GroupListItem> get activeGroups =>
      myGroups.where((g) => !g.group.isClosed).toList();
  List<GroupListItem> get closedGroups =>
      myGroups.where((g) => g.group.isClosed).toList();
  List<GroupListItem> get responsibleGroups =>
      activeGroups.where((g) => g.isResponsible).toList();
  List<GroupListItem> get participantGroups =>
      activeGroups.where((g) => !g.isResponsible).toList();

  SavingsGroup? activeGroup;
  GroupMembership? activeMembership;
  String? activeMemberId;
  bool isLoading = false;

  bool get canEditActive =>
      (activeMembership?.role.canEdit ?? false) &&
      !(activeGroup?.isClosed ?? false);
  bool get isResponsibleActive => activeMembership?.role.isResponsible ?? false;

  Future<void> loadMyGroups(String userId, {String? phone}) async {
    isLoading = true;
    notifyListeners();

    try {
      final user = await _db.getUserById(userId);
      final allPhones =
          user?.allPhones ?? (phone != null ? [normalizePhone(phone)] : <String>[]);

      if (allPhones.isNotEmpty) {
        final name = user?.name ?? '';
        for (final p in allPhones) {
          await _memberLink.linkPhoneToUser(
            phone: p,
            userId: userId,
            userName: name,
          );
        }
      }

      final memberships = await _db.membershipsForUser(userId);
      final items = <GroupListItem>[];
      for (final m in memberships) {
        final g = await _db.getGroup(m.groupId);
        if (g == null) continue;
        final memberId = g.memberIdForUser(
              userId: userId,
              phone: phone,
              allPhones: allPhones,
            ) ??
            userId;
        items.add(GroupListItem(group: g, membership: m, memberId: memberId));
      }
      myGroups = items;
      try {
        await GapNotificationService.instance
            .syncAll(items.map((e) => e.group));
      } catch (e) {
        debugPrint('GAP notification sync: $e');
      }
    } catch (e) {
      debugPrint('loadMyGroups failed: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> selectGroup(String groupId, String userId, {String? phone}) async {
    activeGroup = await _db.getGroup(groupId);
    activeMembership = await _db.getMembership(groupId, userId);
    final user = await _db.getUserById(userId);
    activeMemberId = activeGroup?.memberIdForUser(
      userId: userId,
      phone: phone,
      allPhones: user?.allPhones,
    );
    notifyListeners();
  }

  void clearActive() {
    activeGroup = null;
    activeMembership = null;
    activeMemberId = null;
    notifyListeners();
  }

  Future<PhoneMemberLookup> lookupPhone(String phone) =>
      _groupService.lookupMemberByPhone(phone);

  Future<GapCreationEligibility> creationEligibility(String userId) =>
      _entitlements.eligibilityFor(userId);

  /// Qo‘shimcha GAP slotini sotib olish (hozircha mahalliy tasdiqlash).
  Future<String?> purchaseGapCreationSlot(String userId) async {
    try {
      await _entitlements.grantCreationCredit(userId);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> createGroup({
    required String userId,
    required String userName,
    required String userPhone,
    required String name,
    required CycleType cycleType,
    required int periodAmount,
    AppCurrency settlementCurrency = AppCurrency.uzs,
    ScheduleMode scheduleMode = ScheduleMode.fixedRandom,
  }) async {
    try {
      final g = await _groupService.createGroup(
        userId: userId,
        userName: userName,
        userPhone: userPhone,
        name: name,
        cycleType: cycleType,
        periodAmount: periodAmount,
        settlementCurrency: settlementCurrency,
        scheduleMode: scheduleMode,
      );
      await loadMyGroups(userId, phone: userPhone);
      await selectGroup(g.id, userId, phone: userPhone);
      return null;
    } on GapCreationPaymentRequired {
      return 'payment_required';
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  Future<String?> joinGroup({
    required String userId,
    required String userName,
    required String userPhone,
    required String inviteCode,
  }) async {
    try {
      final g = await _groupService.joinByInviteCode(
        userId: userId,
        userName: userName,
        userPhone: userPhone,
        inviteCode: inviteCode,
      );
      await loadMyGroups(userId, phone: userPhone);
      await selectGroup(g.id, userId, phone: userPhone);
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  Future<void> refreshActive() async {
    final id = activeGroup?.id;
    if (id == null) return;
    activeGroup = await _db.getGroup(id);
    if (activeGroup != null &&
        activeGroup!.pendingCycleClosure &&
        !activeGroup!.isClosed) {
      await _groupService.finalizeCycleClosure(activeGroup!);
      activeGroup = await _db.getGroup(id);
    }
    notifyListeners();
  }

  Future<String?> addMemberByPhone(String phone, {String? displayName}) async {
    if (activeGroup == null || !canEditActive) {
      return 'Faqat masul a\'zo qo\'sha oladi';
    }
    final err = await _groupService.addMemberByPhone(
      group: activeGroup!,
      phone: phone,
      displayName: displayName,
    );
    if (err != null) return err;
    await refreshActive();
    return null;
  }

  Future<String?> transferResponsibility(
    String newMemberId, {
    required String actingUserId,
    String? phone,
  }) async {
    if (!isResponsibleActive) return 'Faqat masul topshira oladi';
    final g = activeGroup!;
    final myMemberId = g.memberIdForUser(userId: actingUserId, phone: phone) ??
        actingUserId;
    if (!g.isResponsibleMember(myMemberId)) {
      return 'Faqat joriy masul topshira oladi';
    }

    final err = await _groupService.transferResponsibility(
      group: g,
      fromUserId: actingUserId,
      newMemberId: newMemberId,
    );
    if (err != null) return err;

    await loadMyGroups(actingUserId, phone: phone);
    await selectGroup(g.id, actingUserId, phone: phone);
    notifyListeners();
    return null;
  }

  Future<String?> confirmMembersRoster() async {
    if (!canEditActive) return 'Faqat masul tasdiqlaydi';
    final err = await _groupService.confirmMembersRoster(activeGroup!);
    if (err != null) return err;
    await refreshActive();
    return null;
  }

  Future<String?> removeMember(String memberId) async {
    if (!canEditActive) return 'Ruxsat yo\'q';
    try {
      await _groupService.removeMember(activeGroup!, memberId);
      await refreshActive();
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  Future<String?> setScheduleMode(
    ScheduleMode mode, {
    bool resetState = true,
  }) async {
    if (!canEditActive) return 'Faqat masul sozlaydi';
    final err = await _groupService.setScheduleMode(
      activeGroup!,
      mode,
      resetState: resetState,
    );
    if (err != null) return err;
    await refreshActive();
    return null;
  }

  Future<String?> createFixedSchedule({
    String? firstReceiverId,
    List<String>? predeterminedOrder,
  }) async {
    if (!canEditActive) return 'Faqat masul navbat yaratadi';
    final err = await _groupService.createFixedSchedule(
      activeGroup!,
      firstReceiverId: firstReceiverId,
      predeterminedOrder: predeterminedOrder,
    );
    if (err != null) return err;
    await refreshActive();
    return null;
  }

  Future<String?> createSchedule() => createFixedSchedule();

  Future<String?> setActiveReceiver(String memberId) async {
    if (!canEditActive) return 'Faqat masul belgilaydi';
    final err = await _groupService.setActiveReceiver(activeGroup!, memberId);
    if (err != null) return err;
    await refreshActive();
    return null;
  }

  Future<String?> pickRandomReceiver({String? memberId}) async {
    if (!canEditActive) return 'Faqat masul tanlaydi';
    final err = await _groupService.pickRandomReceiver(
      activeGroup!,
      memberId: memberId,
    );
    if (err != null) return err;
    await refreshActive();
    return null;
  }

  Future<String?> grantDiscretionaryReceive(String memberId) async {
    if (!canEditActive) return 'Faqat masul belgilaydi';
    final err = await _groupService.grantDiscretionaryReceive(
      activeGroup!,
      memberId,
    );
    if (err != null) return err;
    await refreshActive();
    return null;
  }

  Future<String?> makePayment(
    String payerId,
    int amount,
    AppCurrency currency, {
    double? exchangeRate,
  }) async {
    if (activeGroup == null) return 'Jamg\'arma tanlanmagan';
    if (!canEditActive) {
      return 'To\'lovni faqat masul qayd etadi';
    }

    final err = await _groupService.makePayment(
      activeGroup!,
      payerId,
      amount,
      currency,
      exchangeRate: exchangeRate,
    );
    if (err != null) return err;
    await refreshActive();
    return null;
  }

  Future<String?> handOverFund({bool force = false}) async {
    if (!canEditActive) return 'Faqat masul topshiradi';
    final err = await _groupService.handOverFund(
      activeGroup!,
      force: force,
    );
    await refreshActive();
    if (err != null) return err;
    if (activeGroup?.isClosed == true) return '__group_closed__';
    return null;
  }

  Future<String?> rollbackPendingCycleClosure() async {
    if (!isResponsibleActive) return 'Faqat masul';
    final err =
        await _groupService.rollbackPendingCycleClosure(activeGroup!);
    if (err != null) return err;
    await refreshActive();
    return null;
  }

  Future<String?> startGapSession() async {
    if (!canEditActive) return 'Faqat masul boshlaydi';
    final err = await _groupService.startGapSession(activeGroup!);
    if (err != null) return err;
    await refreshActive();
    return null;
  }

  Future<String?> reactivateGroup() async {
    if (!isResponsibleActive) return 'Faqat masul qayta yoqadi';
    final err = await _groupService.reactivateGroup(activeGroup!);
    if (err != null) return err;
    await refreshActive();
    return null;
  }

  Future<String?> setNextGapDueDate(DateTime date) async {
    if (!canEditActive) return 'Faqat masul belgilaydi';
    final err =
        await _groupService.setNextGapDueDate(activeGroup!, date);
    if (err != null) return err;
    await refreshActive();
    await GapNotificationService.instance.scheduleForGroup(activeGroup!);
    return null;
  }

  Future<String?> setPeriodAmount(int amount) async {
    if (!canEditActive) return 'Faqat masul o\'zgartiradi';
    if (amount < 1 || amount > 100000000000) {
      return 'Summa noto\'g\'ri';
    }
    await _groupService.setPeriodAmount(activeGroup!, amount);
    await refreshActive();
    return null;
  }

  Future<String?> setCycleType(CycleType type) async {
    if (!canEditActive) return 'Faqat masul o\'zgartiradi';
    await _groupService.setCycleType(activeGroup!, type);
    await refreshActive();
    return null;
  }

  Future<String?> setMemberPaymentCurrency(
    String memberId,
    AppCurrency? currency,
  ) async {
    if (!canEditActive) return 'Faqat masul o\'zgartiradi';
    await _groupService.setMemberPaymentCurrency(
      activeGroup!,
      memberId,
      currency,
    );
    await refreshActive();
    return null;
  }

  Future<String?> setMemberReceiveCurrency(
    String memberId,
    AppCurrency? currency,
  ) async {
    if (!canEditActive) return 'Faqat masul o\'zgartiradi';
    await _groupService.setMemberReceiveCurrency(
      activeGroup!,
      memberId,
      currency,
    );
    await refreshActive();
    return null;
  }

  Future<String?> setExchangeRates(Map<String, double> rates) async {
    if (!canEditActive) return 'Faqat masul o\'zgartiradi';
    await _groupService.setExchangeRates(activeGroup!, rates);
    await refreshActive();
    return null;
  }
}
