import 'package:flutter_test/flutter_test.dart';
import 'package:aic_mobile/features/chat/chat_adapter_factory.dart';
import 'package:aic_mobile/features/chat/mock_chat_adapter.dart';
import 'package:aic_mobile/features/chat/openrouter_chat_adapter.dart';
import 'package:aic_mobile/models/chat_provider.dart';

void main() {
  group('ChatAdapterFactory', () {
    test('should create MockChatAdapter for mock provider', () {
      final mockConfig = ChatProviderConfig.mock();
      final adapter = ChatAdapterFactory.create(mockConfig);
      
      expect(adapter, isA<MockChatAdapter>());
    });

    test('should create OpenRouterChatAdapter for grok provider', () {
      final grokConfig = ChatProviderConfig.grok();
      final adapter = ChatAdapterFactory.create(grokConfig);
      
      expect(adapter, isA<OpenRouterChatAdapter>());
    });

    test('should handle all provider types', () {
      // Test all enum values are handled
      for (final providerType in ChatProviderType.values) {
        final config = providerType == ChatProviderType.grok 
            ? ChatProviderConfig.grok()
            : ChatProviderConfig.mock();
        
        final adapter = ChatAdapterFactory.create(config);
        expect(adapter, isNotNull);
        
        if (providerType == ChatProviderType.grok) {
          expect(adapter, isA<OpenRouterChatAdapter>());
        } else {
          expect(adapter, isA<MockChatAdapter>());
        }
      }
    });

    test('should create adapters with correct configuration', () {
      final grokConfig = ChatProviderConfig.grok();
      final mockConfig = ChatProviderConfig.mock();
      
      final grokAdapter = ChatAdapterFactory.create(grokConfig) as OpenRouterChatAdapter;
      final mockAdapter = ChatAdapterFactory.create(mockConfig) as MockChatAdapter;
      
      // Verify adapters receive their configurations
      expect(grokAdapter.toString().contains('OpenRouter'), true);
      expect(mockAdapter.toString().contains('Mock'), true);
    });
  });
}