import 'package:hive_flutter/hive_flutter.dart';

import '../models/app_user.dart';
import '../models/group_membership.dart';
import '../models/member_role.dart';
import '../models/group_message.dart';
import '../models/savings_group.dart';
import '../utils/pin_util.dart';

class LocalDbService {
  static const _usersBox = 'users';
  static const _groupsBox = 'groups';
  static const _membershipsBox = 'memberships';
  static const _groupMessagesBox = 'group_messages';
  static const _sessionKey = 'current_user_id';

  Box<Map>? _users;
  Box<Map>? _groups;
  Box<Map>? _memberships;
  Box<Map>? _groupMessages;
  Box? _session;

  Future<void> init() async {
    await Hive.initFlutter();
    _users = await Hive.openBox<Map>(_usersBox);
    _groups = await Hive.openBox<Map>(_groupsBox);
    _memberships = await Hive.openBox<Map>(_membershipsBox);
    _groupMessages = await Hive.openBox<Map>(_groupMessagesBox);
    _session = await Hive.openBox('session');
  }

  String? get currentUserId => _session?.get(_sessionKey) as String?;

  Future<void> setCurrentUserId(String? userId) async {
    if (userId == null) {
      await _session?.delete(_sessionKey);
    } else {
      await _session?.put(_sessionKey, userId);
    }
  }

  dynamic sessionGet(String key) => _session?.get(key);

  Future<void> sessionPut(String key, dynamic value) async {
    await _session?.put(key, value);
  }

  Future<void> sessionDelete(String key) async {
    await _session?.delete(key);
  }

  Future<AppUser?> getUserByPhone(String phone) async {
    for (final raw in _users!.values) {
      final user = AppUser.fromMap(raw);
      if (user.phone == phone) return user;
    }
    return null;
  }

  Future<AppUser?> findUserByAnyPhone(String phone) async {
    final normalized = normalizePhone(phone);
    for (final raw in _users!.values) {
      final user = AppUser.fromMap(raw);
      if (user.allPhones.any((p) => normalizePhone(p) == normalized)) {
        return user;
      }
    }
    return null;
  }

  Future<AppUser?> getUserById(String id) async {
    final raw = _users?.get(id);
    if (raw == null) return null;
    return AppUser.fromMap(raw);
  }

  /// Ro'yxatdan o'tgan barcha foydalanuvchilar (kirish dropdown uchun).
  Future<List<AppUser>> getAllUsers() async {
    final list = <AppUser>[];
    for (final raw in _users!.values) {
      list.add(AppUser.fromMap(raw));
    }
    list.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return list;
  }

  Future<void> saveUser(AppUser user) async {
    await _users?.put(user.id, user.toMap());
  }

  Future<SavingsGroup?> getGroup(String id) async {
    final raw = _groups?.get(id);
    if (raw == null) return null;
    return SavingsGroup.fromMap(raw);
  }

  Future<void> saveGroup(SavingsGroup group) async {
    await _groups?.put(group.id, group.toMap());
  }

  Future<void> deleteGroup(String id) async {
    await _groups?.delete(id);
    await deleteGroupMessages(id);
    final toRemove = <String>[];
    for (final key in _memberships!.keys) {
      final raw = _memberships!.get(key);
      if (raw == null) continue;
      final m = GroupMembership.fromMap(raw);
      if (m.groupId == id) toRemove.add(key as String);
    }
    for (final key in toRemove) {
      await _memberships?.delete(key);
    }
  }

  Future<GroupMembership?> getMembership(String groupId, String userId) async {
    final raw = _memberships?.get('${groupId}_$userId');
    if (raw == null) return null;
    return GroupMembership.fromMap(raw);
  }

  Future<void> saveMembership(GroupMembership m) async {
    await _memberships?.put(m.compoundKey, m.toMap());
  }

  Future<void> deleteMembership(String groupId, String userId) async {
    await _memberships?.delete('${groupId}_$userId');
  }

  Future<List<GroupMembership>> membershipsForUser(String userId) async {
    final list = <GroupMembership>[];
    for (final raw in _memberships!.values) {
      final m = GroupMembership.fromMap(raw);
      if (m.userId == userId) list.add(m);
    }
    list.sort((a, b) =>
        (b.joinedAt ?? DateTime(0)).compareTo(a.joinedAt ?? DateTime(0)));
    return list;
  }

  Future<bool> hasResponsibleMembership(String userId) async {
    final memberships = await membershipsForUser(userId);
    for (final m in memberships) {
      if (m.role == MemberRole.responsible) return true;
    }
    return false;
  }

  Future<SavingsGroup?> findGroupByInviteCode(String code) async {
    final upper = code.trim().toUpperCase();
    for (final raw in _groups!.values) {
      final g = SavingsGroup.fromMap(raw);
      if (g.inviteCode == upper) return g;
    }
    return null;
  }

  Future<List<String>> memberUserIds(String groupId) async {
    final ids = <String>[];
    for (final raw in _memberships!.values) {
      final m = GroupMembership.fromMap(raw);
      if (m.groupId == groupId) ids.add(m.userId);
    }
    return ids;
  }

  Future<List<SavingsGroup>> getAllGroups() async {
    return _groups!.values
        .map((raw) => SavingsGroup.fromMap(raw))
        .toList();
  }

  Future<List<SavingsGroup>> findGroupsByPhone(String phone) async {
    final result = <SavingsGroup>[];
    for (final raw in _groups!.values) {
      final g = SavingsGroup.fromMap(raw);
      if (g.memberByPhone(phone) != null) result.add(g);
    }
    return result;
  }

  String _messageKey(String groupId, String messageId) =>
      '${groupId}_$messageId';

  Future<void> saveGroupMessage(GroupMessage message) async {
    await _groupMessages?.put(
      _messageKey(message.groupId, message.id),
      message.toMap(),
    );
  }

  Future<List<GroupMessage>> getGroupMessages(String groupId) async {
    final list = <GroupMessage>[];
    for (final raw in _groupMessages!.values) {
      final m = GroupMessage.fromMap(raw);
      if (m.groupId == groupId) list.add(m);
    }
    list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return list;
  }

  Future<void> deleteGroupMessages(String groupId) async {
    final toRemove = <String>[];
    for (final key in _groupMessages!.keys) {
      final raw = _groupMessages!.get(key);
      if (raw == null) continue;
      final m = GroupMessage.fromMap(raw);
      if (m.groupId == groupId) toRemove.add(key as String);
    }
    for (final key in toRemove) {
      await _groupMessages?.delete(key);
    }
  }
}
