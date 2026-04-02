import 'package:flutter/material.dart';
import '../models/conversation_model.dart';
import '../models/group_model.dart';
import '../models/message_model.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../config/api_config.dart';

class ChatProvider extends ChangeNotifier {
  List<ConversationModel> _conversations = [];
  List<GroupModel> _groups = [];
  final Map<String, List<MessageModel>> _messages = {};
  final Map<String, bool> _typingStatus = {};
  bool _loadingConversations = false;

  List<ConversationModel> get conversations => _conversations;
  List<GroupModel> get groups => _groups;
  bool get loadingConversations => _loadingConversations;

  List<MessageModel> getMessages(String roomId) => _messages[roomId] ?? [];
  bool isTyping(String roomId) => _typingStatus[roomId] ?? false;

  // ── Conversations ──────────────────────────────────────────────────────────

  Future<void> fetchConversations() async {
    _loadingConversations = true;
    notifyListeners();
    try {
      final res = await ApiService.get(ApiConfig.conversations);
      if (res['success'] == true) {
        _conversations = (res['conversations'] as List)
            .map((c) => ConversationModel.fromJson(c))
            .toList();
      }
    } catch (_) {}
    _loadingConversations = false;
    notifyListeners();
  }

  Future<ConversationModel?> createOrGetConversation(String participantId) async {
    try {
      final res = await ApiService.post(ApiConfig.conversations, {'participantId': participantId}, auth: true);
      if (res['success'] == true) {
        final conv = ConversationModel.fromJson(res['conversation']);
        // Add to list if not already present
        if (!_conversations.any((c) => c.id == conv.id)) {
          _conversations.insert(0, conv);
          notifyListeners();
        }
        return conv;
      }
    } catch (_) {}
    return null;
  }

  // ── Groups ─────────────────────────────────────────────────────────────────

  Future<void> fetchGroups() async {
    try {
      final res = await ApiService.get(ApiConfig.groups);
      if (res['success'] == true) {
        _groups = (res['groups'] as List)
            .map((g) => GroupModel.fromJson(g))
            .toList();
        notifyListeners();
      }
    } catch (_) {}
  }

  // ── Messages ───────────────────────────────────────────────────────────────

  Future<void> fetchMessages(String conversationId, {bool isGroup = false}) async {
    try {
      final path = isGroup
          ? '${ApiConfig.messages}/group/$conversationId'
          : '${ApiConfig.messages}/conversation/$conversationId';
      final res = await ApiService.get(path);
      if (res['success'] == true) {
        _messages[conversationId] = (res['messages'] as List)
            .map((m) => MessageModel.fromJson(m))
            .toList();
        notifyListeners();
      }
    } catch (_) {}
  }

  void addMessage(String roomId, MessageModel message) {
    _messages[roomId] = [...(_messages[roomId] ?? []), message];
    // Update last message in conversation
    final idx = _conversations.indexWhere((c) => c.id == roomId);
    if (idx != -1) {
      _conversations[idx] = ConversationModel(
        id: _conversations[idx].id,
        participants: _conversations[idx].participants,
        lastMessage: message,
        isGroup: _conversations[idx].isGroup,
        updatedAt: DateTime.now(),
      );
      // Move to top
      final updated = _conversations.removeAt(idx);
      _conversations.insert(0, updated);
    }
    notifyListeners();
  }

  void setTyping(String roomId, bool typing) {
    _typingStatus[roomId] = typing;
    notifyListeners();
  }

  void initSocketListeners(String myId) {
    SocketService.on('new_message', (data) {
      final msg = MessageModel.fromJson(data['message']);
      final roomId = data['conversationId'] as String;
      addMessage(roomId, msg);
    });

    SocketService.on('new_group_message', (data) {
      final msg = MessageModel.fromJson(data['message']);
      final roomId = data['groupId'] as String;
      addMessage(roomId, msg);
    });

    SocketService.on('typing_start', (data) {
      final roomId = data['conversationId'] ?? data['groupId'];
      if (roomId != null) setTyping(roomId.toString(), true);
    });

    SocketService.on('typing_stop', (data) {
      final roomId = data['conversationId'] ?? data['groupId'];
      if (roomId != null) setTyping(roomId.toString(), false);
    });
  }

  void disposeSocketListeners() {
    SocketService.off('new_message');
    SocketService.off('new_group_message');
    SocketService.off('typing_start');
    SocketService.off('typing_stop');
  }
}
