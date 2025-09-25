// Тестовая версия AuthService без Firebase инициализации
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:aic_mobile/services/mock_auth_service.dart' as mock_service;

// Простая версия тестов без реальной Firebase инициализации
@GenerateMocks([firebase_auth.FirebaseAuth, GoogleSignIn, firebase_auth.User, GoogleSignInAccount, GoogleSignInAuthentication])
import 'auth_service_test.mocks.dart' as mocks;

void main() {
  group('AuthService Testable Tests (Without Firebase Init)', () {
    test('should handle mock authentication successfully', () async {
      // Test mock authentication without Firebase initialization
      final user = await mock_service.MockAuthService.signInAnonymously();
      expect(user, isNotNull);
      expect(user.uid, equals('anonymous_user_123'));
    });

    test('should provide auth state stream', () {
      final stream = mock_service.MockAuthService.authStateChanges;
      expect(stream, isNotNull);
      expect(stream, isA<Stream<firebase_auth.User?>>());
    });

    test('should handle sign out', () async {
      await mock_service.MockAuthService.signInAnonymously();
      expect(() async => await mock_service.MockAuthService.signOut(), returnsNormally);
      expect(mock_service.MockAuthService.currentUser, isNull);
    });

    test('should provide mock email signup', () async {
      final user = await mock_service.MockAuthService.signUpWithEmailAndPassword(
        'test@example.com',
        'password123',
      );
      expect(user, isNotNull);
      expect(user.email, equals('test@example.com'));
    });
  });
}