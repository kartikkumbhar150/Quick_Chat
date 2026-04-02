import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';
import '../../widgets/user_avatar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _bioCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  bool _editing = false;
  bool _saving = false;
  bool _uploadingImage = false;

  final List<String> _statusOptions = [
    'Hey there! I am using Quick Chat',
    'Available',
    'Busy',
    'At school',
    'At work',
    'Battery about to die',
    'Sleeping',
    'Do not disturb',
  ];

  String _selectedStatus = 'Hey there! I am using Quick Chat';

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      _bioCtrl.text = user.bio;
      _usernameCtrl.text = user.username;
      _selectedStatus = user.status;
    }
  }

  @override
  void dispose() {
    _bioCtrl.dispose();
    _usernameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;

    setState(() => _uploadingImage = true);
    final res = await ApiService.uploadFile(ApiConfig.meAvatar, 'avatar', picked.path);
    if (!mounted) return;
    setState(() => _uploadingImage = false);

    if (res['success'] == true) {
      await context.read<AuthProvider>().refreshUser();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile photo updated ✅'), backgroundColor: AppTheme.secondary),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'Upload failed'), backgroundColor: AppTheme.error),
      );
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _saving = true);
    final res = await ApiService.put(ApiConfig.me, {
      'username': _usernameCtrl.text.trim(),
      'bio': _bioCtrl.text.trim(),
      'status': _selectedStatus,
    });
    if (!mounted) return;
    setState(() { _saving = false; _editing = false; });

    if (res['success'] == true) {
      await context.read<AuthProvider>().refreshUser();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated ✅'), backgroundColor: AppTheme.secondary),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'Update failed'), backgroundColor: AppTheme.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (!_editing)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => setState(() => _editing = true),
            )
          else
            _saving
                ? const Padding(padding: EdgeInsets.all(14), child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary))
                : TextButton(
                    onPressed: _saveProfile,
                    child: const Text('Save', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            const SizedBox(height: 16),

            // ── Avatar ──────────────────────────────────────────────────────
            Center(
              child: Stack(
                children: [
                  _uploadingImage
                      ? Container(
                          width: 100, height: 100,
                          decoration: BoxDecoration(color: AppTheme.surfaceLight, shape: BoxShape.circle),
                          child: const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
                        )
                      : UserAvatar(imageUrl: user.profileImage, radius: 50, isOnline: user.isOnline),
                  if (!_uploadingImage)
                    Positioned(
                      bottom: 4, right: 4,
                      child: GestureDetector(
                        onTap: _pickAndUploadImage,
                        child: Container(
                          width: 34, height: 34,
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppTheme.background, width: 2),
                          ),
                          child: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // ── Online badge ───────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 8, height: 8,
                  decoration: const BoxDecoration(color: AppTheme.online, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                const Text('Online', style: TextStyle(color: AppTheme.online, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 32),

            // ── Fields ────────────────────────────────────────────────────
            _buildSection('Account', [
              _buildField(
                label: 'Username',
                icon: Icons.alternate_email,
                child: _editing
                    ? TextField(
                        controller: _usernameCtrl,
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      )
                    : _fieldText('@${user.username}'),
              ),
              _buildField(
                label: 'Email',
                icon: Icons.email_outlined,
                child: _fieldText(user.email),
              ),
            ]),

            const SizedBox(height: 16),

            _buildSection('About', [
              _buildField(
                label: 'Bio',
                icon: Icons.info_outline,
                child: _editing
                    ? TextField(
                        controller: _bioCtrl,
                        maxLines: 3,
                        maxLength: 150,
                        decoration: const InputDecoration(
                          hintText: 'Tell people about yourself...',
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      )
                    : _fieldText(user.bio.isNotEmpty ? user.bio : 'No bio yet', muted: user.bio.isEmpty),
              ),
              _buildField(
                label: 'Status',
                icon: Icons.circle_outlined,
                child: _editing
                    ? DropdownButtonFormField<String>(
                        value: _selectedStatus,
                        dropdownColor: AppTheme.cardColor,
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        items: _statusOptions
                            .map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 14))))
                            .toList(),
                        onChanged: (v) => setState(() => _selectedStatus = v ?? _selectedStatus),
                      )
                    : _fieldText(user.status),
              ),
            ]),

            const SizedBox(height: 32),

            // ── Danger zone ───────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.error.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.error.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Danger Zone', style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.logout, color: AppTheme.error, size: 18),
                    label: const Text('Log Out', style: TextStyle(color: AppTheme.error)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.error),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      minimumSize: const Size(double.infinity, 44),
                    ),
                    onPressed: () {
                      auth.logout();
                      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(color: AppTheme.cardColor, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Text(title, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1)),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildField({required String label, required IconData icon, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppTheme.textMuted),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 6),
          child,
          const Divider(height: 1),
        ],
      ),
    );
  }

  Widget _fieldText(String text, {bool muted = false}) {
    return Text(
      text,
      style: TextStyle(color: muted ? AppTheme.textMuted : AppTheme.textPrimary, fontSize: 15),
    );
  }
}
