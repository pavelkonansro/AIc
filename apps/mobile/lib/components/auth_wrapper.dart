import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../state/auth_provider.dart';
import '../features/auth/simple_auth_page.dart';

class AuthWrapper extends ConsumerWidget {
  final Widget child;

  const AuthWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final authService = ref.watch(authServiceProvider);

    return authState.when(
      data: (user) {
        // Отладочная информация
        print('🔍 AuthWrapper: user = ${user?.uid ?? 'null'}, isAnonymous = ${user?.isAnonymous ?? 'N/A'}');
        print('🔍 AuthWrapper: authService.currentUser = ${authService.currentUser?.uid ?? 'null'}');
        
        // ВРЕМЕННО: Всегда показываем основное приложение для тестирования навигации
        // TODO: Восстановить проверку аутентификации когда Firebase будет настроен
        if (true) {  // Временно всегда true
          print('🧪 AuthWrapper: Showing main app (testing mode - bypassing auth)');
          return child;
        }
        
        // Если пользователь авторизован (включая анонимных), показываем основное приложение
        if (user != null || authService.currentUser != null) {
          final displayUser = user ?? authService.currentUser;
          print('✅ AuthWrapper: Showing main app for user ${displayUser?.uid}');
          return child;
        }
        // Если не авторизован, показываем экран входа
        print('❌ AuthWrapper: No user, showing auth page');
        return const SimpleAuthPage();
      },
      loading: () => const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Загрузка...'),
            ],
          ),
        ),
      ),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'Ошибка инициализации',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // Перезапуск приложения или попытка повторной инициализации
                  ref.invalidate(authStateProvider);
                },
                child: const Text('Попробовать снова'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}