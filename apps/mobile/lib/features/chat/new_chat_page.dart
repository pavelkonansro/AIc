import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'chat_adapter.dart';
import '../../components/navigation/navigation.dart';

class NewChatPage extends ConsumerStatefulWidget {
  final String? initialMessage;
  final Map<String, dynamic>? context;

  const NewChatPage({
    super.key,
    this.initialMessage,
    this.context,
  });

  @override
  ConsumerState<NewChatPage> createState() => _NewChatPageState();
}

class _NewChatPageState extends ConsumerState<NewChatPage> {
  final List<types.Message> _messages = [];
  final _user = const types.User(id: 'user', firstName: 'Ты');
  final _assistant = const types.User(id: 'assistant', firstName: 'AIc');

  late final GrokChatAdapter _chatAdapter;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  Future<void> _initChat() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionId = prefs.getString('session_id');

    if (sessionId == null) {
      _showError('Сессия не найдена');
      return;
    }

    _chatAdapter = GrokChatAdapter();
    _chatAdapter.initialize(
      sessionId: sessionId,
      onMessageReceived: _handleMessageReceived,
      onError: _showError,
    );

    // Добавляем приветственное сообщение
    final welcomeMessage = types.TextMessage(
      author: _assistant,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: 'welcome',
      text: _getWelcomeMessage(),
    );

    setState(() {
      _messages.insert(0, welcomeMessage);
      _isConnected = true;
    });

    // Автоматически отправляем начальное сообщение
    if (widget.initialMessage?.isNotEmpty == true) {
      _handleSendPressed(types.PartialText(text: widget.initialMessage!));
    }
  }

  String _getWelcomeMessage() {
    if (widget.context != null) {
      final category = widget.context!['category'] as String?;
      final subcategory = widget.context!['subcategory'] as String?;

      if (category != null && subcategory != null) {
        return 'Привет! Я AIc 🐶 Вижу, ты интересуешься темой "$subcategory" из раздела "$category". Готов помочь разобраться с этим вопросом!';
      }
    }

    return 'Привет! Я AIc 🐶 Как у тебя настроение?';
  }

  void _handleMessageReceived(types.Message message) {
    setState(() {
      _messages.insert(0, message);
    });
  }

  void _handleSendPressed(types.PartialText message) {
    final textMessage = types.TextMessage(
      author: _user,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: message.text,
    );

    setState(() {
      _messages.insert(0, textMessage);
    });

    _chatAdapter.sendMessage(message.text);
  }

  void _showError(String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AicChatScaffold(
      title: 'Чат с AIc',
      currentRoute: '/chat',
      appBarActions: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: (_isConnected ? Colors.green : Colors.red).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _isConnected ? Icons.wifi : Icons.wifi_off,
                color: _isConnected ? Colors.green : Colors.red,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                _isConnected ? 'В сети' : 'Оффлайн',
                style: TextStyle(
                  color: _isConnected ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
      body: Chat(
        messages: _messages,
        onSendPressed: _handleSendPressed,
        user: _user,
        theme: DefaultChatTheme(
          backgroundColor: const Color(0xFFF8FAFC),
          primaryColor: Theme.of(context).colorScheme.primary,
          secondaryColor: const Color(0xFFF1F5F9),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _chatAdapter.dispose();
    super.dispose();
  }
}