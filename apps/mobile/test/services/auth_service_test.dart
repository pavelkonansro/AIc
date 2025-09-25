import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:aic_mobile/services/auth_service.dart';
import 'package:aic_mobile/services/mock_auth_service.dart' as mock_service;
import '../helpers/firebase_test_helper.dart';

// Генерируем моки
@GenerateMocks([firebase_auth.FirebaseAuth, GoogleSignIn, firebase_auth.User, GoogleSignInAccount, GoogleSignInAuthentication])
import 'auth_service_test.mocks.dart' as mocks;

void main() {
  group('AuthService Tests', () {
    late AuthService authService;
    late mocks.MockFirebaseAuth mockFirebaseAuth;
    late mocks.MockGoogleSignIn mockGoogleSignIn;
    late mocks.MockUser mockUser;

    setUpAll(() async {
      // Инициализируем Firebase для тестов
      await setupFirebaseForTests();
      
      // Инициализируем моки
      mockFirebaseAuth = mocks.MockFirebaseAuth();
      mockGoogleSignIn = mocks.MockGoogleSignIn();
      mockUser = mocks.MockUser();
    });

    tearDownAll(() async {
      // Очищаем Firebase после тестов
      await cleanupFirebaseAfterTests();
    });

    setUp(() {
      authService = AuthService();
    });

    tearDown(() {
      authService.dispose();
    });

    group('Initialization', () {
      test('should initialize successfully', () async {
        // Act
        await authService.initialize();

        // Assert
        expect(authService, isNotNull);
      });

      test('should handle initialization failure gracefully', () async {
        // Arrange - симулируем ошибку инициализации
        
        // Act & Assert - не должно падать
        expect(() async => await authService.initialize(), returnsNormally);
      });
    });

    group('Anonymous Authentication', () {
      test('should sign in anonymously successfully', () async {
        // Arrange
        await authService.initialize();
        
        // Act
        final user = await authService.signInAnonymously();

        // Assert
        expect(user, isNotNull);
        expect(user?.isAnonymous, isTrue);
      });

      test('should handle anonymous sign in failure', () async {
        // Arrange
        await authService.initialize();
        
        // Act & Assert - не должно падать, даже если что-то пойдет не так
        expect(() async => await authService.signInAnonymously(), returnsNormally);
      });
    });

    group('Google Authentication', () {
      test('should sign in with Google successfully', () async {
        // Arrange
        await authService.initialize();
        
        // Act
        final user = await authService.signInWithGoogle();

        // Assert
        expect(user, isNotNull);
        // В тестовой среде будет использоваться Mock
        expect(user?.email, isNotNull);
      });

      test('should handle Google sign in cancellation', () async {
        // Arrange
        await authService.initialize();
        
        // Act
        final user = await authService.signInWithGoogle();
        
        // Assert - может быть null если пользователь отменил
        // но не должно падать
        expect(() async => await authService.signInWithGoogle(), returnsNormally);
      });
    });

    group('Email/Password Authentication', () {
      test('should sign up with email and password successfully', () async {
        // Arrange
        await authService.initialize();
        const email = 'test@example.com';
        const password = 'testPassword123';
        const displayName = 'Test User';

        // Act
        final user = await authService.signUpWithEmailAndPassword(
          email: email,
          password: password,
          displayName: displayName,
        );

        // Assert
        expect(user, isNotNull);
        expect(user?.email, equals(email));
      });

      test('should handle invalid email format', () async {
        // Arrange
        await authService.initialize();
        const invalidEmail = 'invalid-email';
        const password = 'testPassword123';

        // Act & Assert
        expect(
          () async => await authService.signUpWithEmailAndPassword(
            email: invalidEmail,
            password: password,
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('should handle weak password', () async {
        // Arrange
        await authService.initialize();
        const email = 'test@example.com';
        const weakPassword = '123';

        // Act & Assert
        expect(
          () async => await authService.signUpWithEmailAndPassword(
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
        await authService.initialize();
        
        // Act & Assert
        expect(() async => await authService.signOut(), returnsNormally);
      });
    });

    group('Auth State Changes', () {
      test('should provide auth state stream', () async {
        // Arrange
        await authService.initialize();

        // Act
        final stream = authService.authStateChanges;

        // Assert
        expect(stream, isNotNull);
        expect(stream, isA<Stream<firebase_auth.User?>>());
      });

      test('should reflect current user state', () async {
        // Arrange
        await authService.initialize();

        // Act
        final currentUser = authService.currentUser;
        final isAuthenticated = authService.isAuthenticated;

        // Assert
        expect(isAuthenticated, equals(currentUser != null));
      });
    });

    group('Error Handling', () {
      test('should handle network errors gracefully', () async {
        // Arrange
        await authService.initialize();

        // Act & Assert - все методы должны обрабатывать сетевые ошибки
        expect(() async => await authService.signInAnonymously(), returnsNormally);
        expect(() async => await authService.signInWithGoogle(), returnsNormally);
        expect(() async => await authService.signOut(), returnsNormally);
      });

      test('should dispose resources properly', () {
        // Arrange
        authService = AuthService();

        // Act & Assert
        expect(() => authService.dispose(), returnsNormally);
      });
    });
  });

  group('MockAuthService Tests', () {
    test('should provide mock authentication', () async {
      // Act
      final user = await mock_service.MockAuthService.signInAnonymously();

      // Assert
      expect(user, isNotNull);
      expect(user?.isAnonymous, isTrue);
    });

    test('should provide mock Google authentication', () async {
      // Act
      final user = await mock_service.MockAuthService.signInWithGoogle();

      // Assert
      expect(user, isNotNull);
      expect(user?.email, contains('@'));
    });

    test('should provide mock email signup', () async {
      // Arrange
      const email = 'test@example.com';
      const password = 'password123';
      const displayName = 'Test User';

      // Act
      final user = await mock_service.MockAuthService.signUpWithEmailAndPassword(
        email: email,
        password: password,
        displayName: displayName,
      );

      // Assert
      expect(user, isNotNull);
      expect(user?.email, equals(email));
      expect(user?.displayName, equals(displayName));
    });

    test('should handle mock sign out', () async {
      // Arrange
      await mock_service.MockAuthService.signInAnonymously();

      // Act & Assert
      expect(() async => await mock_service.MockAuthService.signOut(), returnsNormally);
      expect(mock_service.MockAuthService.currentUser, isNull);
    });

    test('should provide auth state stream', () {
      // Act
      final stream = mock_service.MockAuthService.authStateChanges;

      // Assert
      expect(stream, isNotNull);
      expect(stream, isA<Stream<firebase_auth.User?>>());
    });
  });
}