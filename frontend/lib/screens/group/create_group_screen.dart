import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../models/user_model.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';
import '../../widgets/user_avatar.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  List<UserModel> _searchResults = [];
  final List<UserModel> _selected = [];
  bool _loading = false;
  bool _searching = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _search(String q) async {
    if (q.trim().isEmpty) { setState(() => _searchResults = []); return; }
    setState(() => _searching = true);
    final res = await ApiService.get(ApiConfig.searchUsers, query: {'q': q.trim()});
    if (res['success'] == true && mounted) {
      setState(() => _searchResults = (res['users'] as List).map((u) => UserModel.fromJson(u)).toList());
    }
    if (mounted) setState(() => _searching = false);
  }

  Future<void> _createGroup() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Group name is required'), backgroundColor: AppTheme.error),
      );
      return;
    }
    setState(() => _loading = true);
    final res = await ApiService.post(ApiConfig.groups, {
      'name': _nameCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'memberIds': _selected.map((u) => u.id).toList(),
    }, auth: true);
    if (!mounted) return;
    setState(() => _loading = false);

    if (res['success'] == true) {
      await context.read<ChatProvider>().fetchGroups();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Group created! 🎉'), backgroundColor: AppTheme.secondary),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'Failed'), backgroundColor: AppTheme.error),
      );
    }
  }

  void _toggle(UserModel user) {
    setState(() {
      if (_selected.any((u) => u.id == user.id)) {
        _selected.removeWhere((u) => u.id == user.id);
      } else {
        _selected.add(user);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Group'),
        actions: [
          _loading
              ? const Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2))
              : TextButton(onPressed: _createGroup, child: const Text('Create', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold))),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Group Name', prefixIcon: Icon(Icons.group, color: AppTheme.textMuted)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _descCtrl,
                  decoration: const InputDecoration(labelText: 'Description (optional)', prefixIcon: Icon(Icons.info_outline, color: AppTheme.textMuted)),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search & add members...',
                    prefixIcon: const Icon(Icons.search, color: AppTheme.textMuted),
                    suffixIcon: _searching ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : null,
                  ),
                  onChanged: _search,
                ),
              ],
            ),
          ),
          // Selected members chips
          if (_selected.isNotEmpty)
            Container(
              height: 80,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _selected.length,
                itemBuilder: (_, i) {
                  final u = _selected[i];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            UserAvatar(imageUrl: u.profileImage, radius: 24),
                            Positioned(
                              top: 0, right: 0,
                              child: GestureDetector(
                                onTap: () => _toggle(u),
                                child: Container(
                                  width: 18, height: 18,
                                  decoration: const BoxDecoration(color: AppTheme.error, shape: BoxShape.circle),
                                  child: const Icon(Icons.close, size: 12, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(u.username, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                      ],
                    ),
                  );
                },
              ),
            ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: _searchResults.length,
              itemBuilder: (_, i) {
                final u = _searchResults[i];
                final isSelected = _selected.any((s) => s.id == u.id);
                return ListTile(
                  leading: UserAvatar(imageUrl: u.profileImage, radius: 22, isOnline: u.isOnline),
                  title: Text(u.username),
                  subtitle: Text(u.bio.isNotEmpty ? u.bio : u.status, style: const TextStyle(color: AppTheme.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: AppTheme.primary)
                      : const Icon(Icons.radio_button_unchecked, color: AppTheme.textMuted),
                  onTap: () => _toggle(u),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
