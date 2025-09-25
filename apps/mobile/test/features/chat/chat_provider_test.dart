import 'package:flutter_test/flutter_test.dart';
import 'package:aic_mobile/models/chat_provider.dart';

void main() {
  group('ChatProviderConfig', () {
    test('should create Grok configuration correctly', () {
      final grokConfig = ChatProviderConfig.grok();
      
      expect(grokConfig.type, ChatProviderType.grok);
      expect(grokConfig.name, 'Grok AI');
      expect(grokConfig.apiUrl, 'https://openrouter.ai/api/v1');
      expect(grokConfig.model, 'x-ai/grok-beta');
      expect(grokConfig.systemPrompt.isNotEmpty, true);
    });

    test('should create Mock configuration correctly', () {
      final mockConfig = ChatProviderConfig.mock();
      
      expect(mockConfig.type, ChatProviderType.mock);
      expect(mockConfig.name, 'Mock Provider');
      expect(mockConfig.apiUrl, isNull);
      expect(mockConfig.model, isNull);
      expect(mockConfig.systemPrompt.contains('дружелюбный'), true);
    });

    test('should serialize and deserialize correctly', () {
      final originalConfig = ChatProviderConfig.grok();
      final json = originalConfig.toJson();
      final deserializedConfig = ChatProviderConfig.fromJson(json);
      
      expect(deserializedConfig.type, originalConfig.type);
      expect(deserializedConfig.name, originalConfig.name);
      expect(deserializedConfig.apiUrl, originalConfig.apiUrl);
      expect(deserializedConfig.model, originalConfig.model);
      expect(deserializedConfig.systemPrompt, originalConfig.systemPrompt);
    });

    test('should handle ChatProviderType enum values', () {
      expect(ChatProviderType.values.length, 2);
      expect(ChatProviderType.values.contains(ChatProviderType.grok), true);
      expect(ChatProviderType.values.contains(ChatProviderType.mock), true);
    });
  });
}