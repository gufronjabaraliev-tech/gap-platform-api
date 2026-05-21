class GroupMessage {
  GroupMessage({
    required this.id,
    required this.groupId,
    required this.senderMemberId,
    this.senderUserId,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final String groupId;
  final String senderMemberId;
  final String? senderUserId;
  final String text;
  final DateTime createdAt;

  Map<String, dynamic> toMap() => {
        'id': id,
        'groupId': groupId,
        'senderMemberId': senderMemberId,
        'senderUserId': senderUserId,
        'text': text,
        'createdAt': createdAt.toIso8601String(),
      };

  factory GroupMessage.fromMap(Map<dynamic, dynamic> map) {
    return GroupMessage(
      id: map['id'] as String,
      groupId: map['groupId'] as String,
      senderMemberId: map['senderMemberId'] as String,
      senderUserId: map['senderUserId'] as String?,
      text: map['text'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}
