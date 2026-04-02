import 'user_model.dart';
import 'message_model.dart';

class GroupMember {
  final UserModel user;
  final String role;
  final DateTime joinedAt;

  GroupMember({required this.user, required this.role, required this.joinedAt});

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    return GroupMember(
      user: UserModel.fromJson(json['user'] ?? {}),
      role: json['role'] ?? 'member',
      joinedAt: json['joinedAt'] != null
          ? DateTime.parse(json['joinedAt'])
          : DateTime.now(),
    );
  }
}

class GroupModel {
  final String id;
  final String name;
  final String description;
  final String groupImage;
  final UserModel admin;
  final List<GroupMember> members;
  final MessageModel? lastMessage;
  final DateTime updatedAt;

  GroupModel({
    required this.id,
    required this.name,
    this.description = '',
    this.groupImage = '',
    required this.admin,
    required this.members,
    this.lastMessage,
    required this.updatedAt,
  });

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    return GroupModel(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      groupImage: json['groupImage'] ?? '',
      admin: json['admin'] is Map
          ? UserModel.fromJson(json['admin'])
          : UserModel(id: json['admin'] ?? '', username: '', email: ''),
      members: (json['members'] as List? ?? [])
          .map((m) => GroupMember.fromJson(m))
          .toList(),
      lastMessage: json['lastMessage'] != null && json['lastMessage'] is Map
          ? MessageModel.fromJson(json['lastMessage'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }
}
