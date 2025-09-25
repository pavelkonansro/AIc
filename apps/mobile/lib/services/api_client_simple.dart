import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../state/server_config_provider.dart';
import '../types/api_types.dart';

class ApiClient {
  final Dio _dio;
  final Logger _logger = Logger();
  String _baseUrl;

  // Геттер для доступа к базовому URL
  String get baseUrl => _baseUrl;

  ApiClient(this._baseUrl) : _dio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    headers: {
      'Content-Type': 'application/json',
      // Добавляем заголовок для ngrok
      'ngrok-skip-browser-warning': 'true',
    },
  )) {
    _dio.interceptors.add(LogInterceptor(
      logPrint: (message) => _logger.d(message),
    ));
  }

  // Простая проверка соединения с API
  Future<Map<String, dynamic>?> checkConnection() async {
    try {
      final response = await _dio.get('/health');
      _logger.i('API connection successful: ${response.statusCode}');
      return response.data;
    } catch (e) {
      _logger.e('API connection failed: $e');
      return null;
    }
  }

  // Создание гостевого пользователя для тестирования
  Future<Map<String, dynamic>?> createGuestUser() async {
    try {
      _logger.i('Attempting to create guest user at: $baseUrl/auth/guest');
      final response = await _dio.post('/auth/guest');
      _logger.i('Guest user created successfully: ${response.statusCode}');
      _logger.i('Response data: ${response.data}');
      return response.data;
    } catch (e) {
      _logger.e('Guest user creation failed with error: $e');
      _logger.e('Error type: ${e.runtimeType}');
      if (e is DioException) {
        _logger.e('DioException details:');
        _logger.e('- Type: ${e.type}');
        _logger.e('- Message: ${e.message}');
        _logger.e('- Response: ${e.response?.data}');
        _logger.e('- Status code: ${e.response?.statusCode}');
      }
      return null;
    }
  }

  // Получение информации о пользователе
  Future<Map<String, dynamic>?> getUserInfo(String token) async {
    try {
      final response = await _dio.get(
        '/auth/me',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      _logger.i('User info retrieved: ${response.statusCode}');
      return response.data;
    } catch (e) {
      _logger.e('Get user info failed: $e');
      return null;
    }
  }

  void setToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  // Обновление базового URL
  void updateBaseUrl(String newBaseUrl) {
    _baseUrl = newBaseUrl;
    _dio.options.baseUrl = newBaseUrl;
    _logger.i('API Client base URL updated to: $newBaseUrl');
  }

  String get currentBaseUrl => _baseUrl;

  // === МЕТОДЫ ДЛЯ ЧАТА ===

  // Создание сессии чата с типизированной валидацией
  Future<Map<String, dynamic>?> createChatSession() async {
    try {
      _logger.i('Creating chat session at: $baseUrl/chat/session');
      final response = await _dio.post('/chat/session');
      _logger.i('Chat session created successfully: ${response.statusCode}');

      final responseData = response.data as Map<String, dynamic>;
      _logger.i('Session data: $responseData');

      // Отладочная информация для диагностики
      ApiDebugUtils.logApiResponse('/chat/session', responseData);
      ApiDebugUtils.validateChatSessionResponse(responseData);

      // Типизированное создание объекта с валидацией
      try {
        final sessionResponse = ChatSessionResponse.fromJson(responseData);
        _logger.i('✅ Session successfully parsed: ${sessionResponse.sessionId}');
        // Возвращаем Map для обратной совместимости, но с валидацией
        return responseData;
      } catch (validationError) {
        _logger.e('❌ Session validation failed: $validationError');
        _logger.e('❌ Raw data: $responseData');
        // Возвращаем данные как есть для отладки
        return responseData;
      }
    } catch (e) {
      _logger.e('Chat session creation failed: $e');
      if (e is DioException) {
        _logger.e('- Response: ${e.response?.data}');
        _logger.e('- Status code: ${e.response?.statusCode}');
      }
      return null;
    }
  }

  // Отправка сообщения в чат
  Future<Map<String, dynamic>?> sendChatMessage(String sessionId, String message) async {
    try {
      _logger.i('Sending message to session $sessionId: $message');
      final response = await _dio.post(
        '/chat/message',
        data: {
          'sessionId': sessionId,
          'content': message,
        },
      );
      _logger.i('Message sent successfully: ${response.statusCode}');
      _logger.i('AI response: ${response.data}');
      return response.data;
    } catch (e) {
      _logger.e('Send message failed: $e');
      if (e is DioException) {
        _logger.e('- Response: ${e.response?.data}');
        _logger.e('- Status code: ${e.response?.statusCode}');
      }
      return null;
    }
  }

  // Получение истории сообщений сессии
  Future<List<dynamic>?> getChatMessages(String sessionId) async {
    try {
      _logger.i('Getting messages for session: $sessionId');
      final response = await _dio.get('/chat/session/$sessionId/messages');
      _logger.i('Messages retrieved successfully: ${response.statusCode}');
      return response.data;
    } catch (e) {
      _logger.e('Get messages failed: $e');
      if (e is DioException) {
        _logger.e('- Response: ${e.response?.data}');
        _logger.e('- Status code: ${e.response?.statusCode}');
      }
      return null;
    }
  }

  // Завершение сессии чата
  Future<Map<String, dynamic>?> endChatSession(String sessionId) async {
    try {
      _logger.i('Ending chat session: $sessionId');
      final response = await _dio.post('/chat/session/$sessionId/end');
      _logger.i('Session ended successfully: ${response.statusCode}');
      return response.data;
    } catch (e) {
      _logger.e('End session failed: $e');
      if (e is DioException) {
        _logger.e('- Response: ${e.response?.data}');
        _logger.e('- Status code: ${e.response?.statusCode}');
      }
      return null;
    }
  }
}

// Provider для API клиента
final apiClientProvider = Provider<ApiClient>((ref) {
  final apiConfig = ref.watch(currentApiConfigProvider);
  return ApiClient(apiConfig['baseUrl']!);
});