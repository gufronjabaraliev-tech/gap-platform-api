import 'package:flutter/foundation.dart';

import '../models/group_message.dart';
import '../models/savings_group.dart';
import '../services/group_chat_service.dart';

class GroupChatProvider extends ChangeNotifier {
  GroupChatProvider(this._chatService);

  final GroupChatService _chatService;

  String? _groupId;
  List<GroupMessage> _messages = [];
  bool _loading = false;

  List<GroupMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _loading;
  String? get openGroupId => _groupId;

  Future<void> load(String groupId) async {
    _groupId = groupId;
    _loading = true;
    notifyListeners();

    _messages = await _chatService.getMessages(groupId);
    _loading = false;
    notifyListeners();
  }

  Future<void> refresh() async {
    final id = _groupId;
    if (id == null) return;
    _messages = await _chatService.getMessages(id);
    notifyListeners();
  }

  Future<String?> send({
    required SavingsGroup group,
    required String senderMemberId,
    required String senderUserId,
    required String text,
  }) async {
    final err = await _chatService.sendMessage(
      group: group,
      senderMemberId: senderMemberId,
      senderUserId: senderUserId,
      text: text,
    );
    if (err != null) return err;
    await refresh();
    return null;
  }

  void clear() {
    _groupId = null;
    _messages = [];
    _loading = false;
    notifyListeners();
  }
}
