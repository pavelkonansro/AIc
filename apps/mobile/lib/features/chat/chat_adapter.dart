import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:socket_io_client/socket_io_client.dart' as socket_io;

class GrokChatAdapter {
  socket_io.Socket? _socket;
  String? _sessionId;
  Function(types.Message)? _onMessageReceived;
  Function(String)? _onError;

  void initialize({
    required String sessionId,
    required Function(types.Message) onMessageReceived,
    required Function(String) onError,
  }) {
    _sessionId = sessionId;
    _onMessageReceived = onMessageReceived;
    _onError = onError;
    _connectSocket();
  }

  void _connectSocket() {
    _socket = socket_io.io(
      'http://192.168.68.65:3000/chat',
      socket_io.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .build(),
    );

    _socket!.onConnect((_) {
      _socket!.emit('join_session', {'sessionId': _sessionId!});
    });

    _socket!.on('message', (data) {
      final message = _convertToFlutterChatMessage(data);
      _onMessageReceived?.call(message);
    });

    _socket!.on('error', (data) {
      _onError?.call(data['message'] ?? 'Unknown error');
    });
  }

  void sendMessage(String text) {
    if (_socket?.connected == true && _sessionId != null) {
      _socket!.emit('chat:message', {
        'sessionId': _sessionId!,
        'text': text,
      });
    }
  }

  types.Message _convertToFlutterChatMessage(Map<String, dynamic> data) {
    final role = data['role'] ?? 'assistant';
    final content = data['content'] ?? '';

    return types.TextMessage(
      author: types.User(
        id: role == 'user' ? 'user' : 'assistant',
        firstName: role == 'user' ? 'Ты' : 'AIc',
      ),
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: content,
    );
  }

  void dispose() {
    _socket?.disconnect();
    _socket = null;
  }
}