import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../models/conversation_model.dart';
import '../../models/message_model.dart';
import '../../services/socket_service.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/chat_bubble.dart';

class ChatScreen extends StatefulWidget {
  final ConversationModel conversation;

  const ChatScreen({super.key, required this.conversation});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _sending = false;

  String get _convId => widget.conversation.id;

  @override
  void initState() {
    super.initState();
    SocketService.joinConversation(_convId);
    SocketService.markRead(_convId);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<ChatProvider>().fetchMessages(_convId);
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom({bool animate = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        if (animate) {
          _scrollCtrl.animateTo(
            _scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        } else {
          _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
        }
      }
    });
  }

  void _sendMessage() {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _sending) return;
    _msgCtrl.clear();
    SocketService.sendMessage(conversationId: _convId, content: text);
    _scrollToBottom(animate: true);
  }

  void _onTypingChanged(String val) {
    if (val.isNotEmpty) {
      SocketService.typingStart(conversationId: _convId);
    } else {
      SocketService.typingStop(conversationId: _convId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final chat = context.watch<ChatProvider>();
    final myId = auth.user?.id ?? '';
    final other = widget.conversation.otherParticipant(myId);
    final messages = chat.getMessages(_convId);
    final isTyping = chat.isTyping(_convId);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            UserAvatar(imageUrl: other?.profileImage ?? '', radius: 18, isOnline: other?.isOnline ?? false),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(other?.username ?? 'Chat', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                Text(
                  isTyping ? 'typing...' : (other?.isOnline == true ? 'online' : 'offline'),
                  style: TextStyle(
                    fontSize: 12,
                    color: isTyping || other?.isOnline == true ? AppTheme.secondary : AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
        titleSpacing: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? const Center(
                    child: Text('Say hello! 👋', style: TextStyle(color: AppTheme.textMuted, fontSize: 16)),
                  )
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemCount: messages.length,
                    itemBuilder: (_, i) {
                      final msg = messages[i];
                      final isMine = msg.sender.id == myId;
                      final showDate = i == 0 ||
                          !_isSameDay(messages[i - 1].createdAt, msg.createdAt);
                      return Column(
                        children: [
                          if (showDate) _DateDivider(date: msg.createdAt),
                          ChatBubble(message: msg, isMine: isMine),
                        ],
                      );
                    },
                  ),
          ),
          if (isTyping)
            const Padding(
              padding: EdgeInsets.only(left: 16, bottom: 4),
              child: Row(
                children: [
                  Text('typing...', style: TextStyle(color: AppTheme.textMuted, fontSize: 12, fontStyle: FontStyle.italic)),
                ],
              ),
            ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.divider)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _msgCtrl,
              maxLines: 4,
              minLines: 1,
              onChanged: _onTypingChanged,
              decoration: InputDecoration(
                hintText: 'Message...',
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                fillColor: AppTheme.surfaceLight,
                filled: true,
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _DateDivider extends StatelessWidget {
  final DateTime date;
  const _DateDivider({required this.date});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    String label;
    if (_isSameDay(date, now)) {
      label = 'Today';
    } else if (_isSameDay(date, now.subtract(const Duration(days: 1)))) {
      label = 'Yesterday';
    } else {
      label = DateFormat('MMM d, yyyy').format(date);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const Expanded(child: Divider(color: AppTheme.divider)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
          ),
          const Expanded(child: Divider(color: AppTheme.divider)),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
