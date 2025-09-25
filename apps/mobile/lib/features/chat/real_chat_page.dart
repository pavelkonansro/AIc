import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:uuid/uuid.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../../services/api_client_simple.dart';
import '../../components/main_navigation.dart';

// Provider для сокет-соединения
final socketProvider = StateProvider<io.Socket?>((ref) => null);

// Provider для состояния соединения
final connectionStateProvider = StateProvider<String>((ref) => 'Отключен');

// Provider для сообщений чата
final chatMessagesProvider = StateProvider<List<types.Message>>((ref) => []);

class RealChatPage extends ConsumerStatefulWidget {
  const RealChatPage({super.key});

  @override
  ConsumerState<RealChatPage> createState() => _RealChatPageState();
}

class _RealChatPageState extends ConsumerState<RealChatPage> {
  final _user = const types.User(id: 'user', firstName: 'Ты');
  final _assistant = const types.User(id: 'assistant', firstName: 'AIc');
  String? _authToken;
  String? _sessionId;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  @override
  void dispose() {
    _disconnectSocket();
    super.dispose();
  }

  Future<void> _initializeChat() async {
    ref.read(loadingProvider.notifier).state = true;
    ref.read(connectionStateProvider.notifier).state = 'Подключение...';

    try {
      // 1. Создаем гостевого пользователя
      final apiClient = ref.read(apiClientProvider);
      final guestUser = await apiClient.createGuestUser();

      if (guestUser != null) {
        _authToken = guestUser['token'];
        apiClient.setToken(_authToken!);

        // 2. Подключаемся к сокету
        await _connectSocket();

        // 3. Добавляем приветственное сообщение
        _addWelcomeMessage();

        ref.read(connectionStateProvider.notifier).state = 'Подключен';
      } else {
        throw Exception('Не удалось создать пользователя');
      }
    } catch (e) {
      ref.read(connectionStateProvider.notifier).state = 'Ошибка: $e';
      _addErrorMessage('Не удалось подключиться к серверу. Проверьте соединение.');
    } finally {
      ref.read(loadingProvider.notifier).state = false;
    }
  }

  Future<void> _connectSocket() async {
    final socket = io.io('http://192.168.68.65:3000',
      io.OptionBuilder()
        .setTransports(['websocket'])
        .enableAutoConnect()
        .setExtraHeaders({'Authorization': 'Bearer $_authToken'})
        .build()
    );

    socket.onConnect((_) {
      print('✅ Сокет подключен');
      ref.read(connectionStateProvider.notifier).state = 'Подключен';
    });

    socket.onDisconnect((_) {
      print('❌ Сокет отключен');
      ref.read(connectionStateProvider.notifier).state = 'Отключен';
    });

    socket.on('message', (data) {
      _handleIncomingMessage(data);
    });

    socket.on('error', (error) {
      print('🔴 Ошибка сокета: $error');
      ref.read(connectionStateProvider.notifier).state = 'Ошибка сокета';
    });

    ref.read(socketProvider.notifier).state = socket;
  }

  void _disconnectSocket() {
    final socket = ref.read(socketProvider);
    socket?.disconnect();
    ref.read(socketProvider.notifier).state = null;
  }

  void _addWelcomeMessage() {
    final welcomeMessage = types.TextMessage(
      author: _assistant,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: const Uuid().v4(),
      text: 'Привет! Я AIc - твой AI-компаньон. Как дела? 😊\n\nЯ готов выслушать тебя и помочь с любыми вопросами!',
    );

    final messages = ref.read(chatMessagesProvider);
    ref.read(chatMessagesProvider.notifier).state = [welcomeMessage, ...messages];
  }

  void _addErrorMessage(String errorText) {
    final errorMessage = types.TextMessage(
      author: _assistant,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: const Uuid().v4(),
      text: '⚠️ $errorText',
    );

    final messages = ref.read(chatMessagesProvider);
    ref.read(chatMessagesProvider.notifier).state = [errorMessage, ...messages];
  }

  void _handleIncomingMessage(dynamic data) {
    try {
      final message = types.TextMessage(
        author: _assistant,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        id: const Uuid().v4(),
        text: data['content'] ?? data.toString(),
      );

      final messages = ref.read(chatMessagesProvider);
      ref.read(chatMessagesProvider.notifier).state = [message, ...messages];
    } catch (e) {
      print('Ошибка обработки сообщения: $e');
    }
  }

  void _handleSendPressed(types.PartialText message) {
    final textMessage = types.TextMessage(
      author: _user,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: const Uuid().v4(),
      text: message.text,
    );

    final messages = ref.read(chatMessagesProvider);
    ref.read(chatMessagesProvider.notifier).state = [textMessage, ...messages];

    // Отправляем сообщение через сокет
    _sendMessageToServer(message.text);
  }

  void _sendMessageToServer(String messageText) {
    final socket = ref.read(socketProvider);
    if (socket?.connected == true) {
      socket!.emit('sendMessage', {
        'content': messageText,
        'sessionId': _sessionId,
      });
    } else {
      // Fallback: простой ответ, если сокет не подключен
      Future.delayed(const Duration(milliseconds: 1000), () {
        final response = types.TextMessage(
          author: _assistant,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          id: const Uuid().v4(),
          text: 'Извини, сейчас у меня проблемы с соединением. Попробуй позже 😔',
        );

        final messages = ref.read(chatMessagesProvider);
        ref.read(chatMessagesProvider.notifier).state = [response, ...messages];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatMessagesProvider);
    final connectionState = ref.watch(connectionStateProvider);
    final isLoading = ref.watch(loadingProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            const Text('Чат с AIc'),
            Text(
              connectionState,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _initializeChat,
            tooltip: 'Переподключиться',
          ),
        ],
      ),
      body: Stack(
        children: [
          Chat(
            messages: messages,
            onSendPressed: _handleSendPressed,
            user: _user,
            theme: const DefaultChatTheme(
              backgroundColor: Colors.white,
              primaryColor: Colors.blue,
              secondaryColor: Color(0xFFF5F5F5),
              inputBackgroundColor: Color(0xFFF8F8F8),
            ),
            showUserAvatars: true,
            showUserNames: true,
            emptyState: Container(
              padding: const EdgeInsets.all(20),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Начни разговор с AIc!',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Подключение к AIc...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}