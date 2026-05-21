import 'package:uuid/uuid.dart';

import '../models/group_message.dart';
import '../models/savings_group.dart';
import 'local_db_service.dart';

class GroupChatService {
  GroupChatService(this._db);

  final LocalDbService _db;
  static const _maxLength = 2000;

  Future<List<GroupMessage>> getMessages(String groupId) async {
    return _db.getGroupMessages(groupId);
  }

  Future<String?> sendMessage({
    required SavingsGroup group,
    required String senderMemberId,
    required String senderUserId,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return 'Xabar bo\'sh bo\'lmasligi kerak';
    if (trimmed.length > _maxLength) {
      return 'Xabar $_maxLength belgidan oshmasligi kerak';
    }
    if (!group.members.containsKey(senderMemberId)) {
      return 'Siz bu guruh a\'zosi emassiz';
    }

    final message = GroupMessage(
      id: const Uuid().v4(),
      groupId: group.id,
      senderMemberId: senderMemberId,
      senderUserId: senderUserId,
      text: trimmed,
      createdAt: DateTime.now(),
    );
    await _db.saveGroupMessage(message);
    return null;
  }

  Future<void> deleteMessagesForGroup(String groupId) async {
    await _db.deleteGroupMessages(groupId);
  }
}
