import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:async';
import 'mock_auth_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final Logger _logger = Logger();
  FirebaseAuth? _firebaseAuth;
  GoogleSignIn? _googleSignIn;
  MockAuthService? _mockAuthService;
  bool _isFirebaseEnabled = false;
  
  final StreamController<User?> _authStateController = StreamController<User?>.broadcast();
  Stream<User?> get authStateChanges => _authStateController.stream;
  
  StreamSubscription<User?>? _firebaseSubscription;

  Future<void> initialize() async {
    try {
      // Используем Firebase для всех платформ (iOS, Android, Web)
      if (kIsWeb || defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.android) {
        _firebaseAuth = FirebaseAuth.instance;
        if (!kIsWeb) {
          _googleSignIn = GoogleSignIn();
        }
        _isFirebaseEnabled = true;
        _logger.i('Firebase initialized for ${kIsWeb ? "Web" : "Mobile"}');
        
        _firebaseSubscription = _firebaseAuth!.authStateChanges().listen(
          (user) {
            _logger.i('Firebase auth state changed: ${user?.uid ?? 'null'}');
            _authStateController.add(user);
          },
          onError: (error) {
            _logger.e('Firebase auth state error: $error');
          },
        );
      } else {
        _mockAuthService = MockAuthService();
        _logger.i('Mock auth service initialized');
        
        MockAuthService.authStateChanges.listen(
          (user) {
            _logger.i('Mock auth state changed: ${user?.uid ?? 'null'}');
            _authStateController.add(user);
          },
          onError: (error) {
            _logger.e('Mock auth state error: $error');
          },
        );
      }
      
      final currentUser = _getCurrentUser();
      _authStateController.add(currentUser);
      _logger.i('AuthService initialized. Current user: ${currentUser?.uid ?? 'null'}');
    } catch (e) {
      _logger.e('Failed to initialize AuthService: $e');
      _mockAuthService = MockAuthService();
      final currentUser = _getCurrentUser();
      _authStateController.add(currentUser);
    }
  }

  User? _getCurrentUser() {
    if (_isFirebaseEnabled && _firebaseAuth != null) {
      return _firebaseAuth!.currentUser;
    } else if (_mockAuthService != null) {
      return MockAuthService.currentUser;
    }
    return null;
  }

  User? get currentUser => _getCurrentUser();

  bool get isAuthenticated => currentUser != null;

  Future<User?> signInAnonymously() async {
    try {
      _logger.i('Starting guest sign in...');
      
      if (_isFirebaseEnabled && _firebaseAuth != null) {
        final result = await _firebaseAuth!.signInAnonymously();
        _logger.i('Guest sign in successful: ${result.user?.uid}');
        return result.user;
      } else if (_mockAuthService != null) {
        final user = await MockAuthService.signInAnonymously();
        _logger.i('Mock guest sign in successful: ${user?.uid}');
        return user;
      }
      throw Exception('No auth service available');
    } catch (e) {
      _logger.e('Guest sign in failed: $e');
      rethrow;
    }
  }

  Future<User?> signInWithGoogle() async {
    try {
      _logger.i('Starting Google sign in...');
      
      if (_isFirebaseEnabled && _firebaseAuth != null && _googleSignIn != null) {
        final GoogleSignInAccount? googleUser = await _googleSignIn!.signIn();
        if (googleUser == null) {
          _logger.w('Google sign in cancelled by user');
          return null;
        }

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final result = await _firebaseAuth!.signInWithCredential(credential);
        _logger.i('Google sign in successful: ${result.user?.uid}');
        return result.user;
      } else if (_mockAuthService != null) {
        final user = await MockAuthService.signInWithGoogle();
        _logger.i('Mock Google sign in successful: ${user?.uid}');
        return user;
      }
      throw Exception('No auth service available');
    } catch (e) {
      _logger.e('Google sign in failed: $e');
      rethrow;
    }
  }

  Future<User?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      _logger.i('Starting sign up with email: $email');
      
      if (_isFirebaseEnabled && _firebaseAuth != null) {
        final result = await _firebaseAuth!.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        
        // Обновляем displayName если указано
        if (displayName != null && result.user != null) {
          await result.user!.updateDisplayName(displayName);
        }
        
        _logger.i('Email sign up successful: ${result.user?.uid}');
        return result.user;
      } else if (_mockAuthService != null) {
        final user = await MockAuthService.signUpWithEmailAndPassword(
          email: email,
          password: password,
          displayName: displayName,
        );
        _logger.i('Mock email sign up successful: ${user?.uid}');
        return user;
      }
      throw Exception('No auth service available');
    } catch (e) {
      _logger.e('Email sign up failed: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      _logger.i('Signing out...');
      
      if (_isFirebaseEnabled) {
        await _firebaseAuth?.signOut();
        await _googleSignIn?.signOut();
      } else if (_mockAuthService != null) {
        await MockAuthService.signOut();
      }
      
      _logger.i('Sign out successful');
    } catch (e) {
      _logger.e('Sign out failed: $e');
      rethrow;
    }
  }

  void dispose() {
    _firebaseSubscription?.cancel();
    _authStateController.close();
  }
}
