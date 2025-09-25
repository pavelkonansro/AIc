import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:aic_mobile/state/auth_provider.dart';
import 'package:aic_mobile/services/auth_service.dart';

// Генерируем моки
@GenerateMocks([AuthService, User])
import 'auth_controller_test.mocks.dart';

void main() {
  group('AuthController Tests', () {
    late ProviderContainer container;
    late MockAuthService mockAuthService;
    late MockUser mockUser;

    setUp(() {
      mockAuthService = MockAuthService();
      mockUser = MockUser();

      container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(mockAuthService),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    group('Anonymous Sign In', () {
      test('should sign in anonymously successfully', () async {
        // Arrange
        when(mockAuthService.signInAnonymously())
            .thenAnswer((_) async => mockUser);
        when(mockUser.isAnonymous).thenReturn(true);

        final controller = container.read(authControllerProvider.notifier);

        // Act
        final result = await controller.signInAnonymously();

        // Assert
        expect(result, isNotNull);
        expect(result?.isAnonymous, isTrue);
        verify(mockAuthService.signInAnonymously()).called(1);
      });

      test('should handle anonymous sign in failure', () async {
        // Arrange
        when(mockAuthService.signInAnonymously())
            .thenThrow(Exception('Sign in failed'));

        final controller = container.read(authControllerProvider.notifier);

        // Act & Assert
        expect(
          () async => await controller.signInAnonymously(),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Google Sign In', () {
      test('should sign in with Google successfully', () async {
        // Arrange
        when(mockAuthService.signInWithGoogle())
            .thenAnswer((_) async => mockUser);
        when(mockUser.email).thenReturn('test@gmail.com');
        when(mockUser.isAnonymous).thenReturn(false);

        final controller = container.read(authControllerProvider.notifier);

        // Act
        final result = await controller.signInWithGoogle();

        // Assert
        expect(result, isNotNull);
        expect(result?.email, equals('test@gmail.com'));
        expect(result?.isAnonymous, isFalse);
        verify(mockAuthService.signInWithGoogle()).called(1);
      });

      test('should handle Google sign in cancellation', () async {
        // Arrange
        when(mockAuthService.signInWithGoogle())
            .thenAnswer((_) async => null);

        final controller = container.read(authControllerProvider.notifier);

        // Act
        final result = await controller.signInWithGoogle();

        // Assert
        expect(result, isNull);
        verify(mockAuthService.signInWithGoogle()).called(1);
      });

      test('should handle Google sign in failure', () async {
        // Arrange
        when(mockAuthService.signInWithGoogle())
            .thenThrow(Exception('Google sign in failed'));

        final controller = container.read(authControllerProvider.notifier);

        // Act & Assert
        expect(
          () async => await controller.signInWithGoogle(),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Email Sign Up', () {
      test('should sign up with email successfully', () async {
        // Arrange
        const email = 'test@example.com';
        const password = 'password123';
        const displayName = 'Test User';

        when(mockAuthService.signUpWithEmailAndPassword(
          email: email,
          password: password,
          displayName: displayName,
        )).thenAnswer((_) async => mockUser);
        
        when(mockUser.email).thenReturn(email);
        when(mockUser.displayName).thenReturn(displayName);

        final controller = container.read(authControllerProvider.notifier);

        // Act
        final result = await controller.signUp(
          email: email,
          password: password,
          displayName: displayName,
        );

        // Assert
        expect(result, isNotNull);
        expect(result?.email, equals(email));
        expect(result?.displayName, equals(displayName));
        verify(mockAuthService.signUpWithEmailAndPassword(
          email: email,
          password: password,
          displayName: displayName,
        )).called(1);
      });

      test('should handle invalid email', () async {
        // Arrange
        const invalidEmail = 'invalid-email';
        const password = 'password123';

        when(mockAuthService.signUpWithEmailAndPassword(
          email: invalidEmail,
          password: password,
        )).thenThrow(Exception('Invalid email'));

        final controller = container.read(authControllerProvider.notifier);

        // Act & Assert
        expect(
          () async => await controller.signUp(
            email: invalidEmail,
            password: password,
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('should handle weak password', () async {
        // Arrange
        const email = 'test@example.com';
        const weakPassword = '123';

        when(mockAuthService.signUpWithEmailAndPassword(
          email: email,
          password: weakPassword,
        )).thenThrow(Exception('Weak password'));

        final controller = container.read(authControllerProvider.notifier);

        // Act & Assert
        expect(
          () async => await controller.signUp(
            email: email,
            password: weakPassword,
          ),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Sign Out', () {
      test('should sign out successfully', () async {
        // Arrange
        when(mockAuthService.signOut()).thenAnswer((_) async => {});

        final controller = container.read(authControllerProvider.notifier);

        // Act
        await controller.signOut();

        // Assert
        verify(mockAuthService.signOut()).called(1);
        
        // Проверяем состояние контроллера
        final state = container.read(authControllerProvider);
        expect(state, isA<AsyncData>());
      });

      test('should handle sign out failure', () async {
        // Arrange
        when(mockAuthService.signOut())
            .thenThrow(Exception('Sign out failed'));

        final controller = container.read(authControllerProvider.notifier);

        // Act
        await controller.signOut();

        // Assert
        verify(mockAuthService.signOut()).called(1);
        
        // Проверяем что состояние содержит ошибку
        final state = container.read(authControllerProvider);
        expect(state, isA<AsyncError>());
      });
    });

    group('State Management', () {
      test('should start with initial state', () {
        // Act
        final state = container.read(authControllerProvider);

        // Assert
        expect(state, isA<AsyncData>());
        expect(state.hasValue, isTrue);
        expect(state.valueOrNull, isNull);
      });

      test('should update state during sign out', () async {
        // Arrange
        when(mockAuthService.signOut()).thenAnswer((_) async => {});

        final controller = container.read(authControllerProvider.notifier);

        // Act
        final future = controller.signOut();

        // Проверяем состояние загрузки
        final loadingState = container.read(authControllerProvider);
        expect(loadingState, isA<AsyncLoading>());

        await future;

        // Проверяем финальное состояние
        final finalState = container.read(authControllerProvider);
        expect(finalState, isA<AsyncData>());
      });
    });
  });

  group('Auth Providers Tests', () {
    late ProviderContainer container;
    late MockAuthService mockAuthService;
    late MockUser mockUser;

    setUp(() {
      mockAuthService = MockAuthService();
      mockUser = MockUser();

      container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(mockAuthService),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('authStateProvider should provide user stream', () {
      // Arrange
      when(mockAuthService.authStateChanges)
          .thenAnswer((_) => Stream.value(mockUser));

      // Act
      final state = container.read(authStateProvider);

      // Assert
      expect(state, isA<AsyncValue<User?>>());
    });

    test('currentUserProvider should return current user', () {
      // Arrange
      when(mockAuthService.authStateChanges)
          .thenAnswer((_) => Stream.value(mockUser));

      // Act
      container.read(authStateProvider); // Инициализируем стрим
      final user = container.read(currentUserProvider);

      // Assert
      expect(user, equals(mockUser));
    });

    test('isAuthenticatedProvider should return true when user exists', () {
      // Arrange
      when(mockAuthService.authStateChanges)
          .thenAnswer((_) => Stream.value(mockUser));

      // Act
      container.read(authStateProvider); // Инициализируем стрим
      final isAuthenticated = container.read(isAuthenticatedProvider);

      // Assert
      expect(isAuthenticated, isTrue);
    });

    test('isAuthenticatedProvider should return false when user is null', () {
      // Arrange
      when(mockAuthService.authStateChanges)
          .thenAnswer((_) => Stream.value(null));

      // Act
      container.read(authStateProvider); // Инициализируем стрим
      final isAuthenticated = container.read(isAuthenticatedProvider);

      // Assert
      expect(isAuthenticated, isFalse);
    });

    test('isAnonymousProvider should return true for anonymous user', () {
      // Arrange
      when(mockUser.isAnonymous).thenReturn(true);
      when(mockAuthService.authStateChanges)
          .thenAnswer((_) => Stream.value(mockUser));

      // Act
      container.read(authStateProvider); // Инициализируем стрим
      final isAnonymous = container.read(isAnonymousProvider);

      // Assert
      expect(isAnonymous, isTrue);
    });

    test('isAnonymousProvider should return false for regular user', () {
      // Arrange
      when(mockUser.isAnonymous).thenReturn(false);
      when(mockAuthService.authStateChanges)
          .thenAnswer((_) => Stream.value(mockUser));

      // Act
      container.read(authStateProvider); // Инициализируем стрим
      final isAnonymous = container.read(isAnonymousProvider);

      // Assert
      expect(isAnonymous, isFalse);
    });
  });
}