import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class MockUser implements User {
  final String _uid;
  final String? _email;
  final String? _displayName;

  MockUser({
    required String uid,
    String? email,
    String? displayName,
  }) : _uid = uid, _email = email, _displayName = displayName;

  @override
  String get uid => _uid;

  @override
  String? get email => _email;

  @override
  String? get displayName => _displayName;

  @override
  bool get isAnonymous => _email == null;

  // Остальные методы User (минимальная реализация)
  @override
  bool get emailVerified => false;

  @override
  UserMetadata get metadata => throw UnimplementedError();

  @override
  String? get phoneNumber => null;

  @override
  String? get photoURL => null;

  @override
  List<UserInfo> get providerData => [];

  @override
  String? get refreshToken => null;

  @override
  String? get tenantId => null;

  @override
  Future<void> delete() => throw UnimplementedError();

  @override
  Future<String> getIdToken([bool forceRefresh = false]) => throw UnimplementedError();

  @override
  Future<IdTokenResult> getIdTokenResult([bool forceRefresh = false]) => throw UnimplementedError();

  @override
  Future<UserCredential> linkWithCredential(AuthCredential credential) => throw UnimplementedError();

  @override
  Future<UserCredential> linkWithProvider(AuthProvider provider) => throw UnimplementedError();

  @override
  Future<ConfirmationResult> linkWithPhoneNumber(String phoneNumber, [RecaptchaVerifier? verifier]) => throw UnimplementedError();

  @override
  Future<UserCredential> linkWithPopup(AuthProvider provider) => throw UnimplementedError();

  @override
  Future<void> linkWithRedirect(AuthProvider provider) => throw UnimplementedError();

  @override
  MultiFactor get multiFactor => throw UnimplementedError();

  @override
  Future<UserCredential> reauthenticateWithCredential(AuthCredential credential) => throw UnimplementedError();

  @override
  Future<UserCredential> reauthenticateWithProvider(AuthProvider provider) => throw UnimplementedError();

  @override
  Future<UserCredential> reauthenticateWithPopup(AuthProvider provider) => throw UnimplementedError();

  @override
  Future<void> reauthenticateWithRedirect(AuthProvider provider) => throw UnimplementedError();

  @override
  Future<void> reload() async {}

  @override
  Future<void> sendEmailVerification([ActionCodeSettings? actionCodeSettings]) => throw UnimplementedError();

  @override
  Future<User> unlink(String providerId) => throw UnimplementedError();

  @override
  Future<void> updateDisplayName(String? displayName) async {}

  @override
  Future<void> updateEmail(String newEmail) => throw UnimplementedError();

  @override
  Future<void> updatePassword(String newPassword) => throw UnimplementedError();

  @override
  Future<void> updatePhoneNumber(PhoneAuthCredential phoneCredential) => throw UnimplementedError();

  @override
  Future<void> updatePhotoURL(String? photoURL) async {}

  @override
  Future<void> updateProfile({String? displayName, String? photoURL}) async {}

  @override
  Future<void> verifyBeforeUpdateEmail(String newEmail, [ActionCodeSettings? actionCodeSettings]) => throw UnimplementedError();
}

class MockAuthService {
  static User? _currentUser;
  static final StreamController<User?> _authStateController = StreamController<User?>.broadcast();

  static Stream<User?> get authStateChanges => _authStateController.stream;
  static User? get currentUser => _currentUser;

  static Future<User?> signInAnonymously() async {
    if (kDebugMode) {
      try {
        await Future.delayed(const Duration(milliseconds: 500)); // Симуляция задержки
        
        _currentUser = MockUser(
          uid: 'mock_anonymous_${DateTime.now().millisecondsSinceEpoch}',
          email: null,
          displayName: 'Anonymous User',
        );
        
        _authStateController.add(_currentUser);
        return _currentUser;
      } catch (e) {
        print('❌ Mock anonymous sign in failed: $e');
        return null;
      }
    }
    return null;
  }

  static Future<User?> signInWithGoogle() async {
    if (kDebugMode) {
      try {
        await Future.delayed(const Duration(milliseconds: 800)); // Симуляция задержки
        
        _currentUser = MockUser(
          uid: 'mock_google_${DateTime.now().millisecondsSinceEpoch}',
          email: 'mockuser@gmail.com',
          displayName: 'Mock Google User',
        );
        
        _authStateController.add(_currentUser);
        return _currentUser;
      } catch (e) {
        print('❌ Mock Google sign in failed: $e');
        return null;
      }
    }
    return null;
  }

  static Future<User?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    if (kDebugMode) {
      try {
        print('🔄 Mock signing up with email: $email');
        await Future.delayed(const Duration(seconds: 1));
        
        _currentUser = MockUser(
          uid: 'mock_email_user_${DateTime.now().millisecondsSinceEpoch}',
          email: email,
          displayName: displayName ?? email.split('@')[0],
        );
        
        _authStateController.add(_currentUser);
        print('✅ Mock email sign up successful');
        return _currentUser;
      } catch (e) {
        print('❌ Mock email sign up failed: $e');
        return null;
      }
    }
    return null;
  }

  static Future<void> signOut() async {
    _currentUser = null;
    _authStateController.add(null);
  }
}