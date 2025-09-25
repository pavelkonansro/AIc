import 'dart:math';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:logger/logger.dart';
import 'chat_adapter_interface.dart';
import '../../models/chat_provider.dart';

/// Mock чат адаптер для тестирования без реальных API вызовов
class MockChatAdapter implements ChatAdapter {
  final Logger _logger = Logger();
  
  String? _sessionId;
  ChatProviderConfig? _config;
  Function(types.Message)? _onMessageReceived;
  Function(String)? _onError;
  Function(bool)? _onConnectionStatusChanged;
  Function(Map<String, dynamic>)? _onStatsUpdated;

  bool _isConnected = false;
  int _messagesCount = 0;
  DateTime? _lastMessageTime;

  final List<String> _mockResponses = [
    'Привет! 😊 Как дела? Я готов тебе помочь!',
    'Понимаю тебя 🤗 Расскажи больше об этом.',
    'Интересно! 🤔 А что ты об этом думаешь?',
    'Отличный вопрос! 💡 Давай разберемся вместе.',
    'Я здесь, чтобы тебя поддержать 💪 Продолжай!',
    'Хм, это действительно важная тема 🧐 Что тебя больше всего беспокоит?',
    'Ты молодец, что думаешь об этом! 🌟 Это показывает твою зрелость.',
    'Понимаю, иногда бывает сложно 😔 Но мы найдем решение!',
    'Отлично! 🎉 Я рад, что ты делишься со мной своими мыслями.',
    'Это нормальные чувства 💙 Многие подростки через это проходят.',
  ];

  @override
  Future<void> initialize({
    required String sessionId,
    required ChatProviderConfig config,
    required Function(types.Message) onMessageReceived,
    required Function(String) onError,
    Function(bool)? onConnectionStatusChanged,
    Function(Map<String, dynamic>)? onStatsUpdated,
  }) async {
    _sessionId = sessionId;
    _config = config;
    _onMessageReceived = onMessageReceived;
    _onError = onError;
    _onConnectionStatusChanged = onConnectionStatusChanged;
    _onStatsUpdated = onStatsUpdated;

    _logger.i('Инициализация Mock чат адаптера для сессии: $sessionId');
    
    // Эмулируем подключение
    await Future.delayed(const Duration(milliseconds: 100));
    _isConnected = true;
    _onConnectionStatusChanged?.call(true);
    _updateStats();
    _logger.i('Mock чат адаптер успешно подключен');
  }

  @override
  Future<void> sendMessage(String text) async {
    if (!_isConnected) {
      _onError?.call('Mock адаптер не подключен');
      return;
    }

    _logger.i('Получено сообщение в Mock адаптер: $text');

    try {
      // Эмулируем задержку обработки
      // Настройки для Mock провайдера
      final delay = 1000; // Фиксированная задержка
      final enableTyping = true; // Всегда показываем эффект печатания

      if (enableTyping) {
        // Эмулируем индикатор печати
        await Future.delayed(Duration(milliseconds: delay ~/ 2));
      }

      // Выбираем случайный ответ
      final random = Random();
      final responseIndex = random.nextInt(_mockResponses.length);
      final response = _mockResponses[responseIndex];

      // Добавляем персонализированный ответ на основе ключевых слов
      final personalizedResponse = _personalizeResponse(text, response);

      await Future.delayed(Duration(milliseconds: delay ~/ 2));

      // Создаем сообщение для UI
      final message = types.TextMessage(
        author: const types.User(id: 'assistant', firstName: 'AIc'),
        createdAt: DateTime.now().millisecondsSinceEpoch,
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: personalizedResponse,
      );

      _messagesCount++;
      _lastMessageTime = DateTime.now();
      _updateStats();

      _onMessageReceived?.call(message);
      _logger.i('Mock ответ отправлен: $personalizedResponse');

    } catch (e) {
      _logger.e('Ошибка в Mock адаптере: $e');
      _onError?.call('Ошибка Mock адаптера: $e');
    }
  }

  /// Персонализирует ответ на основе ключевых слов в сообщении пользователя
  String _personalizeResponse(String userMessage, String baseResponse) {
    final lowercaseMessage = userMessage.toLowerCase();
    
    // Реакция на эмоциональные слова
    if (lowercaseMessage.contains(RegExp(r'\b(грустно|плохо|печально|расстроен|депрессия)\b'))) {
      return 'Понимаю, что тебе грустно 😔 $baseResponse Помни - это пройдет!';
    }
    
    if (lowercaseMessage.contains(RegExp(r'\b(счастлив|радостно|отлично|супер|круто)\b'))) {
      return 'Как здорово, что у тебя хорошее настроение! 😄 $baseResponse';
    }
    
    if (lowercaseMessage.contains(RegExp(r'\b(школа|учеба|экзамен|урок|домашка)\b'))) {
      return 'Ах, школьные дела! 📚 $baseResponse Учеба важна, но не забывай отдыхать!';
    }
    
    if (lowercaseMessage.contains(RegExp(r'\b(друзья|дружба|компания|одиночество)\b'))) {
      return 'Дружба - это важно! 👫 $baseResponse';
    }
    
    if (lowercaseMessage.contains(RegExp(r'\b(родители|мама|папа|семья)\b'))) {
      return 'Семейные отношения бывают сложными 👨‍👩‍👧‍👦 $baseResponse';
    }
    
    // Реакция на вопросы
    if (lowercaseMessage.contains('?') || lowercaseMessage.startsWith(RegExp(r'\b(как|что|где|когда|почему|зачем)\b'))) {
      return 'Отличный вопрос! 🤔 $baseResponse';
    }
    
    return baseResponse;
  }

  @override
  Future<bool> checkConnection() async {
    // Mock всегда "подключен"
    await Future.delayed(const Duration(milliseconds: 100));
    return _isConnected;
  }

  @override
  Map<String, dynamic> getStats() {
    return ChatStats(
      model: 'Mock Chat Bot',
      isConnected: _isConnected,
      totalTokens: 0, // Mock не использует реальные токены
      messagesCount: _messagesCount,
      lastMessageTime: _lastMessageTime,
    ).toMap();
  }

  void _updateStats() {
    _onStatsUpdated?.call(getStats());
  }

  @override
  void dispose() {
    _logger.i('Mock чат адаптер освобожден');
    _isConnected = false;
    _onConnectionStatusChanged?.call(false);
    _sessionId = null;
    _config = null;
    _onMessageReceived = null;
    _onError = null;
    _onConnectionStatusChanged = null;
    _onStatsUpdated = null;
  }
}