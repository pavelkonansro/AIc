import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as socket_io;

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _controller = TextEditingController();
  final _messages = <Map<String, String>>[
    {'role': 'assistant', 'content': 'Привет! Я AIc 🐶 Как у тебя настроение?'},
  ];
  socket_io.Socket? _socket;
  String? _sessionId;
  bool _isConnected = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initSocket();
  }

  Future<void> _initSocket() async {
    try {
      debugPrint('🔄 Инициализируем WebSocket...');
      final prefs = await SharedPreferences.getInstance();
      _sessionId = prefs.getString('session_id');

      debugPrint('📋 Session ID: $_sessionId');

      if (_sessionId == null) {
        debugPrint('❌ Session ID не найден');
        _showError(
            'Сессия не найдена. Пожалуйста, вернитесь на страницу авторизации.');
        return;
      }

      debugPrint('🌐 Подключаемся к WebSocket...');
      _socket = socket_io.io(
          'http://localhost:3000/chat',
          socket_io.OptionBuilder()
              .setTransports(['websocket'])
              .enableAutoConnect()
              .build());

      _socket!.onConnect((_) {
        debugPrint('✅ WebSocket подключен');
        setState(() => _isConnected = true);
        if (_sessionId != null) {
          _socket!.emit('join_session', {'sessionId': _sessionId!});
          _addMessage('system', 'Подключено к чату');
        }
      });

      _socket!.onDisconnect((_) {
        debugPrint('❌ WebSocket отключен');
        setState(() => _isConnected = false);
        _addMessage('system', 'Отключено от чата');
      });

      _socket!.on('message', (data) {
        debugPrint('📨 Получено сообщение: $data');
        final role = data['role'] ?? 'assistant';
        final content = data['content'] ?? '';
        if (content.isNotEmpty) {
          _addMessage(role, content);
        }
        setState(() => _isLoading = false);
      });

      _socket!.on('error', (data) {
        debugPrint('❌ WebSocket ошибка: $data');
        _addMessage('error', 'Ошибка: ${data['message']}');
        setState(() => _isLoading = false);
      });
    } catch (e) {
      debugPrint('❌ Ошибка инициализации WebSocket: $e');
      _showError('Ошибка подключения: $e');
    }
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty || !_isConnected || _isLoading || _sessionId == null) {
      return;
    }

    debugPrint('📤 Отправляем сообщение: $text');
    debugPrint('📋 Session ID: $_sessionId');
    debugPrint('🔌 WebSocket подключен: $_isConnected');

    setState(() {
      _isLoading = true;
      _controller.clear();
    });

    _addMessage('user', text);

    // Проверяем, что все значения не null
    final messageData = {
      'sessionId': _sessionId!,
      'text': text,
    };

    debugPrint('📦 Данные для отправки: $messageData');
    _socket!.emit('chat:message', messageData);
  }

  void _addMessage(String role, String content) {
    setState(() {
      _messages.add({'role': role, 'content': content});
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _socket?.disconnect();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Чат с AIc'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                Icon(
                  _isConnected ? Icons.wifi : Icons.wifi_off,
                  color: _isConnected ? Colors.green : Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 4),
                Text(
                  _isConnected ? 'Подключено' : 'Отключено',
                  style: TextStyle(
                    color: _isConnected ? Colors.green : Colors.red,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (_, i) {
                if (i == _messages.length && _isLoading) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 8),
                          Text('AIc печатает...'),
                        ],
                      ),
                    ),
                  );
                }

                final m = _messages[i];
                final isUser = m['role'] == 'user';
                final isSystem = m['role'] == 'system';
                final isError = m['role'] == 'error';

                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isUser
                          ? Colors.indigo.shade100
                          : isError
                              ? Colors.red.shade100
                              : isSystem
                                  ? Colors.blue.shade100
                                  : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      m['content'] ?? '',
                      style: TextStyle(
                        color: isError ? Colors.red.shade700 : null,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    enabled: _isConnected && !_isLoading,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.all(12),
                      hintText: _isConnected
                          ? (_isLoading ? 'AIc печатает...' : 'Напиши AIc...')
                          : 'Подключение...',
                    ),
                    onSubmitted:
                        _isConnected && !_isLoading ? (_) => _send() : null,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _isConnected && !_isLoading ? _send : null,
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
