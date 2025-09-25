import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:uuid/uuid.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_client_simple.dart';
import '../../state/auth_provider.dart';
import '../../config/api_config.dart';

// Provider для сообщений чата
final chatMessagesProvider = StateProvider<List<types.Message>>((ref) => []);

// Provider для состояния загрузки
final chatLoadingProvider = StateProvider<bool>((ref) => false);

// Provider для токена сессии чата
final chatSessionProvider = StateProvider<String?>((ref) => null);

class OpenRouterChatPage extends ConsumerStatefulWidget {
  const OpenRouterChatPage({super.key});

  @override
  ConsumerState<OpenRouterChatPage> createState() => _OpenRouterChatPageState();
}

class _OpenRouterChatPageState extends ConsumerState<OpenRouterChatPage> {
  final _user = const types.User(id: 'user', firstName: 'Ты');
  final _assistant = const types.User(id: 'assistant', firstName: 'AIc');

  @override
  void initState() {
    super.initState();
    // Отложить инициализацию до окончания build
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _initializeChat();
    });
  }

  Future<void> _initializeChat() async {
    // Отложить изменение состояния до завершения билда
    await Future(() {});

    if (mounted) {
      ref.read(chatLoadingProvider.notifier).state = true;
    }

    try {
      // 1. Создаем сессию чата
      final apiClient = ref.read(apiClientProvider);
      final sessionResponse = await apiClient.createChatSession();

      // Дополнительное отладочное логирование
      debugPrint('🔍 DEBUG: sessionResponse = $sessionResponse');
      debugPrint('🔍 DEBUG: sessionResponse type = ${sessionResponse.runtimeType}');
      if (sessionResponse != null) {
        debugPrint('🔍 DEBUG: sessionResponse keys = ${sessionResponse.keys}');
        debugPrint('🔍 DEBUG: sessionResponse["sessionId"] = ${sessionResponse["sessionId"]}');
        debugPrint('🔍 DEBUG: containsKey test = ${sessionResponse.containsKey("sessionId")}');
      }

      if (sessionResponse != null && sessionResponse.containsKey('sessionId') && sessionResponse['sessionId'] != null) {
        if (mounted) {
          ref.read(chatSessionProvider.notifier).state = sessionResponse['sessionId'];
        }

        // 2. Добавляем приветственное сообщение
        _addWelcomeMessage();

        debugPrint('✅ Чат инициализирован с сессией: ${sessionResponse['sessionId']}');
        debugPrint('🌐 Используется сервер: ${ApiConfig.currentServerName}');
        debugPrint('🔗 URL: ${ApiConfig.baseUrl}');

      } else {
        throw Exception('Не удалось создать сессию чата');
      }
    } catch (e) {
      debugPrint('❌ Ошибка инициализации чата: $e');
      _addErrorMessage('Не удалось подключиться к серверу. Проверьте соединение.');
    } finally {
      if (mounted) {
        ref.read(chatLoadingProvider.notifier).state = false;
      }
    }
  }

  void _addWelcomeMessage() {
    if (!mounted) return;

    final welcomeMessage = types.TextMessage(
      author: _assistant,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: const Uuid().v4(),
      text: '🤖 Привет! Я AIc - твой AI-компаньон, работающий на Grok-4. Как дела?\n\n✨ Я готов выслушать тебя и помочь с любыми вопросами!',
    );

    final messages = ref.read(chatMessagesProvider);
    ref.read(chatMessagesProvider.notifier).state = [welcomeMessage, ...messages];
  }

  void _addErrorMessage(String errorText) {
    if (!mounted) return;

    final errorMessage = types.TextMessage(
      author: _assistant,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: const Uuid().v4(),
      text: '⚠️ $errorText\n\n🔄 Попробуйте нажать кнопку обновления в правом верхнем углу.',
    );

    final messages = ref.read(chatMessagesProvider);
    ref.read(chatMessagesProvider.notifier).state = [errorMessage, ...messages];
  }

  void _addTypingIndicator() {
    if (!mounted) return;

    final typingMessage = types.TextMessage(
      author: _assistant,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: 'typing_${const Uuid().v4()}',
      text: '💭 AIc печатает...',
    );

    final messages = ref.read(chatMessagesProvider);
    ref.read(chatMessagesProvider.notifier).state = [typingMessage, ...messages];
  }

  void _removeTypingIndicator() {
    if (!mounted) return;

    final messages = ref.read(chatMessagesProvider);
    final updatedMessages = messages.where((msg) => !msg.id.startsWith('typing_')).toList();
    ref.read(chatMessagesProvider.notifier).state = updatedMessages;
  }

  void _handleSendPressed(types.PartialText message) async {
    final sessionId = ref.read(chatSessionProvider);
    if (sessionId == null) {
      _addErrorMessage('Сессия чата не инициализирована');
      return;
    }

    // Добавляем сообщение пользователя
    final textMessage = types.TextMessage(
      author: _user,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: const Uuid().v4(),
      text: message.text,
    );

    if (!mounted) return;

    final messages = ref.read(chatMessagesProvider);
    ref.read(chatMessagesProvider.notifier).state = [textMessage, ...messages];

    // Показываем индикатор печати
    _addTypingIndicator();

    try {
      // Отправляем сообщение в API
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.sendChatMessage(sessionId, message.text);

      // Убираем индикатор печати
      _removeTypingIndicator();

      if (!mounted) return;

      if (response != null && response['content'] != null) {
        final assistantMessage = types.TextMessage(
          author: _assistant,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          id: const Uuid().v4(),
          text: response['content'],
        );

        final updatedMessages = ref.read(chatMessagesProvider);
        ref.read(chatMessagesProvider.notifier).state = [assistantMessage, ...updatedMessages];

        debugPrint('✅ Получен ответ от Grok: ${response['content']}');
      } else {
        throw Exception('Пустой ответ от сервера');
      }
    } catch (e) {
      debugPrint('❌ Ошибка отправки сообщения: $e');
      _removeTypingIndicator();

      if (!mounted) return;

      final errorMessage = types.TextMessage(
        author: _assistant,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        id: const Uuid().v4(),
        text: '😔 Извини, у меня проблемы с соединением. Попробуй ещё раз.\n\nОшибка: $e',
      );

      final updatedMessages = ref.read(chatMessagesProvider);
      ref.read(chatMessagesProvider.notifier).state = [errorMessage, ...updatedMessages];
    }
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatMessagesProvider);
    final isLoading = ref.watch(chatLoadingProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            const Text('AIc Chat'),
            Text(
              '🌐 ${ApiConfig.currentServerName}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/');
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (!mounted) return;

              // Очищаем сообщения и переинициализируем чат
              ref.read(chatMessagesProvider.notifier).state = [];
              ref.read(chatSessionProvider.notifier).state = null;
              _initializeChat();
            },
            tooltip: 'Новая сессия',
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('О чате'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('🤖 AI модель: Grok-4-fast'),
                      Text('🌐 Сервер: ${ApiConfig.currentServerName}'),
                      Text('🔗 URL: ${ApiConfig.baseUrl}'),
                      const SizedBox(height: 8),
                      Text('Сессия: ${ref.read(chatSessionProvider) ?? "Не создана"}'),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
            tooltip: 'Информация',
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
              inputTextColor: Color(0xFF2C2C2C),
              inputBorderRadius: BorderRadius.all(Radius.circular(12)),
              inputMargin: EdgeInsets.all(8),
              inputPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              inputTextStyle: TextStyle(
                fontSize: 16,
                color: Color(0xFF2C2C2C),
                fontWeight: FontWeight.w400,
              ),
            ),
            showUserAvatars: true,
            showUserNames: true,
            emptyState: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.smart_toy,
                    size: 64,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Чат с Grok-4 готов!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Начни разговор с своим AI-компаньоном',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '🌐 ${ApiConfig.currentServerName}\n🤖 Grok-4-fast модель',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12),
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
                      '🤖 Подключение к Grok...',
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