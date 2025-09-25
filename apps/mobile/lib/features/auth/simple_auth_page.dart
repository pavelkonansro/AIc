import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../state/auth_provider.dart';
import '../../services/mock_auth_service.dart';

class SimpleAuthPage extends ConsumerStatefulWidget {
  const SimpleAuthPage({super.key});

  @override
  ConsumerState<SimpleAuthPage> createState() => _SimpleAuthPageState();
}

class _SimpleAuthPageState extends ConsumerState<SimpleAuthPage> {
  bool _isSignUp = false;
  bool _isGuestLoading = false;
  bool _isGoogleLoading = false;

  Future<void> _handleGuestMode() async {
    if (_isGuestLoading) return;
    
    setState(() {
      _isGuestLoading = true;
    });
    
    try {
      print('🔐 Starting guest mode authentication...');
      final authController = ref.read(authControllerProvider.notifier);
      final user = await authController.signInAnonymously();

      print('🔐 Guest authentication result: ${user?.uid}');
      
      // Проверяем как мок-сервис, так и реальный Firebase Auth
      final currentUser = FirebaseAuth.instance.currentUser;
      final mockUser = MockAuthService.currentUser;
      
      if (user != null || currentUser != null || mockUser != null) {
        print('✅ Guest authentication successful, navigating to chat');
        if (mounted) context.go('/chat');
      } else {
        print('❌ Guest authentication failed - no user returned');
        _showMessage('Не удалось войти как гость', isError: true);
      }
    } catch (e, stackTrace) {
      print('❌ Guest authentication error: $e');
      print('Stack trace: $stackTrace');
      _showMessage('Ошибка: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isGuestLoading = false;
        });
      }
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : Colors.green,
        ),
      );
    }
  }

  Future<void> _handleGoogleSignIn() async {
    if (_isGoogleLoading) return;
    
    setState(() {
      _isGoogleLoading = true;
    });
    
    try {
      print('🔐 Starting Google Sign-In...');
      final authController = ref.read(authControllerProvider.notifier);
      final user = await authController.signInWithGoogle();

      print('🔐 Google Sign-In result: ${user?.uid}');
      
      // Проверяем как мок-сервис, так и реальный Firebase Auth
      final currentUser = FirebaseAuth.instance.currentUser;
      final mockUser = MockAuthService.currentUser;
      
      if (user != null || currentUser != null || mockUser != null) {
        print('✅ Google Sign-In successful, navigating to chat');
        if (mounted) context.go('/chat');
      } else {
        print('❌ Google Sign-In failed - no user returned');
        _showMessage('Не удалось войти через Google', isError: true);
      }
    } catch (e, stackTrace) {
      print('❌ Google Sign-In error: $e');
      print('Stack trace: $stackTrace');
      _showMessage('Ошибка Google Sign-In: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isGoogleLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40), // Отступ сверху
                // Логотип и заголовок
                Column(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.pets,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'AIc',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'AI-компаньон для подростков',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 60),

                // Описание
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Column(
                    children: [
                      Text(
                        '🤖 Поддержка 24/7',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '💬 Умные разговоры',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '🔒 Полная конфиденциальность',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Кнопка гостевого режима
                // Кнопка "Начать общение"
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isGuestLoading ? null : _handleGuestMode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isGuestLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.rocket_launch),
                              SizedBox(width: 12),
                              Text(
                                'Начать общение',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 16),

                // Кнопка регистрации
                SizedBox(
                  height: 56,
                  child: OutlinedButton(
                    onPressed: () {
                      context.push('/register');
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey[300]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Создать аккаунт',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Кнопка Google Sign-In
                SizedBox(
                  height: 56,
                  child: OutlinedButton(
                    onPressed: _isGoogleLoading ? null : _handleGoogleSignIn,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.red[300]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isGoogleLoading
                        ? const CircularProgressIndicator()
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.g_mobiledata, color: Colors.red[600], size: 24),
                              const SizedBox(width: 12),
                              Text(
                                'Войти через Google',
                                style: TextStyle(
                                  color: Colors.red[600],
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 40),

                // Информация о гостевом режиме
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange[700]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'В гостевом режиме ты можешь попробовать все функции AIc',
                          style: TextStyle(
                            color: Colors.orange[700],
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Политика конфиденциальности
                Text(
                  'Используя приложение, ты соглашаешься с политикой конфиденциальности',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
                
                const SizedBox(height: 40), // Отступ снизу
              ],
            ),
          ),
        ),
      ),
    );
  }
}