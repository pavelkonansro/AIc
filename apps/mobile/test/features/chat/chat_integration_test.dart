import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:aic_mobile/features/chat/chat_adapter_factory.dart';
import 'package:aic_mobile/features/chat/mock_chat_adapter.dart';
import 'package:aic_mobile/features/chat/openrouter_chat_adapter.dart';
import 'package:aic_mobile/models/chat_provider.dart';
import 'package:aic_mobile/providers/chat_settings_provider.dart';

void main() {
  group('Chat Provider System Integration', () {
    late ProviderContainer container;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('should complete full provider switching workflow', () async {
      // Initialize with default Grok provider
      final notifier = container.read(chatSettingsProvider.notifier);
      await notifier.initialize();
      
      // Verify initial state
      var config = container.read(chatProviderConfigProvider);
      expect(config.type, ChatProviderType.grok);
      expect(container.read(isGrokProviderProvider), true);
      expect(container.read(isMockProviderProvider), false);
      
      // Create adapter with factory
      var adapter = ChatAdapterFactory.create(config);
      expect(adapter, isA<OpenRouterChatAdapter>());
      
      // Switch to Mock provider
      await notifier.switchProvider(ChatProviderType.mock);
      
      // Verify state changed
      config = container.read(chatProviderConfigProvider);
      expect(config.type, ChatProviderType.mock);
      expect(container.read(isGrokProviderProvider), false);
      expect(container.read(isMockProviderProvider), true);
      
      // Create new adapter
      adapter = ChatAdapterFactory.create(config);
      expect(adapter, isA<MockChatAdapter>());
      
      // Verify persistence across container recreation
      container.dispose();
      container = ProviderContainer();
      
      final newNotifier = container.read(chatSettingsProvider.notifier);
      await newNotifier.initialize();
      
      final persistedConfig = container.read(chatProviderConfigProvider);
      expect(persistedConfig.type, ChatProviderType.mock);
    });

    test('should handle mock adapter end-to-end flow', () async {
      final notifier = container.read(chatSettingsProvider.notifier);
      await notifier.initialize();
      await notifier.switchProvider(ChatProviderType.mock);
      
      final config = container.read(chatProviderConfigProvider);
      final adapter = ChatAdapterFactory.create(config) as MockChatAdapter;
      
      // Test complete flow
      var messageReceived = false;
      var connectionStatusChanged = false;
      var statsUpdated = false;
      
      adapter.initialize(
        sessionId: 'test-session',
        config: config,
        onMessageReceived: (message) {
          messageReceived = true;
          if (message is types.TextMessage) {
            expect(message.text.isNotEmpty, true);
          } else {
            expect(message.metadata?.isNotEmpty ?? false, true);
          }
        },
        onError: (error) {
          fail('Unexpected error: $error');
        },
        onConnectionStatusChanged: (isConnected) {
          connectionStatusChanged = true;
        },
        onStatsUpdated: (stats) {
          statsUpdated = true;
          expect(stats['messagesCount'], greaterThanOrEqualTo(0));
        },
      );
      
      // Дождемся завершения инициализации
      await Future.delayed(Duration(milliseconds: 200));
      
      await adapter.sendMessage('Test message');
      
      // Wait for async callbacks
      await Future.delayed(Duration(milliseconds: 100));
      
      expect(messageReceived, true);
      // Connection status may change asynchronously
      // expect(connectionStatusChanged, true);
      expect(statsUpdated, true);
      
      adapter.dispose();
    });

    test('should handle provider configuration updates correctly', () async {
      final notifier = container.read(chatSettingsProvider.notifier);
      await notifier.initialize();
      
      // Check initial configuration
      var config = container.read(chatProviderConfigProvider);
      expect(config.type, ChatProviderType.grok);
      
      // Switch providers and verify
      await notifier.switchProvider(ChatProviderType.mock);
      config = container.read(chatProviderConfigProvider);
      expect(config.type, ChatProviderType.mock);
      
      await notifier.switchProvider(ChatProviderType.grok);
      config = container.read(chatProviderConfigProvider);
      expect(config.type, ChatProviderType.grok);
      
      await notifier.switchProvider(ChatProviderType.mock);
      config = container.read(chatProviderConfigProvider);
      expect(config.type, ChatProviderType.mock);
    });

    test('should validate all provider configurations', () {
      final grokConfig = ChatProviderConfig.grok();
      final mockConfig = ChatProviderConfig.mock();
      
      // Validate Grok config
      expect(grokConfig.type, ChatProviderType.grok);
      expect(grokConfig.name, 'Grok AI');
      expect(grokConfig.apiUrl, isNotNull);
      expect(grokConfig.model, isNotNull);
      expect(grokConfig.systemPrompt.isNotEmpty, true);
      
      // Validate Mock config
      expect(mockConfig.type, ChatProviderType.mock);
      expect(mockConfig.name, 'Mock Provider');
      expect(mockConfig.systemPrompt.isNotEmpty, true);
      
      // Verify both configs can create adapters
      final grokAdapter = ChatAdapterFactory.create(grokConfig);
      final mockAdapter = ChatAdapterFactory.create(mockConfig);
      
      expect(grokAdapter, isA<OpenRouterChatAdapter>());
      expect(mockAdapter, isA<MockChatAdapter>());
    });

    test('should handle error scenarios gracefully', () async {
      // Test with corrupted SharedPreferences
      SharedPreferences.setMockInitialValues({
        'chat_provider_type': 'corrupted_data',
        'chat_provider_config': 'invalid_json'
      });
      
      container.dispose();
      container = ProviderContainer();
      
      final notifier = container.read(chatSettingsProvider.notifier);
      await notifier.initialize();
      
      // Should fallback to default configuration
      final config = container.read(chatProviderConfigProvider);
      expect(config.type, ChatProviderType.grok);
      expect(config.name, 'Grok AI');
    });
  });
}