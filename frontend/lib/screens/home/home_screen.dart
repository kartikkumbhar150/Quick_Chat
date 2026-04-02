import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../models/conversation_model.dart';
import '../../models/group_model.dart';
import '../../models/user_model.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';
import '../chat/chat_screen.dart';
import '../chat/group_chat_screen.dart';
import '../../widgets/user_avatar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _searchCtrl = TextEditingController();
  List<UserModel> _searchResults = [];
  bool _searching = false;
  bool _searchLoading = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final chat = context.read<ChatProvider>();
    final auth = context.read<AuthProvider>();
    await Future.wait([chat.fetchConversations(), chat.fetchGroups()]);
    chat.initSocketListeners(auth.user?.id ?? '');
  }

  Future<void> _search(String q) async {
    if (q.trim().isEmpty) {
      setState(() { _searchResults = []; _searching = false; });
      return;
    }
    setState(() { _searching = true; _searchLoading = true; });
    try {
      final res = await ApiService.get(ApiConfig.searchUsers, query: {'q': q.trim()});
      if (res['success'] == true && mounted) {
        setState(() {
          _searchResults = (res['users'] as List).map((u) => UserModel.fromJson(u)).toList();
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _searchLoading = false);
  }

  Future<void> _startDM(UserModel user) async {
    setState(() => _searching = false);
    _searchCtrl.clear();
    _searchResults = [];
    final chat = context.read<ChatProvider>();
    final conv = await chat.createOrGetConversation(user.id);
    if (conv != null && mounted) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(conversation: conv)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final chat = context.watch<ChatProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: _searching
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Search username...',
                  border: InputBorder.none,
                  fillColor: Colors.transparent,
                ),
                onChanged: _search,
              )
            : Row(
                children: [
                  UserAvatar(imageUrl: auth.user?.profileImage ?? '', radius: 18),
                  const SizedBox(width: 10),
                  const Text('Quick Chat', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                ],
              ),
        actions: [
          if (!_searching)
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => setState(() => _searching = true),
            ),
          if (_searching)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() { _searching = false; _searchResults = []; });
                _searchCtrl.clear();
              },
            ),
          if (!_searching)
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () => _showMenu(context, auth),
            ),
        ],
        bottom: _searching
            ? null
            : TabBar(
                controller: _tabCtrl,
                indicatorColor: AppTheme.primary,
                labelColor: AppTheme.primary,
                unselectedLabelColor: AppTheme.textSecondary,
                tabs: const [
                  Tab(text: 'Chats'),
                  Tab(text: 'Groups'),
                ],
              ),
      ),
      body: _searching ? _buildSearchResults() : TabBarView(
        controller: _tabCtrl,
        children: [
          _buildConversationList(chat),
          _buildGroupList(chat),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primary,
        onPressed: _tabCtrl.index == 0
            ? () => setState(() => _searching = true)
            : () => Navigator.pushNamed(context, '/create-group').then((_) => chat.fetchGroups()),
        child: Icon(_tabCtrl.index == 0 ? Icons.chat_rounded : Icons.group_add_rounded),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchLoading) return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    if (_searchResults.isEmpty && _searchCtrl.text.isNotEmpty) {
      return const Center(child: Text('No users found', style: TextStyle(color: AppTheme.textSecondary)));
    }
    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (_, i) {
        final user = _searchResults[i];
        return ListTile(
          leading: UserAvatar(imageUrl: user.profileImage, radius: 24, isOnline: user.isOnline),
          title: Text(user.username, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(user.bio.isNotEmpty ? user.bio : user.status, style: const TextStyle(color: AppTheme.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
          onTap: () => _startDM(user),
        );
      },
    );
  }

  Widget _buildConversationList(ChatProvider chat) {
    if (chat.loadingConversations) return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    if (chat.conversations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.chat_bubble_outline, size: 64, color: AppTheme.textMuted),
            const SizedBox(height: 16),
            const Text('No conversations yet', style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
            const SizedBox(height: 8),
            const Text('Tap 🔍 to find someone to chat with', style: TextStyle(color: AppTheme.textMuted)),
          ],
        ),
      );
    }
    final myId = context.read<AuthProvider>().user?.id ?? '';
    return RefreshIndicator(
      color: AppTheme.primary,
      onRefresh: chat.fetchConversations,
      child: ListView.separated(
        itemCount: chat.conversations.length,
        separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
        itemBuilder: (_, i) {
          final conv = chat.conversations[i];
          final other = conv.otherParticipant(myId);
          if (other == null) return const SizedBox();
          return _ConvTile(conv: conv, other: other, onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(conversation: conv)));
          });
        },
      ),
    );
  }

  Widget _buildGroupList(ChatProvider chat) {
    if (chat.groups.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.group_outlined, size: 64, color: AppTheme.textMuted),
            const SizedBox(height: 16),
            const Text('No groups yet', style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
            const SizedBox(height: 8),
            const Text('Tap + to create a group', style: TextStyle(color: AppTheme.textMuted)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      color: AppTheme.primary,
      onRefresh: chat.fetchGroups,
      child: ListView.separated(
        itemCount: chat.groups.length,
        separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
        itemBuilder: (_, i) {
          final g = chat.groups[i];
          return ListTile(
            leading: UserAvatar(imageUrl: g.groupImage, radius: 24, isGroup: true),
            title: Text(g.name, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(
              g.lastMessage?.content.isNotEmpty == true ? g.lastMessage!.content : '${g.members.length} members',
              style: const TextStyle(color: AppTheme.textSecondary),
              overflow: TextOverflow.ellipsis,
            ),
            trailing: g.updatedAt != null
                ? Text(timeago.format(g.updatedAt, allowFromNow: true), style: const TextStyle(color: AppTheme.textMuted, fontSize: 12))
                : null,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GroupChatScreen(group: g))),
          );
        },
      ),
    );
  }

  void _showMenu(BuildContext context, AuthProvider auth) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceLight,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.person_outline, color: AppTheme.primary),
            title: const Text('Profile'),
            onTap: () { Navigator.pop(context); Navigator.pushNamed(context, '/profile').then((_) => auth.refreshUser()); },
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: AppTheme.error),
            title: const Text('Logout', style: TextStyle(color: AppTheme.error)),
            onTap: () { Navigator.pop(context); auth.logout(); },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _ConvTile extends StatelessWidget {
  final ConversationModel conv;
  final UserModel other;
  final VoidCallback onTap;

  const _ConvTile({required this.conv, required this.other, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final lastMsg = conv.lastMessage;
    return ListTile(
      leading: UserAvatar(imageUrl: other.profileImage, radius: 24, isOnline: other.isOnline),
      title: Text(other.username, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        lastMsg?.isDeleted == true ? '🚫 This message was deleted' : (lastMsg?.content ?? 'Start chatting...'),
        style: const TextStyle(color: AppTheme.textSecondary),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            timeago.format(conv.updatedAt, allowFromNow: true),
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
          ),
        ],
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}
