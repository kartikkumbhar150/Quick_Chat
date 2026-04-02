import 'user_model.dart';
import 'message_model.dart';

class ConversationModel {
  final String id;
  final List<UserModel> participants;
  final MessageModel? lastMessage;
  final bool isGroup;
  final DateTime updatedAt;

  ConversationModel({
    required this.id,
    required this.participants,
    this.lastMessage,
    this.isGroup = false,
    required this.updatedAt,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['_id'] ?? '',
      participants: (json['participants'] as List? ?? [])
          .map((p) => UserModel.fromJson(p))
          .toList(),
      lastMessage: json['lastMessage'] != null && json['lastMessage'] is Map
          ? MessageModel.fromJson(json['lastMessage'])
          : null,
      isGroup: json['isGroup'] ?? false,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  /// Returns the other participant (for 1:1 DMs)
  UserModel? otherParticipant(String myId) {
    try {
      return participants.firstWhere((p) => p.id != myId);
    } catch (_) {
      return participants.isNotEmpty ? participants.first : null;
    }
  }
}
