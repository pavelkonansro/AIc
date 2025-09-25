import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:uuid/uuid.dart';
import 'dart:math';

class SimpleChatPage extends ConsumerStatefulWidget {
  const SimpleChatPage({super.key});

  @override
  ConsumerState<SimpleChatPage> createState() => _SimpleChatPageState();
}

class _SimpleChatPageState extends ConsumerState<SimpleChatPage> {
  List<types.Message> _messages = [];
  final _user = const types.User(id: 'user');
  final _assistant = const types.User(id: 'assistant', firstName: 'AIc');

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  void _loadMessages() {
    final welcomeMessage = types.TextMessage(
      author: _assistant,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: const Uuid().v4(),
      text: 'Привет! Я AIc - твой AI-компаньон. Как дела? 😊',
    );

    setState(() {
      _messages = [welcomeMessage];
    });
  }

  void _addMessage(types.Message message) {
    setState(() {
      _messages.insert(0, message);
    });
  }

  void _handleSendPressed(types.PartialText message) {
    final textMessage = types.TextMessage(
      author: _user,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: const Uuid().v4(),
      text: message.text,
    );

    _addMessage(textMessage);

    // Симуляция ответа ассистента
    _simulateAssistantResponse(message.text);
  }

  void _simulateAssistantResponse(String userMessage) {
    Future.delayed(const Duration(milliseconds: 1000), () {
      final responses = [
        'Понимаю, расскажи больше об этом 🤔',
        'Это интересно! Как ты к этому относишься?',
        'Я слушаю тебя внимательно ✨',
        'Хочешь поговорить об этом подробнее?',
        'Спасибо, что делишься этим со мной 💙',
        'Как ты себя чувствуешь в связи с этим?',
        'Давай разберем это вместе 🤝',
      ];

      final randomResponse = responses[Random().nextInt(responses.length)];

      final assistantMessage = types.TextMessage(
        author: _assistant,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        id: const Uuid().v4(),
        text: randomResponse,
      );

      _addMessage(assistantMessage);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat с AIc'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Chat(
        messages: _messages,
        onSendPressed: _handleSendPressed,
        user: _user,
        theme: const DefaultChatTheme(
          backgroundColor: Colors.white,
          primaryColor: Colors.blue,
          secondaryColor: Color(0xFFF5F5F5),
        ),
        showUserAvatars: false,
        showUserNames: true,
      ),
    );
  }
}