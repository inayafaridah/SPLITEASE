// lib/models/group_member.dart
class GroupMember {
  final int? id;
  final int groupId;
  final int contactId;
  final String joinedAt;

  GroupMember({
    this.id,
    required this.groupId,
    required this.contactId,
    String? joinedAt,
  }) : joinedAt = joinedAt ?? DateTime.now().toIso8601String();

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'group_id': groupId,
        'contact_id': contactId,
        'joined_at': joinedAt,
      };

  factory GroupMember.fromMap(Map<String, dynamic> map) => GroupMember(
        id: map['id'] as int?,
        groupId: map['group_id'] as int,
        contactId: map['contact_id'] as int,
        joinedAt: map['joined_at'] as String,
      );
}