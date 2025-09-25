import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:aic_mobile/features/chat/mock_chat_adapter.dart';
import 'package:aic_mobile/models/chat_provider.dart';

void main() {
  group('MockChatAdapter', () {
    late MockChatAdapter adapter;
    late ChatProviderConfig config;

    setUp(() {
      config = ChatProviderConfig.mock();
      adapter = MockChatAdapter();
    });

    tearDown(() {
      adapter.dispose();
    });

    test('should initialize correctly', () async {
      await adapter.initialize(
        sessionId: 'test-session',
        config: config,
        onMessageReceived: (message) {},
        onError: (error) {},
      );
      expect(await adapter.checkConnection(), true);
    });

    test('should provide personalized responses', () async {
      final responses = <String>[];
      
      await adapter.initialize(
        sessionId: 'test-session',
        config: config,
        onMessageReceived: (message) {
          if (message is types.TextMessage) {
            responses.add(message.text);
          }
        },
        onError: (error) {},
      );
      
      // Test different types of messages
      await adapter.sendMessage('Привет!');
      await adapter.sendMessage('Как дела?');
      await adapter.sendMessage('Мне грустно');
      
      // Wait for responses
      await Future.delayed(Duration(milliseconds: 200));
      
      expect(responses.length, 3);
      expect(responses.every((response) => response.isNotEmpty), true);
      
      // Check that responses are not empty and contain emojis (basic check)
      final sadResponse = responses[2];
      expect(sadResponse.isNotEmpty, true);
      expect(sadResponse.contains(RegExp(r'[😊🤗🤔💡💪🧐🌟😔🎉💙]')), true);
    });

    test('should track message statistics', () async {
      await adapter.initialize(
        sessionId: 'test-session',
        config: config,
        onMessageReceived: (message) {},
        onError: (error) {},
      );
      
      await adapter.sendMessage('Test message 1');
      await adapter.sendMessage('Test message 2');
      
      final stats = adapter.getStats();
      expect(stats['messagesCount'], 2);
      expect(stats['isConnected'], true);
      expect(stats['totalTokens'], 0); // Mock doesn't use real tokens
    });

    test('should handle connection status correctly', () async {
      // Before initialization
      expect(await adapter.checkConnection(), false);
      
      // After initialization
      await adapter.initialize(
        sessionId: 'test-session',
        config: config,
        onMessageReceived: (message) {},
        onError: (error) {},
      );
      expect(await adapter.checkConnection(), true);
      
      // After disposal
      adapter.dispose();
      expect(await adapter.checkConnection(), false);
    });

    test('should notify about connection status changes', () async {
      bool? lastConnectionStatus;
      
      await adapter.initialize(
        sessionId: 'test-session',
        config: config,
        onMessageReceived: (message) {},
        onError: (error) {},
        onConnectionStatusChanged: (isConnected) {
          lastConnectionStatus = isConnected;
        },
      );
      
      expect(lastConnectionStatus, true);
      
      adapter.dispose();
      expect(lastConnectionStatus, false);
    });

    test('should update stats when sending messages', () async {
      Map<String, dynamic>? lastStats;
      
      await adapter.initialize(
        sessionId: 'test-session',
        config: config,
        onMessageReceived: (message) {},
        onError: (error) {},
        onStatsUpdated: (stats) {
          lastStats = stats;
        },
      );
      
      await adapter.sendMessage('Test message');
      
      expect(lastStats, isNotNull);
      expect(lastStats!['messagesCount'], 1);
      expect(lastStats!['isConnected'], true);
    });

    test('should provide different responses for similar inputs', () async {
      final responses = <String>[];
      
      await adapter.initialize(
        sessionId: 'test-session',
        config: config,
        onMessageReceived: (message) {
          if (message is types.TextMessage) {
            responses.add(message.text);
          }
        },
        onError: (error) {},
      );
      
      // Send same message multiple times
      for (int i = 0; i < 5; i++) {
        await adapter.sendMessage('Привет');
        await Future.delayed(Duration(milliseconds: 100));
      }
      
      // Should have variety in responses
      final uniqueResponses = responses.toSet();
      expect(uniqueResponses.length, greaterThan(1));
    });
  });
}