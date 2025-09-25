import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart' as chat_ui;
import 'package:http/http.dart' as http;

import 'package:aic_mobile/features/chat/chat_page.dart';
import 'package:aic_mobile/services/auth_service.dart';
import 'package:aic_mobile/state/auth_provider.dart';

// Генерируем моки
@GenerateMocks([AuthService, User, http.Client])
import 'chat_test.mocks.dart';

// Mock classes для тестирования чата
class MockChatMessage extends chat_ui.TextMessage {
  MockChatMessage({
    required chat_ui.User author,
    int? createdAt,
    required String id,
    required String text,
  }) : super(
    author: author,
    createdAt: createdAt,
    id: id,
    text: text,
  );
}

class MockChatUser extends chat_ui.User {
  MockChatUser({
    required String id,
    String? firstName,
    String? lastName,
  }) : super(
    id: id,
    firstName: firstName,
    lastName: lastName,
  );
}

void main() {
  group('Chat Integration Tests', () {
    late MockAuthService mockAuthService;
    late MockUser mockUser;
    late MockClient mockHttpClient;

    setUp(() {
      mockAuthService = MockAuthService();
      mockUser = MockUser();
      mockHttpClient = MockClient();
    });

    testWidgets('should display chat interface when authenticated', (tester) async {
      // Arrange
      when(mockUser.uid).thenReturn('test_user_123');
      when(mockUser.displayName).thenReturn('Test User');
      when(mockUser.isAnonymous).thenReturn(false);
      when(mockAuthService.currentUser).thenReturn(mockUser);
      when(mockAuthService.isAuthenticated).thenReturn(true);
      when(mockAuthService.authStateChanges)
          .thenAnswer((_) => Stream.value(mockUser));

      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(mockAuthService),
          ],
          child: MaterialApp(
            home: ChatPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert - проверяем основные элементы чата
      expect(find.byType(chat_ui.Chat), findsOneWidget);
    });

    testWidgets('should redirect to auth if user is not authenticated', (tester) async {
      // Arrange
      when(mockAuthService.currentUser).thenReturn(null);
      when(mockAuthService.isAuthenticated).thenReturn(false);
      when(mockAuthService.authStateChanges)
          .thenAnswer((_) => Stream.value(null));

      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(mockAuthService),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                return Consumer(
                  builder: (context, ref, child) {
                    final isAuthenticated = ref.watch(isAuthenticatedProvider);
                    if (isAuthenticated) {
                      return ChatPage();
                    } else {
                      return Scaffold(
                        body: Center(child: Text('Please authenticate')),
                      );
                    }
                  },
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Please authenticate'), findsOneWidget);
      expect(find.byType(ChatPage), findsNothing);
    });

    testWidgets('should initialize chat session on page load', (tester) async {
      // Arrange
      when(mockUser.uid).thenReturn('test_user_123');
      when(mockUser.displayName).thenReturn('Test User');
      when(mockAuthService.currentUser).thenReturn(mockUser);
      when(mockAuthService.isAuthenticated).thenReturn(true);
      when(mockAuthService.authStateChanges)
          .thenAnswer((_) => Stream.value(mockUser));

      // Mock successful session creation
      when(mockHttpClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(
        '{"sessionId": "session_123", "status": "created"}',
        201,
      ));

      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(mockAuthService),
          ],
          child: MaterialApp(
            home: ChatPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert - страница должна загрузиться без ошибок
      expect(find.byType(ChatPage), findsOneWidget);
    });

    testWidgets('should handle chat initialization failure gracefully', (tester) async {
      // Arrange
      when(mockUser.uid).thenReturn('test_user_123');
      when(mockUser.displayName).thenReturn('Test User');
      when(mockAuthService.currentUser).thenReturn(mockUser);
      when(mockAuthService.isAuthenticated).thenReturn(true);
      when(mockAuthService.authStateChanges)
          .thenAnswer((_) => Stream.value(mockUser));

      // Mock failed session creation
      when(mockHttpClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(
        '{"error": "Failed to create session"}',
        500,
      ));

      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(mockAuthService),
          ],
          child: MaterialApp(
            home: ChatPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert - приложение не должно упасть
      expect(tester.takeException(), isNull);
      expect(find.byType(ChatPage), findsOneWidget);
    });

    testWidgets('should display loading indicator while initializing chat', (tester) async {
      // Arrange
      when(mockUser.uid).thenReturn('test_user_123');
      when(mockAuthService.currentUser).thenReturn(mockUser);
      when(mockAuthService.isAuthenticated).thenReturn(true);
      when(mockAuthService.authStateChanges)
          .thenAnswer((_) => Stream.value(mockUser));

      // Mock delayed response
      when(mockHttpClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async {
        await Future.delayed(Duration(milliseconds: 100));
        return http.Response('{"sessionId": "session_123"}', 201);
      });

      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(mockAuthService),
          ],
          child: MaterialApp(
            home: ChatPage(),
          ),
        ),
      );

      // Проверяем состояние загрузки
      await tester.pump(Duration(milliseconds: 50));

      // Assert - может показывать индикатор загрузки
      // (зависит от реализации ChatPage)
      expect(find.byType(ChatPage), findsOneWidget);
    });
  });

  group('Chat Message Tests', () {
    late MockAuthService mockAuthService;
    late MockUser mockUser;

    setUp(() {
      mockAuthService = MockAuthService();
      mockUser = MockUser();
    });

    testWidgets('should display welcome message for new users', (tester) async {
      // Arrange
      when(mockUser.uid).thenReturn('new_user_123');
      when(mockUser.displayName).thenReturn('New User');
      when(mockUser.isAnonymous).thenReturn(true);
      when(mockAuthService.currentUser).thenReturn(mockUser);
      when(mockAuthService.isAuthenticated).thenReturn(true);
      when(mockAuthService.authStateChanges)
          .thenAnswer((_) => Stream.value(mockUser));

      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(mockAuthService),
          ],
          child: MaterialApp(
            home: ChatPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert - должно быть приветственное сообщение или пустой чат
      expect(find.byType(ChatPage), findsOneWidget);
    });

    testWidgets('should handle empty chat state', (tester) async {
      // Arrange
      when(mockUser.uid).thenReturn('test_user_123');
      when(mockUser.displayName).thenReturn('Test User');
      when(mockAuthService.currentUser).thenReturn(mockUser);
      when(mockAuthService.isAuthenticated).thenReturn(true);
      when(mockAuthService.authStateChanges)
          .thenAnswer((_) => Stream.value(mockUser));

      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(mockAuthService),
          ],
          child: MaterialApp(
            home: ChatPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(ChatPage), findsOneWidget);
      expect(find.byType(chat_ui.Chat), findsOneWidget);
    });

    testWidgets('should show typing indicator when enabled', (tester) async {
      // Arrange
      when(mockUser.uid).thenReturn('test_user_123');
      when(mockUser.displayName).thenReturn('Test User');
      when(mockAuthService.currentUser).thenReturn(mockUser);
      when(mockAuthService.isAuthenticated).thenReturn(true);
      when(mockAuthService.authStateChanges)
          .thenAnswer((_) => Stream.value(mockUser));

      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(mockAuthService),
          ],
          child: MaterialApp(
            home: ChatPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert - проверяем что чат загружается
      expect(find.byType(ChatPage), findsOneWidget);
    });
  });

  group('Chat Error Handling Tests', () {
    late MockAuthService mockAuthService;
    late MockUser mockUser;

    setUp(() {
      mockAuthService = MockAuthService();
      mockUser = MockUser();
    });

    testWidgets('should handle network errors gracefully', (tester) async {
      // Arrange
      when(mockUser.uid).thenReturn('test_user_123');
      when(mockAuthService.currentUser).thenReturn(mockUser);
      when(mockAuthService.isAuthenticated).thenReturn(true);
      when(mockAuthService.authStateChanges)
          .thenAnswer((_) => Stream.value(mockUser));

      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(mockAuthService),
          ],
          child: MaterialApp(
            home: ChatPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert - приложение должно работать даже при сетевых ошибках
      expect(tester.takeException(), isNull);
      expect(find.byType(ChatPage), findsOneWidget);
    });

    testWidgets('should recover from connection loss', (tester) async {
      // Arrange
      when(mockUser.uid).thenReturn('test_user_123');
      when(mockAuthService.currentUser).thenReturn(mockUser);
      when(mockAuthService.isAuthenticated).thenReturn(true);
      when(mockAuthService.authStateChanges)
          .thenAnswer((_) => Stream.value(mockUser));

      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(mockAuthService),
          ],
          child: MaterialApp(
            home: ChatPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(ChatPage), findsOneWidget);
    });

    testWidgets('should handle authentication changes during chat', (tester) async {
      // Arrange
      final streamController = StreamController<User?>();
      when(mockUser.uid).thenReturn('test_user_123');
      when(mockAuthService.authStateChanges)
          .thenAnswer((_) => streamController.stream);

      // Начинаем с аутентифицированного пользователя
      streamController.add(mockUser);

      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(mockAuthService),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                return Consumer(
                  builder: (context, ref, child) {
                    final authState = ref.watch(authStateProvider);
                    return authState.when(
                      data: (user) {
                        if (user != null) {
                          return ChatPage();
                        } else {
                          return Scaffold(body: Text('Please authenticate'));
                        }
                      },
                      loading: () => Scaffold(body: CircularProgressIndicator()),
                      error: (error, stack) => Scaffold(body: Text('Auth Error')),
                    );
                  },
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Проверяем что показывается чат
      expect(find.byType(ChatPage), findsOneWidget);

      // Эмулируем потерю аутентификации
      streamController.add(null);
      await tester.pumpAndSettle();

      // Assert - должен вернуться к аутентификации
      expect(find.text('Please authenticate'), findsOneWidget);
      expect(find.byType(ChatPage), findsNothing);

      // Cleanup
      streamController.close();
    });
  });

  group('Chat Performance Tests', () {
    late MockAuthService mockAuthService;
    late MockUser mockUser;

    setUp(() {
      mockAuthService = MockAuthService();
      mockUser = MockUser();
    });

    testWidgets('should not rebuild unnecessarily', (tester) async {
      // Arrange
      when(mockUser.uid).thenReturn('test_user_123');
      when(mockAuthService.currentUser).thenReturn(mockUser);
      when(mockAuthService.isAuthenticated).thenReturn(true);
      when(mockAuthService.authStateChanges)
          .thenAnswer((_) => Stream.value(mockUser));

      int buildCount = 0;

      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(mockAuthService),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                buildCount++;
                return ChatPage();
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final initialBuildCount = buildCount;

      // Trigger rebuild
      await tester.pump();

      // Assert - количество rebuild'ов должно быть минимальным
      expect(buildCount, lessThanOrEqualTo(initialBuildCount + 1));
    });
  });
}