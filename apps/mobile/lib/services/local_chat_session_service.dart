import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/logger.dart';
import '../state/app_state.dart';
import 'chat_session_service.dart';

/// Локальная реализация чат-сессий
/// Использует SharedPreferences для хранения данных
class LocalChatSessionService implements ChatSessionService {
  static const String _sessionsKey = 'local_chat_sessions';
  static const String _messagesPrefix = 'local_messages_';
  
  @override
  String get serviceType => 'Local Storage';

  @override
  Future<ChatSession> createSession(String userId) async {
    try {
      AppLogger.i('[$serviceType] Создаем локальную сессию для пользователя: $userId');
      
      final sessionId = _generateId();
      final session = ChatSession(
        id: sessionId,
        userId: userId,
        startedAt: DateTime.now(),
        status: 'active',
        messages: [],
      );

      await _saveSession(session);
      
      AppLogger.i('[$serviceType] Сессия создана локально: $sessionId');
      return session;
    } catch (e) {
      AppLogger.e('[$serviceType] Ошибка создания локальной сессии: $e');
      rethrow;
    }
  }

  @override
  Future<ChatSession?> getSession(String sessionId) async {
    try {
      AppLogger.d('[$serviceType] Получаем локальную сессию: $sessionId');
      
      final prefs = await SharedPreferences.getInstance();
      final sessionsJson = prefs.getString(_sessionsKey);
      
      if (sessionsJson == null) return null;
      
      final sessionsList = jsonDecode(sessionsJson) as List;
      final sessionData = sessionsList
          .cast<Map<String, dynamic>>()
          .where((s) => s['id'] == sessionId)
          .firstOrNull;
          
      if (sessionData == null) return null;
      
      // Загружаем сообщения сессии
      final messagesJson = prefs.getString('$_messagesPrefix$sessionId');
      List<ChatMessage> messages = [];
      
      if (messagesJson != null) {
        final messagesList = jsonDecode(messagesJson) as List;
        messages = messagesList
            .cast<Map<String, dynamic>>()
            .map((m) => ChatMessage.fromJson(m))
            .toList();
      }
      
      return ChatSession(
        id: sessionData['id'],
        userId: sessionData['userId'],
        startedAt: DateTime.parse(sessionData['startedAt']),
        status: sessionData['status'],
        messages: messages,
      );
    } catch (e) {
      AppLogger.e('[$serviceType] Ошибка получения локальной сессии: $e');
      return null;
    }
  }

  @override
  Future<List<ChatSession>> getUserSessions(String userId) async {
    try {
      AppLogger.d('[$serviceType] Получаем сессии пользователя: $userId');
      
      final prefs = await SharedPreferences.getInstance();
      final sessionsJson = prefs.getString(_sessionsKey);
      
      if (sessionsJson == null) return [];
      
      final sessionsList = jsonDecode(sessionsJson) as List;
      final sessions = <ChatSession>[];
      
      for (final sessionData in sessionsList.cast<Map<String, dynamic>>()) {
        if (sessionData['userId'] == userId) {
          final session = await getSession(sessionData['id']);
          if (session != null) {
            sessions.add(session);
          }
        }
      }
      
      return sessions;
    } catch (e) {
      AppLogger.e('[$serviceType] Ошибка получения сессий пользователя: $e');
      return [];
    }
  }

  @override
  Future<ChatMessage> addMessage(String sessionId, ChatMessage message) async {
    try {
      AppLogger.d('[$serviceType] Добавляем сообщение в сессию: $sessionId');
      
      final prefs = await SharedPreferences.getInstance();
      final messagesKey = '$_messagesPrefix$sessionId';
      
      // Получаем существующие сообщения
      List<Map<String, dynamic>> messages = [];
      final existingJson = prefs.getString(messagesKey);
      if (existingJson != null) {
        messages = (jsonDecode(existingJson) as List).cast<Map<String, dynamic>>();
      }
      
      // Добавляем новое сообщение
      final messageWithId = ChatMessage(
        id: message.id.isEmpty ? _generateId() : message.id,
        role: message.role,
        content: message.content,
        createdAt: message.createdAt,
        safetyFlag: message.safetyFlag,
      );
      
      messages.add(messageWithId.toJson());
      
      // Сохраняем обновленные сообщения
      await prefs.setString(messagesKey, jsonEncode(messages));
      
      return messageWithId;
    } catch (e) {
      AppLogger.e('[$serviceType] Ошибка добавления сообщения: $e');
      rethrow;
    }
  }

  @override
  Future<void> endSession(String sessionId) async {
    try {
      AppLogger.i('[$serviceType] Завершаем локальную сессию: $sessionId');
      
      final prefs = await SharedPreferences.getInstance();
      final sessionsJson = prefs.getString(_sessionsKey);
      
      if (sessionsJson != null) {
        final sessionsList = jsonDecode(sessionsJson) as List;
        final sessions = sessionsList.cast<Map<String, dynamic>>();
        
        // Обновляем статус сессии
        for (final session in sessions) {
          if (session['id'] == sessionId) {
            session['status'] = 'ended';
            break;
          }
        }
        
        await prefs.setString(_sessionsKey, jsonEncode(sessions));
      }
    } catch (e) {
      AppLogger.e('[$serviceType] Ошибка завершения локальной сессии: $e');
    }
  }

  @override
  Future<bool> isAvailable() async {
    try {
      // Проверяем доступность SharedPreferences
      await SharedPreferences.getInstance();
      return true;
    } catch (e) {
      AppLogger.e('[$serviceType] Локальное хранилище недоступно: $e');
      return false;
    }
  }

  /// Сохраняет сессию в локальное хранилище
  Future<void> _saveSession(ChatSession session) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Получаем существующие сессии
    List<Map<String, dynamic>> sessions = [];
    final existingJson = prefs.getString(_sessionsKey);
    if (existingJson != null) {
      sessions = (jsonDecode(existingJson) as List).cast<Map<String, dynamic>>();
    }
    
    // Добавляем новую сессию (без сообщений - они хранятся отдельно)
    sessions.add({
      'id': session.id,
      'userId': session.userId,
      'startedAt': session.startedAt.toIso8601String(),
      'status': session.status,
    });
    
    await prefs.setString(_sessionsKey, jsonEncode(sessions));
  }

  /// Генерирует уникальный ID
  String _generateId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(999999);
    return '${timestamp}_$random';
  }

  /// Очищает все локальные данные (для отладки)
  Future<void> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      for (final key in keys) {
        if (key.startsWith(_messagesPrefix) || key == _sessionsKey) {
          await prefs.remove(key);
        }
      }
      
      AppLogger.i('[$serviceType] Все локальные данные чата очищены');
    } catch (e) {
      AppLogger.e('[$serviceType] Ошибка очистки локальных данных: $e');
    }
  }
}