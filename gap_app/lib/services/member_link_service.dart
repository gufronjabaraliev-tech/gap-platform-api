import '../models/group_member.dart';
import '../models/group_membership.dart';
import '../models/member_role.dart';
import '../models/payment_entry.dart';
import '../models/savings_group.dart';
import 'local_db_service.dart';

class MemberLinkService {
  MemberLinkService(this._db);

  final LocalDbService _db;

  Future<void> linkPhoneToUser({
    required String phone,
    required String userId,
    required String userName,
  }) async {
    final groups = await _db.getAllGroups();
    for (final group in groups) {
      var changed = false;

      for (final entry in group.members.entries.toList()) {
        final m = entry.value;
        if (m.phone != phone) continue;
        if (m.linkedUserId == userId) continue;

        final oldId = entry.key;
        final newId = userId;

        if (oldId != newId) {
          group.members.remove(oldId);
          group.members[newId] = GroupMember(
            id: newId,
            displayName: userName,
            phone: phone,
            linkedUserId: userId,
          );
          _replaceIdInGroup(group, oldId, newId);
        } else {
          m.linkedUserId = userId;
          m.displayName = userName;
        }
        changed = true;

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

      if (changed) await _db.saveGroup(group);
    }
  }

  void _replaceIdInGroup(SavingsGroup group, String oldId, String newId) {
    if (group.responsibleUserId == oldId) {
      group.responsibleUserId = newId;
    }
    if (group.activeReceiverId == oldId) {
      group.activeReceiverId = newId;
    }
    group.completedReceiverIds = group.completedReceiverIds
        .map((id) => id == oldId ? newId : id)
        .toList();
    group.schedule = group.schedule.map((id) => id == oldId ? newId : id).toList();
    final newPayments = <String, Map<String, PaymentEntry>>{};
    group.payments.forEach((period, payers) {
      newPayments[period] = {};
      payers.forEach((id, entry) {
        newPayments[period]![id == oldId ? newId : id] = entry;
      });
    });
    group.payments = newPayments;
  }

  Future<void> syncDisplayNameFromProfile(String userId, String newName) async {
    final groups = await _db.getAllGroups();
    for (final group in groups) {
      var changed = false;
      for (final m in group.members.values) {
        if (m.linkedUserId == userId || m.id == userId) {
          m.displayName = newName;
          changed = true;
        }
      }
      if (changed) await _db.saveGroup(group);
    }
  }
}
