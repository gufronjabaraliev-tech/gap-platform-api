import 'member_role.dart';

class GroupMembership {
  GroupMembership({
    required this.groupId,
    required this.userId,
    required this.role,
    this.joinedAt,
  });

  final String groupId;
  final String userId;
  final MemberRole role;
  final DateTime? joinedAt;

  String get compoundKey => '${groupId}_$userId';

  Map<String, dynamic> toMap() => {
        'groupId': groupId,
        'userId': userId,
        'role': role == MemberRole.responsible ? 'responsible' : 'member',
        'joinedAt': (joinedAt ?? DateTime.now()).toIso8601String(),
      };

  factory GroupMembership.fromMap(Map<dynamic, dynamic> map) =>
      GroupMembership(
        groupId: map['groupId'] as String,
        userId: map['userId'] as String,
        role: MemberRole.fromString(map['role'] as String?),
        joinedAt: map['joinedAt'] != null
            ? DateTime.tryParse(map['joinedAt'] as String)
            : null,
      );
}
