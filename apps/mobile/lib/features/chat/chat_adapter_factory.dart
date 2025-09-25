import 'chat_adapter_interface.dart';
import 'openrouter_chat_adapter.dart';
import 'mock_chat_adapter.dart';
import '../../models/chat_provider.dart';

/// Фабрика для создания чат адаптеров
class ChatAdapterFactory {
  /// Создать адаптер на основе конфигурации провайдера
  static ChatAdapter create(ChatProviderConfig config) {
    switch (config.type) {
      case ChatProviderType.grok:
        return OpenRouterChatAdapter();
      case ChatProviderType.mock:
        return MockChatAdapter();
    }
  }

  /// Создать адаптер по типу провайдера с настройками по умолчанию
  static ChatAdapter createDefault(ChatProviderType type) {
    final config = ChatProviderConfig.getDefault(type);
    return create(config);
  }
}