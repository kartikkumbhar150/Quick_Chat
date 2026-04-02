import 'user_model.dart';

class MessageModel {
  final String id;
  final String? conversationId;
  final String? groupId;
  final UserModel sender;
  final String content;
  final String type;
  final String mediaUrl;
  final bool isDeleted;
  final DateTime? editedAt;
  final DateTime createdAt;
  final List<Map<String, dynamic>> readBy;

  MessageModel({
    required this.id,
    this.conversationId,
    this.groupId,
    required this.sender,
    required this.content,
    this.type = 'text',
    this.mediaUrl = '',
    this.isDeleted = false,
    this.editedAt,
    required this.createdAt,
    this.readBy = const [],
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['_id'] ?? '',
      conversationId: json['conversationId'],
      groupId: json['groupId'],
      sender: json['sender'] is Map
          ? UserModel.fromJson(json['sender'])
          : UserModel(id: json['sender'] ?? '', username: '', email: ''),
      content: json['content'] ?? '',
      type: json['type'] ?? 'text',
      mediaUrl: json['mediaUrl'] ?? '',
      isDeleted: json['isDeleted'] ?? false,
      editedAt: json['editedAt'] != null ? DateTime.tryParse(json['editedAt']) : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      readBy: List<Map<String, dynamic>>.from(json['readBy'] ?? []),
    );
  }
}
