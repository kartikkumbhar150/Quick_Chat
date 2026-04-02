import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../models/group_model.dart';
import '../../services/socket_service.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/chat_bubble.dart';

class GroupChatScreen extends StatefulWidget {
  final GroupModel group;
  const GroupChatScreen({super.key, required this.group});

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  String get _groupId => widget.group.id;

  @override
  void initState() {
    super.initState();
    SocketService.joinGroup(_groupId);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<ChatProvider>().fetchMessages(_groupId, isGroup: true);
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
          _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
              duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
        } else {
          _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
        }
      }
    });
  }

  void _sendMessage() {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    _msgCtrl.clear();
    SocketService.sendGroupMessage(groupId: _groupId, content: text);
    _scrollToBottom(animate: true);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final chat = context.watch<ChatProvider>();
    final myId = auth.user?.id ?? '';
    final messages = chat.getMessages(_groupId);
    final isTyping = chat.isTyping(_groupId);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            UserAvatar(imageUrl: widget.group.groupImage, radius: 18, isGroup: true),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.group.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                Text(
                  isTyping ? 'someone is typing...' : '${widget.group.members.length} members',
                  style: TextStyle(
                    fontSize: 12,
                    color: isTyping ? AppTheme.secondary : AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
        titleSpacing: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showGroupInfo(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? const Center(child: Text('Be the first to say hi! 👋', style: TextStyle(color: AppTheme.textMuted)))
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
                          if (showDate) _dateDivider(msg.createdAt),
                          ChatBubble(message: msg, isMine: isMine, showSenderName: !isMine),
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
              onChanged: (v) {
                if (v.isNotEmpty) SocketService.typingStart(groupId: _groupId);
                else SocketService.typingStop(groupId: _groupId);
              },
              decoration: InputDecoration(
                hintText: 'Message...',
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                fillColor: AppTheme.surfaceLight,
                filled: true,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 46, height: 46,
              decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateDivider(DateTime date) {
    final now = DateTime.now();
    String label;
    if (_isSameDay(date, now)) label = 'Today';
    else if (_isSameDay(date, now.subtract(const Duration(days: 1)))) label = 'Yesterday';
    else label = DateFormat('MMM d, yyyy').format(date);
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

  void _showGroupInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceLight,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        expand: false,
        builder: (_, ctrl) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: UserAvatar(imageUrl: widget.group.groupImage, radius: 36, isGroup: true),
              ),
            ),
            Center(child: Text(widget.group.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
            if (widget.group.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Center(child: Text(widget.group.description, style: const TextStyle(color: AppTheme.textSecondary))),
            ],
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('${widget.group.members.length} Members', style: const TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
            ),
            Expanded(
              child: ListView.builder(
                controller: ctrl,
                itemCount: widget.group.members.length,
                itemBuilder: (_, i) {
                  final m = widget.group.members[i];
                  return ListTile(
                    leading: UserAvatar(imageUrl: m.user.profileImage, radius: 20),
                    title: Text(m.user.username),
                    trailing: m.role == 'admin' ? const Chip(label: Text('Admin', style: TextStyle(fontSize: 11)), backgroundColor: AppTheme.primary) : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
