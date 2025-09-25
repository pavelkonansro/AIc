import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import '../../models/chat_provider.dart';

/// Абстрактный интерфейс для чат адаптеров
abstract class ChatAdapter {
  /// Инициализация адаптера
  Future<void> initialize({
    required String sessionId,
    required ChatProviderConfig config,
    required Function(types.Message) onMessageReceived,
    required Function(String) onError,
    Function(bool)? onConnectionStatusChanged,
    Function(Map<String, dynamic>)? onStatsUpdated,
  });

  /// Отправить сообщение
  Future<void> sendMessage(String text);

  /// Проверить подключение
  Future<bool> checkConnection();

  /// Получить статистику
  Map<String, dynamic> getStats();

  /// Освободить ресурсы
  void dispose();
}

/// Базовые статистики чата
class ChatStats {
  final String model;
  final bool isConnected;
  final int totalTokens;
  final int messagesCount;
  final DateTime? lastMessageTime;

  const ChatStats({
    required this.model,
    required this.isConnected,
    required this.totalTokens,
    required this.messagesCount,
    this.lastMessageTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'model': model,
      'isConnected': isConnected,
      'totalTokens': totalTokens,
      'messagesCount': messagesCount,
      'lastMessageTime': lastMessageTime?.toIso8601String(),
    };
  }
}