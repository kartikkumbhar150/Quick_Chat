import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../config/api_config.dart';

class SocketService {
  static IO.Socket? _socket;

  static IO.Socket get socket {
    assert(_socket != null, 'SocketService not initialized. Call init() first.');
    return _socket!;
  }

  static bool get isConnected => _socket?.connected ?? false;

  static void init(String token) {
    _socket = IO.io(
      ApiConfig.socketUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({'token': token})
          .setReconnectionAttempts(5)
          .setReconnectionDelay(2000)
          .build(),
    );
    _socket!.connect();

    _socket!.onConnect((_) => print('🟢 Socket connected'));
    _socket!.onDisconnect((_) => print('🔴 Socket disconnected'));
    _socket!.onConnectError((e) => print('⚠️ Socket error: $e'));
  }

  static void joinConversation(String conversationId) {
    _socket?.emit('join_conversation', {'conversationId': conversationId});
  }

  static void joinGroup(String groupId) {
    _socket?.emit('join_group', {'groupId': groupId});
  }

  static void sendMessage({
    required String conversationId,
    required String content,
    String type = 'text',
  }) {
    _socket?.emit('send_message', {
      'conversationId': conversationId,
      'content': content,
      'type': type,
    });
  }

  static void sendGroupMessage({
    required String groupId,
    required String content,
    String type = 'text',
  }) {
    _socket?.emit('send_group_message', {
      'groupId': groupId,
      'content': content,
      'type': type,
    });
  }

  static void typingStart({String? conversationId, String? groupId}) {
    _socket?.emit('typing_start', {
      if (conversationId != null) 'conversationId': conversationId,
      if (groupId != null) 'groupId': groupId,
    });
  }

  static void typingStop({String? conversationId, String? groupId}) {
    _socket?.emit('typing_stop', {
      if (conversationId != null) 'conversationId': conversationId,
      if (groupId != null) 'groupId': groupId,
    });
  }

  static void markRead(String conversationId) {
    _socket?.emit('message_read', {'conversationId': conversationId});
  }

  static void on(String event, Function(dynamic) handler) {
    _socket?.on(event, handler);
  }

  static void off(String event) {
    _socket?.off(event);
  }

  static void dispose() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }
}
