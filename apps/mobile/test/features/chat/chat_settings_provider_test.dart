import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aic_mobile/models/chat_provider.dart';
import 'package:aic_mobile/providers/chat_settings_provider.dart';

void main() {
  group('ChatSettingsProvider', () {
    late ProviderContainer container;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('should initialize with default Grok provider', () async {
      final notifier = container.read(chatSettingsProvider.notifier);
      await notifier.initialize();
      
      final config = container.read(chatProviderConfigProvider);
      expect(config.type, ChatProviderType.grok);
    });

    test('should switch provider correctly', () async {
      final notifier = container.read(chatSettingsProvider.notifier);
      await notifier.initialize();
      
      // Switch to mock
      await notifier.switchProvider(ChatProviderType.mock);
      final mockConfig = container.read(chatProviderConfigProvider);
      expect(mockConfig.type, ChatProviderType.mock);
      
      // Switch back to grok
      await notifier.switchProvider(ChatProviderType.grok);
      final grokConfig = container.read(chatProviderConfigProvider);
      expect(grokConfig.type, ChatProviderType.grok);
    });

    test('should persist provider selection', () async {
      // First container - set mock provider
      final notifier1 = container.read(chatSettingsProvider.notifier);
      await notifier1.initialize();
      await notifier1.switchProvider(ChatProviderType.mock);
      
      // Create new container to simulate app restart
      container.dispose();
      container = ProviderContainer();
      
      final notifier2 = container.read(chatSettingsProvider.notifier);
      await notifier2.initialize();
      
      final config = container.read(chatProviderConfigProvider);
      expect(config.type, ChatProviderType.mock);
    });

    test('should correctly identify provider types', () async {
      final notifier = container.read(chatSettingsProvider.notifier);
      await notifier.initialize();
      
      // Initially Grok
      expect(container.read(isGrokProviderProvider), true);
      expect(container.read(isMockProviderProvider), false);
      
      // Switch to Mock
      await notifier.switchProvider(ChatProviderType.mock);
      expect(container.read(isGrokProviderProvider), false);
      expect(container.read(isMockProviderProvider), true);
    });

    test('should handle invalid stored provider gracefully', () async {
      // Set invalid value in SharedPreferences
      SharedPreferences.setMockInitialValues({
        'chat_provider_type': 'invalid_provider'
      });
      
      final notifier = container.read(chatSettingsProvider.notifier);
      await notifier.initialize();
      
      // Should fallback to default Grok
      final config = container.read(chatProviderConfigProvider);
      expect(config.type, ChatProviderType.grok);
    });
  });
}