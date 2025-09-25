import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';

// Провайдер для AuthService (singleton)
final authServiceProvider = Provider<AuthService>((ref) {
  // Используем singleton instance
  final authService = AuthService();
  // Инициализируем сервис асинхронно
  authService.initialize();
  return authService;
});

// Провайдер для потока состояния аутентификации
final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  print('🔍 authStateProvider: Creating stream for authService');
  return authService.authStateChanges;
});

// Провайдер текущего пользователя
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) => user,
    loading: () => null,
    error: (error, stack) => null,
  );
});

// Провайдер проверки аутентификации
final isAuthenticatedProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user != null;
});

// Провайдер проверки анонимного пользователя
final isAnonymousProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.isAnonymous ?? false;
});

// Контроллер аутентификации
class AuthController extends StateNotifier<AsyncValue<void>> {
  AuthController(this._authService) : super(const AsyncValue.data(null));

  final AuthService _authService;

  // Анонимная аутентификация
  Future<User?> signInAnonymously() async {
    try {
      final user = await _authService.signInAnonymously();
      return user;
    } catch (error) {
      rethrow;
    }
  }

  // Вход через Google
  Future<User?> signInWithGoogle() async {
    try {
      final user = await _authService.signInWithGoogle();
      return user;
    } catch (error) {
      rethrow;
    }
  }

  // Регистрация с email и паролем
  Future<User?> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final user = await _authService.signUpWithEmailAndPassword(
        email: email,
        password: password,
        displayName: displayName,
      );
      return user;
    } catch (error) {
      rethrow;
    }
  }

  // Выход
  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      await _authService.signOut();
      state = const AsyncValue.data(null);
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
    }
  }
}

// Провайдер контроллера аутентификации
final authControllerProvider = StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthController(authService);
});