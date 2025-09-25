import 'package:dio/dio.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:logger/logger.dart';
import '../../utils/string_utils.dart';
import 'chat_adapter_interface.dart';
import '../../models/chat_provider.dart';

class OpenRouterChatAdapter implements ChatAdapter {

  final Logger _logger = Logger();
  late final Dio _dio;

  String? _sessionId;
  ChatProviderConfig? _config;
  Function(types.Message)? _onMessageReceived;
  Function(String)? _onError;
  Function(bool)? _onConnectionStatusChanged;
  Function(Map<String, dynamic>)? _onStatsUpdated;

  bool _isConnected = false;
  int _totalTokensUsed = 0;
  int _messagesCount = 0;
  DateTime? _lastMessageTime;

  final List<Map<String, dynamic>> _conversationHistory = [];

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

    // Инициализируем Dio с конфигурацией
    _dio = Dio(BaseOptions(
      baseUrl: config.apiUrl!,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer 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',
        'HTTP-Referer': 'https://aic-app.com',
        'X-Title': 'AIc - AI Companion for Teens'
      },
    ));

    _dio.interceptors.add(LogInterceptor(
      logPrint: (message) => _logger.d(message),
    ));

    await _checkConnection();
  }

  Future<void> _checkConnection() async {
    try {
      _logger.i('Проверка подключения к OpenRouter...');
      final response = await _dio.get('/models');
      _isConnected = true;
      _onConnectionStatusChanged?.call(true);
      _updateStats();
      _logger.i('Подключение к OpenRouter успешно');
    } catch (e) {
      _isConnected = false;
      _onConnectionStatusChanged?.call(false);
      _logger.e('Ошибка подключения к OpenRouter: $e');
      _onError?.call('Не удалось подключиться к AI сервису');
    }
  }

  @override
  Future<bool> checkConnection() async {
    try {
      final response = await _dio.get('/models');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> sendMessage(String text) async {
    if (!_isConnected) {
      _onError?.call('Нет подключения к AI сервису');
      return;
    }

    try {
      _logger.i('Отправка сообщения в OpenRouter: $text');

      // Добавляем сообщение пользователя в историю
      _conversationHistory.add({
        'role': 'user',
        'content': text,
      });

      // Добавляем системное сообщение если это первое сообщение
      final messages = <Map<String, dynamic>>[];
      if (_conversationHistory.length == 1) {
        final systemPrompt = _config?.systemPrompt ?? 
          'Ты AIc - дружелюбный AI компаньон для подростков. Отвечай по-русски, будь полезным и поддерживающим. Используй эмодзи для выражения эмоций.';
        messages.add({
          'role': 'system',
          'content': systemPrompt
        });
      }

      messages.addAll(_conversationHistory);

      final temperature = 0.7;
      final maxTokens = 1000;

      final response = await _dio.post(
        '/chat/completions',
        data: {
          'model': _config?.model ?? 'x-ai/grok-beta',
          'messages': messages,
          'temperature': temperature,
          'max_tokens': maxTokens,
          'stream': false,
        },
      );

      final choice = response.data['choices']?[0];
      if (choice == null) {
        throw Exception('Нет ответа от AI');
      }

      final assistantMessage = choice['message']['content'] as String;
      final usage = response.data['usage'] as Map<String, dynamic>?;

      // Добавляем ответ ассистента в историю
      _conversationHistory.add({
        'role': 'assistant',
        'content': assistantMessage,
      });

      // Обновляем статистику
      if (usage != null) {
        _totalTokensUsed += (usage['total_tokens'] as int?) ?? 0;
      }
      _messagesCount++;
      _lastMessageTime = DateTime.now();
      _updateStats();

      // Создаем сообщение для UI
      final message = types.TextMessage(
        author: const types.User(id: 'assistant', firstName: 'AIc'),
        createdAt: DateTime.now().millisecondsSinceEpoch,
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: assistantMessage,
      );

      _onMessageReceived?.call(message);
      _logger.i('Получен ответ от OpenRouter: ${StringUtils.logPreview(assistantMessage)}');

    } catch (e) {
      _logger.e('Ошибка отправки сообщения: $e');
      if (e is DioException) {
        if (e.response?.statusCode == 401) {
          _onError?.call('Ошибка авторизации AI сервиса');
        } else if (e.response?.statusCode == 429) {
          _onError?.call('Превышен лимит запросов. Попробуйте позже');
        } else {
          _onError?.call('Ошибка AI сервиса: ${e.response?.statusMessage ?? e.message}');
        }
      } else {
        _onError?.call('Ошибка отправки сообщения: $e');
      }
    }
  }

  void _updateStats() {
    _onStatsUpdated?.call(getStats());
  }

  @override
  Map<String, dynamic> getStats() {
    return ChatStats(
      model: _config?.model ?? 'unknown',
      isConnected: _isConnected,
      totalTokens: _totalTokensUsed,
      messagesCount: _messagesCount,
      lastMessageTime: _lastMessageTime,
    ).toMap();
  }

  @override
  void dispose() {
    _conversationHistory.clear();
    _dio.close();
  }
}