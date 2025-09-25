import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';

class AuthDebugPage extends ConsumerStatefulWidget {
  const AuthDebugPage({Key? key}) : super(key: key);

  @override
  ConsumerState<AuthDebugPage> createState() => _AuthDebugPageState();
}

class _AuthDebugPageState extends ConsumerState<AuthDebugPage> {
  final AuthService _authService = AuthService();
  String _debugInfo = 'Инициализация...';
  String? _currentUser;

  @override
  void initState() {
    super.initState();
    _initializeAndTest();
  }

  Future<void> _initializeAndTest() async {
    try {
      await _authService.initialize();
      
      // Проверяем, какой сервис используется
      final debugInfo = await _getAuthServiceInfo();
      
      setState(() {
        _debugInfo = debugInfo;
        _currentUser = _authService.currentUser?.uid;
      });
    } catch (e) {
      setState(() {
        _debugInfo = 'Ошибка инициализации: $e';
      });
    }
  }

  Future<String> _getAuthServiceInfo() async {
    final buffer = StringBuffer();
    
    // Основная информация
    buffer.writeln('=== AUTH SERVICE DEBUG ===');
    buffer.writeln('Текущий пользователь: ${_authService.currentUser?.uid ?? 'Нет'}');
    buffer.writeln('Аутентифицирован: ${_authService.isAuthenticated}');
    
    // Пытаемся понять, какой сервис используется
    try {
      final user = await _authService.signInAnonymously();
      
      if (user?.uid == 'anonymous_user_123') {
        buffer.writeln('🔴 ИСПОЛЬЗУЕТСЯ: MockAuthService');
        buffer.writeln('Причина: Firebase недоступен или не настроен');
      } else if (user?.uid?.startsWith('firebase') == true || user?.uid?.length == 28) {
        buffer.writeln('🟢 ИСПОЛЬЗУЕТСЯ: Firebase Auth');
        buffer.writeln('Firebase UID: ${user?.uid}');
      } else {
        buffer.writeln('🟡 НЕИЗВЕСТНЫЙ СЕРВИС');
        buffer.writeln('UID: ${user?.uid}');
      }
      
      // Информация о платформе
      buffer.writeln('\n=== ПЛАТФОРМА ===');
      buffer.writeln('Web: ${Theme.of(context).platform == TargetPlatform.fuchsia}');
      buffer.writeln('iOS: ${Theme.of(context).platform == TargetPlatform.iOS}');
      buffer.writeln('Android: ${Theme.of(context).platform == TargetPlatform.android}');
      
    } catch (e) {
      buffer.writeln('🔴 ОШИБКА АУТЕНТИФИКАЦИИ: $e');
    }
    
    return buffer.toString();
  }

  Future<void> _testSignOut() async {
    try {
      await _authService.signOut();
      setState(() {
        _currentUser = null;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выход выполнен')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка выхода: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auth Service Debug'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Информация об Auth Service:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _debugInfo,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _initializeAndTest,
                  child: const Text('Обновить информацию'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _currentUser != null ? _testSignOut : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Выйти'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Объяснение:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '🟢 Firebase Auth - работает настоящая аутентификация\n'
              '🔴 MockAuthService - используется заглушка для разработки\n'
              '🟡 Неизвестно - требует дополнительной диагностики',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}