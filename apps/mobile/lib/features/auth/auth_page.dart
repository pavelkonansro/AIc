import 'dart:convert';

import 'package:aic_mobile/services/notifications.dart';
import 'package:aic_mobile/services/logger.dart';
import 'package:aic_mobile/config/api_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../components/navigation/navigation.dart';
import '../../state/server_config_provider.dart';
import '../../state/providers.dart';
import '../../services/chat_session_service.dart';

class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key});

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
  final _nickController = TextEditingController();
  String _selectedAge = '13-15';
  String _selectedCountry = 'CZ';
  bool _isLoading = false;
  bool _isReturningUser = false;

  @override
  void initState() {
    super.initState();
    _checkExistingUser();
  }

  Future<void> _checkExistingUser() async {
    final prefs = await SharedPreferences.getInstance();
    final existingNick = prefs.getString('user_nick');
    final existingAge = prefs.getString('user_age');
    final existingCountry = prefs.getString('user_country');
    final sessionId = prefs.getString('session_id');
    final userId = prefs.getString('user_id');

    if (existingNick != null && sessionId != null) {
      setState(() {
        _isReturningUser = true;
        _nickController.text = existingNick;
        _selectedAge = existingAge ?? '13-15';
        _selectedCountry = existingCountry ?? 'CZ';
      });
    }

    if (userId != null) {
      try {
        await NotificationService.setUserContext(userId);
      } catch (error) {
        debugPrint('Notification service temporarily disabled: $error');
      }
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    setState(() {
      _isReturningUser = false;
      _nickController.clear();
      _selectedAge = '13-15';
      _selectedCountry = 'CZ';
    });
  }

  Future<void> _continueWithExistingUser() async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionId = prefs.getString('session_id');

      if (sessionId != null) {
        if (mounted) {
          context.go('/home');
        }
      } else {
        _createUserAndStartChat();
      }
    } catch (e) {
      AppLogger.e('Ошибка при продолжении с существующим пользователем: $e');
      _createUserAndStartChat();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _createUserAndStartChat() async {
    if (_nickController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пожалуйста, введите свое имя')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      AppLogger.i('Создаем пользователя...');

      // Получаем текущую конфигурацию API
      final apiConfig = ref.read(currentApiConfigProvider);
      final baseUrl = apiConfig['baseUrl']!;
      
      AppLogger.i('Используем сервер: ${apiConfig['name']} - $baseUrl');

      // Создаем пользователя через API
      final response = await http.post(
        Uri.parse('$baseUrl/auth/guest'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nick': _nickController.text.trim(),
          'ageGroup': _selectedAge,
          'locale': _getLocaleFromCountry(_selectedCountry),
        }),
      );

      AppLogger.d('Ответ сервера: ${response.statusCode}');
      AppLogger.d('Тело ответа: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final userId = data['user']['id'];
        final token = data['token'];

        AppLogger.i('Пользователь создан: $userId');

        // Сохраняем данные пользователя
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_id', userId);
        await prefs.setString('user_token', token);
        await prefs.setString('user_nick', _nickController.text.trim());
        await prefs.setString('user_age', _selectedAge);
        await prefs.setString('user_country', _selectedCountry);

        try {
          await NotificationService.setUserContext(userId);
        } catch (error) {
          debugPrint('Notification service temporarily disabled: $error');
        }

        AppLogger.i('Создаем чат сессию...');

        // Создаем чат сессию через адаптивный сервис
        final chatService = ref.read(chatSessionServiceProvider);
        final session = await chatService.createSession(userId);
        
        await prefs.setString('session_id', session.id);
        
        // Сохраняем сессию в провайдере
        ref.read(currentChatSessionProvider.notifier).setSession(session);

        AppLogger.i('Сессия создана: ${session.id} (${chatService.serviceType})');

        // Переходим к чату
        if (mounted) {
          context.go('/home');
        }
      } else {
        throw Exception(
            'Ошибка создания пользователя: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      AppLogger.e('Ошибка: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getLocaleFromCountry(String country) {
    switch (country) {
      case 'CZ':
        return 'cs-CZ';
      case 'DE':
        return 'de-DE';
      case 'US':
        return 'en-US';
      default:
        return 'en-US';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AicScaffold(
      title: 'AIc - Вход',
      showBottomNavigation: false,
      showBackButton: false,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '🐶 Привет! Я AIc',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                _isReturningUser
                    ? 'Рад тебя снова видеть!'
                    : 'Твой дружелюбный AI-компаньон',
                style: const TextStyle(fontSize: 18, color: Colors.grey),
              ),
              if (_isReturningUser) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Добро пожаловать обратно, ${_nickController.text}!',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Возраст: ${_getAgeText(_selectedAge)} • Страна: ${_getCountryText(_selectedCountry)}',
                        style: TextStyle(
                            fontSize: 14, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed:
                            _isLoading ? null : _continueWithExistingUser,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(0, 50),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Продолжить'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : _logout,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 50),
                        ),
                        child: const Text('Сменить пользователя'),
                      ),
                    ),
                  ],
                ),
              ],
              if (!_isReturningUser) ...[
                const SizedBox(height: 48),
                TextField(
                  controller: _nickController,
                  decoration: const InputDecoration(
                    labelText: 'Как тебя зовут?',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                DropdownButtonFormField<String>(
                  initialValue: _selectedAge,
                  decoration: const InputDecoration(
                    labelText: 'Возраст',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: '9-12', child: Text('9-12 лет')),
                    DropdownMenuItem(value: '13-15', child: Text('13-15 лет')),
                    DropdownMenuItem(value: '16-18', child: Text('16-18 лет')),
                  ],
                  onChanged: (value) => setState(() => _selectedAge = value!),
                ),
                const SizedBox(height: 24),
                DropdownButtonFormField<String>(
                  initialValue: _selectedCountry,
                  decoration: const InputDecoration(
                    labelText: 'Страна',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'CZ', child: Text('Чехия')),
                    DropdownMenuItem(value: 'DE', child: Text('Германия')),
                    DropdownMenuItem(value: 'US', child: Text('США')),
                  ],
                  onChanged: (value) =>
                      setState(() => _selectedCountry = value!),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isLoading ? null : _createUserAndStartChat,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Начать общение'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _getAgeText(String age) {
    switch (age) {
      case '9-12':
        return '9-12 лет';
      case '13-15':
        return '13-15 лет';
      case '16-18':
        return '16-18 лет';
      default:
        return age;
    }
  }

  String _getCountryText(String country) {
    switch (country) {
      case 'CZ':
        return 'Чехия';
      case 'DE':
        return 'Германия';
      case 'US':
        return 'США';
      default:
        return country;
    }
  }
}
