import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:aic_mobile/services/auth_service.dart';
import 'package:aic_mobile/services/mock_auth_service.dart';

void main() {
  group('MockAuthService Tests', () {
    test('Mock anonymous authentication', () async {
      final user = await MockAuthService.signInAnonymously();
      
      expect(user, isNotNull);
      expect(user!.isAnonymous, isTrue);
    });

    test('Mock Google authentication', () async {
      final user = await MockAuthService.signInWithGoogle();
      
      expect(user, isNotNull);
      expect(user!.email, contains('@gmail.com'));
    });

    test('Mock email signup with user registration', () async {
      print('🔄 Mock signing up with email: test@example.com');
      
      final user = await MockAuthService.signUpWithEmailAndPassword(
        email: 'test@example.com', 
        password: 'password123',
        displayName: 'Test User'
      );
      
      print('✅ Mock email sign up successful');
      expect(user, isNotNull);
      expect(user!.email, equals('test@example.com'));
      expect(user!.displayName, equals('Test User'));
    });

    test('Mock sign out', () async {
      final service = MockAuthService();
      
      expect(() => MockAuthService.signOut(), returnsNormally);
      expect(MockAuthService.currentUser, isNull);
    });

    test('Mock auth state stream', () async {
      final user = await MockAuthService.signInAnonymously();
      
      expect(user, isNotNull);
      expect(user, isA<User>());
    });
  });
}