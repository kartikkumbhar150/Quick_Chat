import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/app_theme.dart';
import '../models/message_model.dart';

class ChatBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMine;
  final bool showSenderName;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isMine,
    this.showSenderName = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDeleted = message.isDeleted;
    final content = isDeleted ? '🚫 This message was deleted' : message.content;
    final timeStr = DateFormat('h:mm a').format(message.createdAt.toLocal());

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMine ? AppTheme.sentBubble : AppTheme.receivedBubble,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: isMine ? const Radius.circular(18) : const Radius.circular(4),
            bottomRight: isMine ? const Radius.circular(4) : const Radius.circular(18),
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Sender name (for groups)
            if (showSenderName && !isMine)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  message.sender.username,
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

            // Message content
            Text(
              content,
              style: TextStyle(
                color: isDeleted ? AppTheme.textMuted : AppTheme.textPrimary,
                fontSize: 15,
                fontStyle: isDeleted ? FontStyle.italic : FontStyle.normal,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 4),

            // Time + edited tag
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (message.editedAt != null)
                  const Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: Text('edited', style: TextStyle(color: AppTheme.textMuted, fontSize: 10, fontStyle: FontStyle.italic)),
                  ),
                Text(timeStr, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                if (isMine) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.done_all, size: 14, color: AppTheme.primary),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
