import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:aic_mobile/services/auth_service.dart';
import 'package:aic_mobile/services/mock_auth_service.dart';
import '../helpers/firebase_test_helper.dart';

void main() {
  group('AuthService Basic Tests', () {
    late AuthService authService;

    setUpAll(() async {
      // Инициализируем Firebase для тестов
      await setupFirebaseForTests();
    });

    setUp(() {
      authService = AuthService();
    });

    tearDownAll(() async {
      // Очищаем Firebase после тестов
      await cleanupFirebaseAfterTests();
    });

    tearDown(() {
      authService.dispose();
    });

    test('should initialize successfully', () async {
      // Act
      await authService.initialize();

      // Assert
      expect(authService, isNotNull);
    });

    test('should provide auth state stream', () async {
      // Arrange
      await authService.initialize();

      // Act
      final stream = authService.authStateChanges;

      // Assert
      expect(stream, isNotNull);
      expect(stream, isA<Stream<User?>>());
    });

    test('should handle sign in anonymously', () async {
      // Arrange
      await authService.initialize();

      // Act & Assert - не должно падать
      expect(() async => await authService.signInAnonymously(), returnsNormally);
    });

    test('should handle Google sign in', () async {
      // Arrange
      await authService.initialize();

      // Act & Assert - не должно падать
      expect(() async => await authService.signInWithGoogle(), returnsNormally);
    });

    test('should handle sign out', () async {
      // Arrange
      await authService.initialize();

      // Act & Assert - не должно падать
      expect(() async => await authService.signOut(), returnsNormally);
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

  group('MockAuthService Tests', () {
    test('should provide mock anonymous authentication', () async {
      // Act
      final user = await MockAuthService.signInAnonymously();

      // Assert
      expect(user, isNotNull);
      expect(user?.isAnonymous, isTrue);
    });

    test('should provide mock Google authentication', () async {
      // Act
      final user = await MockAuthService.signInWithGoogle();

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
      final user = await MockAuthService.signUpWithEmailAndPassword(
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
      await MockAuthService.signInAnonymously();

      // Act & Assert
      expect(() async => await MockAuthService.signOut(), returnsNormally);
      expect(MockAuthService.currentUser, isNull);
    });

    test('should provide auth state stream', () {
      // Act
      final stream = MockAuthService.authStateChanges;

      // Assert
      expect(stream, isNotNull);
      expect(stream, isA<Stream<User?>>());
    });
  });
}