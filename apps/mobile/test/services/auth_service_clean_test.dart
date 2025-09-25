import 'package:flutter_test/flutter_test.dart';// Правильная архитектура тестирования AuthService

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;import 'package:flutter_test    test('should provide mock email authentication', () async {

      // Act

import 'package:aic_mobile/services/auth_service.dart';      final user = await service.signUpWithEmailAndPassword(

import 'package:aic_mobile/services/mock_auth_service.dart' as mock_service;        'test@example.com',

import '../helpers/firebase_test_helper.dart';        'password123',

      );

void main() {

  setUpAll(() async {      // Assert

    await setupFirebaseForTests();      expect(user, isNotNull);

  });      expect(user?.uid, isNotEmpty);est.dart';

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

  tearDownAll(() async {

    await cleanupFirebaseAfterTests();import 'package:aic_mobile/services/auth_service.dart';

  });import 'package:aic_mobile/services/mock_auth_service.dart' as mock_service;



  group('AuthService Integration Tests (Real-like behavior)', () {void main() {

    late AuthService authService;  group('AuthService Integration Tests (Real-like behavior)', () {

    late AuthService authService;

    setUp(() {

      authService = AuthService();    setUp(() {

    });      authService = AuthService();

    });

    tearDown(() {

      // Clean up if needed    tearDown(() {

    });      authService.dispose();

    });

    test('should fallback to MockAuthService when Firebase unavailable', () async {

      // Arrange    test('should fallback to MockAuthService when Firebase unavailable', () async {

      await authService.initialize();      // Arrange & Act

      await authService.initialize();

      // Assert

      expect(authService, isNotNull);      // Assert

      // AuthService должен автоматически переключиться на MockAuthService

      // Check that auth state changes stream is available      // когда Firebase недоступен (что и происходит в тестах)

      final stream = authService.authStateChanges();      expect(authService, isNotNull);

      expect(stream, isNotNull);      

      expect(stream, isA<Stream<firebase_auth.User?>>());      // Проверяем что можем получить stream

    });      final stream = authService.authStateChanges;

      expect(stream, isNotNull);

    test('should handle anonymous authentication through fallback', () async {      expect(stream, isA<Stream<firebase_auth.User?>>());

      // Arrange    });

      await authService.initialize();

    test('should handle anonymous authentication through fallback', () async {

      // Act      // Arrange

      final user = await authService.signInAnonymously();      await authService.initialize();



      // Assert      // Act

      expect(user, isNotNull);      final user = await authService.signInAnonymously();

      // MockAuthService returns a user with specific uid

      expect(user?.uid, equals('anonymous_user_123'));      // Assert

    });      expect(user, isNotNull);

      // MockAuthService возвращает предсказуемые данные

    test('should handle sign out gracefully', () async {      expect(user?.uid, equals('anonymous_user_123'));

      // Arrange    });

      await authService.initialize();

      await authService.signInAnonymously();    test('should handle sign out gracefully', () async {

      // Arrange

      // Act & Assert      await authService.initialize();

      expect(() async => await authService.signOut(), returnsNormally);      await authService.signInAnonymously();

    });

      // Act & Assert

    test('should provide auth state changes stream', () async {      expect(() async => await authService.signOut(), returnsNormally);

      // Arrange    });

      await authService.initialize();

    test('should provide auth state changes stream', () async {

      // Act      // Arrange

      final stream = authService.authStateChanges();      await authService.initialize();



      // Assert      // Act

      expect(stream, isNotNull);      final stream = authService.authStateChanges;

      expect(stream, isA<Stream<firebase_auth.User?>>());

    });      // Assert

  });      expect(stream, isNotNull);

      expect(stream, isA<Stream<firebase_auth.User?>>());

  group('MockAuthService Direct Tests (Fast unit tests)', () {    });

    test('should provide mock anonymous authentication', () async {  });

      // Act

      final user = await mock_service.MockAuthService.signInAnonymously();  group('MockAuthService Direct Tests (Fast unit tests)', () {

    test('should provide mock anonymous authentication', () async {

      // Assert      // Act

      expect(user, isNotNull);      final user = await mock_service.MockAuthService.signInAnonymously();

      expect(user?.uid, equals('anonymous_user_123'));

    });      // Assert

      expect(user, isNotNull);

    test('should provide mock email authentication', () async {      expect(user?.uid, equals('anonymous_user_123'));

      // Act    });

      final user = await mock_service.MockAuthService.signUpWithEmailAndPassword(

        email: 'test@example.com',    test('should provide mock email authentication', () async {

        password: 'password123',            // Act

      );      final user = await service.signUpWithEmailAndPassword(

        'test@example.com',

      // Assert        'password123',

      expect(user, isNotNull);      );

      expect(user?.uid, isNotEmpty);

    });      // Assert

      expect(user, isNotNull);

    test('should handle sign out', () async {      expect(user?.uid, isNotEmpty);

      // Arrange    });

      await mock_service.MockAuthService.signInAnonymously();

    test('should handle sign out', () async {

      // Act & Assert      // Arrange

      expect(() async => await mock_service.MockAuthService.signOut(), returnsNormally);      await mock_service.MockAuthService.signInAnonymously();

      expect(mock_service.MockAuthService.currentUser, isNull);

    });      // Act & Assert

      expect(() async => await mock_service.MockAuthService.signOut(), returnsNormally);

    test('should provide auth state stream', () {      expect(mock_service.MockAuthService.currentUser, isNull);

      // Act    });

      final stream = mock_service.MockAuthService.authStateChanges();

    test('should provide auth state stream', () {

      // Assert      // Act

      expect(stream, isNotNull);      final stream = mock_service.MockAuthService.authStateChanges;

      expect(stream, isA<Stream<firebase_auth.User?>>());

    });      // Assert

  });      expect(stream, isNotNull);

}      expect(stream, isA<Stream<firebase_auth.User?>>());
    });
  });
}