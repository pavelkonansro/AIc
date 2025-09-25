import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:aic_mobile/main.dart';
import 'package:aic_mobile/state/auth_provider.dart';
import 'package:aic_mobile/services/auth_service.dart';
import 'package:aic_mobile/features/auth/simple_auth_page.dart';
import 'package:aic_mobile/features/chat/chat_page.dart';

// Генерируем моки
@GenerateMocks([AuthService, User, GoRouter])
import 'navigation_test.mocks.dart';

void main() {
  group('Navigation Tests', () {
    late MockAuthService mockAuthService;
    late MockUser mockUser;

    setUp(() {
      mockAuthService = MockAuthService();
      mockUser = MockUser();
    });

    testWidgets('should show auth page when user is not authenticated', (tester) async {
      // Arrange
      when(mockAuthService.authStateChanges)
          .thenAnswer((_) => Stream.value(null));
      when(mockAuthService.currentUser).thenReturn(null);
      when(mockAuthService.isAuthenticated).thenReturn(false);

      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(mockAuthService),
          ],
          child: MaterialApp(
            home: SimpleAuthPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Начать общение'), findsOneWidget);
      expect(find.text('Войти через Google'), findsOneWidget);
    });

    testWidgets('should navigate to chat after anonymous sign in', (tester) async {
      // Arrange
      when(mockUser.isAnonymous).thenReturn(true);
      when(mockUser.uid).thenReturn('anonymous_user_123');
      when(mockAuthService.signInAnonymously())
          .thenAnswer((_) async => mockUser);
      when(mockAuthService.authStateChanges)
          .thenAnswer((_) => Stream.value(null));

      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(mockAuthService),
          ],
          child: MaterialApp(
            home: SimpleAuthPage(),
            routes: {
              '/chat': (context) => Scaffold(body: Text('Chat Page')),
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Нажимаем кнопку "Начать общение"
      await tester.tap(find.text('Начать общение'));
      await tester.pumpAndSettle();

      // Assert
      verify(mockAuthService.signInAnonymously()).called(1);
    });

    testWidgets('should navigate to chat after Google sign in', (tester) async {
      // Arrange
      when(mockUser.isAnonymous).thenReturn(false);
      when(mockUser.email).thenReturn('test@gmail.com');
      when(mockUser.uid).thenReturn('google_user_123');
      when(mockAuthService.signInWithGoogle())
          .thenAnswer((_) async => mockUser);
      when(mockAuthService.authStateChanges)
          .thenAnswer((_) => Stream.value(null));

      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(mockAuthService),
          ],
          child: MaterialApp(
            home: SimpleAuthPage(),
            routes: {
              '/chat': (context) => Scaffold(body: Text('Chat Page')),
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Нажимаем кнопку "Войти через Google"
      await tester.tap(find.text('Войти через Google'));
      await tester.pumpAndSettle();

      // Assert
      verify(mockAuthService.signInWithGoogle()).called(1);
    });

    testWidgets('should show loading indicator during authentication', (tester) async {
      // Arrange
      when(mockAuthService.signInAnonymously())
          .thenAnswer((_) async {
            await Future.delayed(Duration(milliseconds: 100));
            return mockUser;
          });
      when(mockAuthService.authStateChanges)
          .thenAnswer((_) => Stream.value(null));

      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(mockAuthService),
          ],
          child: MaterialApp(
            home: SimpleAuthPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Нажимаем кнопку
      await tester.tap(find.text('Начать общение'));
      await tester.pump(); // Только один pump, чтобы увидеть загрузку

      // Assert - должен показывать индикатор загрузки
      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('should handle authentication failure gracefully', (tester) async {
      // Arrange
      when(mockAuthService.signInAnonymously())
          .thenThrow(Exception('Network error'));
      when(mockAuthService.authStateChanges)
          .thenAnswer((_) => Stream.value(null));

      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(mockAuthService),
          ],
          child: MaterialApp(
            home: SimpleAuthPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Нажимаем кнопку
      await tester.tap(find.text('Начать общение'));
      await tester.pumpAndSettle();

      // Assert - приложение не должно упасть
      expect(tester.takeException(), isNull);
    });

    testWidgets('should disable buttons during loading', (tester) async {
      // Arrange
      when(mockAuthService.signInAnonymously())
          .thenAnswer((_) async {
            await Future.delayed(Duration(milliseconds: 100));
            return mockUser;
          });
      when(mockAuthService.authStateChanges)
          .thenAnswer((_) => Stream.value(null));

      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(mockAuthService),
          ],
          child: MaterialApp(
            home: SimpleAuthPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Нажимаем первую кнопку
      await tester.tap(find.text('Начать общение'));
      await tester.pump(); // Один pump для начала загрузки

      // Пытаемся нажать вторую кнопку во время загрузки
      await tester.tap(find.text('Войти через Google'));
      await tester.pump();

      // Assert - вторая кнопка не должна сработать
      verify(mockAuthService.signInAnonymously()).called(1);
      verifyNever(mockAuthService.signInWithGoogle());
    });
  });

  group('Route Guards Tests', () {
    late MockAuthService mockAuthService;
    late MockUser mockUser;

    setUp(() {
      mockAuthService = MockAuthService();
      mockUser = MockUser();
    });

    testWidgets('should redirect to auth when accessing chat without authentication', (tester) async {
      // Arrange
      when(mockAuthService.authStateChanges)
          .thenAnswer((_) => Stream.value(null));
      when(mockAuthService.currentUser).thenReturn(null);
      when(mockAuthService.isAuthenticated).thenReturn(false);

      final router = GoRouter(
        initialLocation: '/chat',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => SimpleAuthPage(),
          ),
          GoRoute(
            path: '/chat',
            builder: (context, state) => Scaffold(body: Text('Chat Page')),
            redirect: (context, state) {
              // Симуляция guard'а
              return mockAuthService.isAuthenticated ? null : '/';
            },
          ),
        ],
      );

      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(mockAuthService),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert - должны быть перенаправлены на страницу аутентификации
      expect(find.text('Начать общение'), findsOneWidget);
      expect(find.text('Войти через Google'), findsOneWidget);
    });

    testWidgets('should allow access to chat when authenticated', (tester) async {
      // Arrange
      when(mockUser.uid).thenReturn('authenticated_user');
      when(mockAuthService.authStateChanges)
          .thenAnswer((_) => Stream.value(mockUser));
      when(mockAuthService.currentUser).thenReturn(mockUser);
      when(mockAuthService.isAuthenticated).thenReturn(true);

      final router = GoRouter(
        initialLocation: '/chat',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => SimpleAuthPage(),
          ),
          GoRoute(
            path: '/chat',
            builder: (context, state) => Scaffold(body: Text('Chat Page')),
            redirect: (context, state) {
              return mockAuthService.isAuthenticated ? null : '/';
            },
          ),
        ],
      );

      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(mockAuthService),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert - должны остаться на странице чата
      expect(find.text('Chat Page'), findsOneWidget);
    });
  });

  group('Auth State Navigation Tests', () {
    late MockAuthService mockAuthService;
    late MockUser mockUser;

    setUp(() {
      mockAuthService = MockAuthService();
      mockUser = MockUser();
    });

    testWidgets('should automatically navigate to chat when user signs in', (tester) async {
      // Arrange
      final streamController = StreamController<User?>();
      when(mockAuthService.authStateChanges)
          .thenAnswer((_) => streamController.stream);
      when(mockAuthService.currentUser).thenReturn(null);
      when(mockAuthService.isAuthenticated).thenReturn(false);

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
                          return Scaffold(body: Text('Chat Page'));
                        } else {
                          return SimpleAuthPage();
                        }
                      },
                      loading: () => Scaffold(body: CircularProgressIndicator()),
                      error: (error, stack) => Scaffold(body: Text('Error')),
                    );
                  },
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Проверяем что показывается страница аутентификации
      expect(find.text('Начать общение'), findsOneWidget);

      // Эмулируем успешную аутентификацию
      streamController.add(mockUser);
      await tester.pumpAndSettle();

      // Assert - должна показаться страница чата
      expect(find.text('Chat Page'), findsOneWidget);

      // Cleanup
      streamController.close();
    });

    testWidgets('should navigate back to auth when user signs out', (tester) async {
      // Arrange
      final streamController = StreamController<User?>();
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
                          return Scaffold(body: Text('Chat Page'));
                        } else {
                          return SimpleAuthPage();
                        }
                      },
                      loading: () => Scaffold(body: CircularProgressIndicator()),
                      error: (error, stack) => Scaffold(body: Text('Error')),
                    );
                  },
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Проверяем что показывается страница чата
      expect(find.text('Chat Page'), findsOneWidget);

      // Эмулируем выход
      streamController.add(null);
      await tester.pumpAndSettle();

      // Assert - должна показаться страница аутентификации
      expect(find.text('Начать общение'), findsOneWidget);

      // Cleanup
      streamController.close();
    });
  });
}