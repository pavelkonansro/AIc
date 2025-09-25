// 🛡️ API Types для предотвращения ошибок интеграции
// Этот файл содержит строго типизированные модели для всех API ответов

class ChatSessionResponse {
  final String sessionId;
  final String startedAt;
  final String status;

  ChatSessionResponse({
    required this.sessionId,
    required this.startedAt,
    required this.status,
  });

  factory ChatSessionResponse.fromJson(Map<String, dynamic> json) {
    // Валидация обязательных полей с понятными ошибками
    if (json['sessionId'] == null) {
      throw ApiValidationException(
        'Missing required field: sessionId',
        field: 'sessionId',
        receivedData: json,
      );
    }

    if (json['startedAt'] == null) {
      throw ApiValidationException(
        'Missing required field: startedAt',
        field: 'startedAt',
        receivedData: json,
      );
    }

    if (json['status'] == null) {
      throw ApiValidationException(
        'Missing required field: status',
        field: 'status',
        receivedData: json,
      );
    }

    return ChatSessionResponse(
      sessionId: json['sessionId'] as String,
      startedAt: json['startedAt'] as String,
      status: json['status'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'startedAt': startedAt,
      'status': status,
    };
  }
}

class ChatMessageResponse {
  final String content;
  final String role;
  final String? id;
  final Map<String, dynamic>? metadata;

  ChatMessageResponse({
    required this.content,
    required this.role,
    this.id,
    this.metadata,
  });

  factory ChatMessageResponse.fromJson(Map<String, dynamic> json) {
    if (json['content'] == null) {
      throw ApiValidationException(
        'Missing required field: content',
        field: 'content',
        receivedData: json,
      );
    }

    return ChatMessageResponse(
      content: json['content'] as String,
      role: json['role'] as String? ?? 'assistant',
      id: json['id'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'role': role,
      if (id != null) 'id': id,
      if (metadata != null) 'metadata': metadata,
    };
  }
}

// Исключение для валидации API
class ApiValidationException implements Exception {
  final String message;
  final String? field;
  final Map<String, dynamic>? receivedData;

  const ApiValidationException(
    this.message, {
    this.field,
    this.receivedData,
  });

  @override
  String toString() {
    final buffer = StringBuffer('ApiValidationException: $message');

    if (field != null) {
      buffer.write('\nField: $field');
    }

    if (receivedData != null) {
      buffer.write('\nReceived data: $receivedData');
    }

    return buffer.toString();
  }
}

// Утилиты для отладки API
class ApiDebugUtils {
  static void logApiResponse(String endpoint, Map<String, dynamic> response) {
    print('🔍 API Response Debug:');
    print('   Endpoint: $endpoint');
    print('   Response: $response');
    print('   Keys: ${response.keys.toList()}');

    // Проверяем популярные поля
    final commonFields = ['id', 'sessionId', 'content', 'status', 'startedAt'];
    for (final field in commonFields) {
      if (response.containsKey(field)) {
        print('   ✅ $field: ${response[field]}');
      } else {
        print('   ❌ Missing: $field');
      }
    }
  }

  static void validateChatSessionResponse(Map<String, dynamic> response) {
    try {
      ChatSessionResponse.fromJson(response);
      print('✅ Chat session response validation: PASSED');
    } catch (e) {
      print('❌ Chat session response validation: FAILED');
      print('   Error: $e');
    }
  }

  static void validateChatMessageResponse(Map<String, dynamic> response) {
    try {
      ChatMessageResponse.fromJson(response);
      print('✅ Chat message response validation: PASSED');
    } catch (e) {
      print('❌ Chat message response validation: FAILED');
      print('   Error: $e');
    }
  }
}