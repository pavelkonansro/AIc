import '../state/app_state.dart';

import '../state/app_state.dart';

/// Интерфейс для управления чат-сессиями
/// Может быть реализован как локально, так и удаленно
abstract class ChatSessionService {
  /// Создает новую чат-сессию для пользователя
  Future<ChatSession> createSession(String userId);
  
  /// Получает существующую сессию по ID
  Future<ChatSession?> getSession(String sessionId);
  
  /// Получает все сессии пользователя
  Future<List<ChatSession>> getUserSessions(String userId);
  
  /// Добавляет сообщение в сессию
  Future<ChatMessage> addMessage(String sessionId, ChatMessage message);
  
  /// Завершает сессию
  Future<void> endSession(String sessionId);
  
  /// Проверяет доступность сервиса
  Future<bool> isAvailable();
  
  /// Тип сервиса для логирования
  String get serviceType;
}