import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../services/logger.dart';
import '../state/app_state.dart';
import '../state/server_config_provider.dart';
import 'chat_session_service.dart';

/// Удаленная реализация чат-сессий
/// Работает через REST API с сервером
class RemoteChatSessionService implements ChatSessionService {
  final ProviderRef ref;
  
  RemoteChatSessionService(this.ref);

  @override
  String get serviceType => 'Remote Server';

  String get _baseUrl => ref.read(currentApiConfigProvider)['baseUrl']!;

  @override
  Future<ChatSession> createSession(String userId) async {
    try {
      AppLogger.i('[$serviceType] Создаем удаленную сессию для пользователя: $userId');
      AppLogger.d('[$serviceType] Используем сервер: $_baseUrl');
      
      final response = await http.post(
        Uri.parse('$_baseUrl/chat/session'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': userId}),
      ).timeout(const Duration(seconds: 10));

      AppLogger.d('[$serviceType] Ответ сервера: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final session = ChatSession.fromJson(data);
        
        AppLogger.i('[$serviceType] Сессия создана на сервере: ${session.id}');
        return session;
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      AppLogger.e('[$serviceType] Ошибка создания удаленной сессии: $e');
      rethrow;
    }
  }

  @override
  Future<ChatSession?> getSession(String sessionId) async {
    try {
      AppLogger.d('[$serviceType] Получаем удаленную сессию: $sessionId');
      
      final response = await http.get(
        Uri.parse('$_baseUrl/chat/session/$sessionId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return ChatSession.fromJson(data);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      AppLogger.e('[$serviceType] Ошибка получения удаленной сессии: $e');
      return null;
    }
  }

  @override
  Future<List<ChatSession>> getUserSessions(String userId) async {
    try {
      AppLogger.d('[$serviceType] Получаем сессии пользователя: $userId');
      
      final response = await http.get(
        Uri.parse('$_baseUrl/chat/sessions?userId=$userId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        return data.map((item) => ChatSession.fromJson(item)).toList();
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      AppLogger.e('[$serviceType] Ошибка получения сессий пользователя: $e');
      return [];
    }
  }

  @override
  Future<ChatMessage> addMessage(String sessionId, ChatMessage message) async {
    try {
      AppLogger.d('[$serviceType] Добавляем сообщение в удаленную сессию: $sessionId');
      
      final response = await http.post(
        Uri.parse('$_baseUrl/chat/session/$sessionId/message'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'role': message.role,
          'content': message.content,
          'safetyFlag': message.safetyFlag,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return ChatMessage.fromJson(data);
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      AppLogger.e('[$serviceType] Ошибка добавления сообщения: $e');
      rethrow;
    }
  }

  @override
  Future<void> endSession(String sessionId) async {
    try {
      AppLogger.i('[$serviceType] Завершаем удаленную сессию: $sessionId');
      
      final response = await http.post(
        Uri.parse('$_baseUrl/chat/session/$sessionId/end'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      AppLogger.e('[$serviceType] Ошибка завершения удаленной сессии: $e');
    }
  }

  @override
  Future<bool> isAvailable() async {
    try {
      AppLogger.d('[$serviceType] Проверяем доступность сервера: $_baseUrl');
      
      final response = await http.get(
        Uri.parse('$_baseUrl/health'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      final isAvailable = response.statusCode == 200;
      AppLogger.d('[$serviceType] Сервер ${isAvailable ? 'доступен' : 'недоступен'}');
      
      return isAvailable;
    } catch (e) {
      AppLogger.w('[$serviceType] Сервер недоступен: $e');
      return false;
    }
  }
}