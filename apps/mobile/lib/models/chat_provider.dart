/// Типы провайдеров чата
enum ChatProviderType {
  /// Grok AI через OpenRouter (по умолчанию)
  grok,
  
  /// Заглушка для тестирования без API вызовов
  mock,
}

/// Конфигурация провайдера чата
class ChatProviderConfig {
  final ChatProviderType type;
  final String name;
  final String? apiUrl;
  final String? model;
  final String systemPrompt;

  const ChatProviderConfig({
    required this.type,
    required this.name,
    this.apiUrl,
    this.model,
    required this.systemPrompt,
  });

  /// Конфигурация для Grok AI
  factory ChatProviderConfig.grok() {
    return const ChatProviderConfig(
      type: ChatProviderType.grok,
      name: 'Grok AI',
      apiUrl: 'https://openrouter.ai/api/v1',
      model: 'x-ai/grok-beta',
      systemPrompt: 'Ты AIc - дружелюбный AI компаньон для подростков в виде сенбернара 🐶. '
          'Отвечай по-русски, будь полезным и поддерживающим. '
          'Используй эмодзи для выражения эмоций. '
          'Помогай с учебой, эмоциональными вопросами и повседневными проблемами.',
    );
  }

  /// Конфигурация для Mock провайдера (тестирование)
  factory ChatProviderConfig.mock() {
    return const ChatProviderConfig(
      type: ChatProviderType.mock,
      name: 'Mock Provider',
      systemPrompt: 'Я AIc - дружелюбный помощник 🐶! '
          'Это тестовый режим, где я отвечаю заранее заготовленными фразами.',
    );
  }

  /// Получить конфигурацию по умолчанию для типа провайдера
  static ChatProviderConfig getDefault(ChatProviderType type) {
    switch (type) {
      case ChatProviderType.grok:
        return ChatProviderConfig.grok();
      case ChatProviderType.mock:
        return ChatProviderConfig.mock();
    }
  }

  /// Преобразовать в JSON
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'name': name,
      'apiUrl': apiUrl,
      'model': model,
      'systemPrompt': systemPrompt,
    };
  }

  /// Создать из JSON
  static ChatProviderConfig fromJson(Map<String, dynamic> json) {
    final typeString = json['type'] as String?;
    ChatProviderType type = ChatProviderType.grok; // по умолчанию
    
    if (typeString == 'mock') {
      type = ChatProviderType.mock;
    }
    
    return ChatProviderConfig(
      type: type,
      name: json['name'] as String? ?? 'Unknown Provider',
      apiUrl: json['apiUrl'] as String?,
      model: json['model'] as String?,
      systemPrompt: json['systemPrompt'] as String? ?? '',
    );
  }
}