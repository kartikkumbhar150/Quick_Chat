import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/conversation_model.dart';
import '../models/user_model.dart';
import 'user_avatar.dart';
import 'package:timeago/timeago.dart' as timeago;

class ConversationTile extends StatelessWidget {
  final ConversationModel conversation;
  final String myId;
  final VoidCallback onTap;

  const ConversationTile({
    super.key,
    required this.conversation,
    required this.myId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final other = conversation.otherParticipant(myId);
    if (other == null) return const SizedBox();

    final lastMsg = conversation.lastMessage;
    final isDeleted = lastMsg?.isDeleted ?? false;
    final preview = isDeleted
        ? '🚫 This message was deleted'
        : (lastMsg?.content.isNotEmpty == true ? lastMsg!.content : 'Start chatting...');

    return ListTile(
      leading: UserAvatar(imageUrl: other.profileImage, radius: 26, isOnline: other.isOnline),
      title: Text(other.username, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      subtitle: Text(
        preview,
        style: TextStyle(
          color: isDeleted ? AppTheme.textMuted : AppTheme.textSecondary,
          fontStyle: isDeleted ? FontStyle.italic : FontStyle.normal,
          fontSize: 13,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
      trailing: Text(
        timeago.format(conversation.updatedAt, allowFromNow: true),
        style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onTap: onTap,
    );
  }
}
