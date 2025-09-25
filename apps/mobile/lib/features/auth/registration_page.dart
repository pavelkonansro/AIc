import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../state/auth_provider.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';

class RegistrationPage extends ConsumerStatefulWidget {
  const RegistrationPage({Key? key}) : super(key: key);

  @override
  ConsumerState<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends ConsumerState<RegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _birthDateController = TextEditingController();
  
  DateTime? _selectedBirthDate;
  String? _selectedAgeGroup;
  String _selectedCountry = 'CZ'; // По умолчанию Чехия
  bool _hasParentalConsent = false;
  bool _agreesToTerms = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  final List<String> _countries = ['CZ', 'DE', 'US', 'FR', 'PL'];
  final Map<String, String> _countryNames = {
    'CZ': '🇨🇿 Чехия',
    'DE': '🇩🇪 Германия', 
    'US': '🇺🇸 США',
    'FR': '🇫🇷 Франция',
    'PL': '🇵🇱 Польша',
  };

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  // Определение возрастной группы на основе даты рождения
  String _calculateAgeGroup(DateTime birthDate) {
    final age = DateTime.now().difference(birthDate).inDays ~/ 365;
    if (age >= 9 && age <= 12) return '9-12';
    if (age >= 13 && age <= 15) return '13-15';
    if (age >= 16 && age <= 18) return '16-18';
    return '18+';
  }

  // Проверка необходимости родительского согласия
  bool _requiresParentalConsent() {
    if (_selectedBirthDate == null) return false;
    final age = DateTime.now().difference(_selectedBirthDate!).inDays ~/ 365;
    
    // Разные требования по странам
    switch (_selectedCountry) {
      case 'DE':
        return age < 16;
      case 'CZ':
        return age < 15;
      default:
        return age < 13; // COPPA для других стран
    }
  }

  Future<void> _selectBirthDate() async {
    try {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: DateTime(2010, 1, 1), // Для подростков
        firstDate: DateTime(1990, 1, 1),
        lastDate: DateTime.now(),
        // Убираем locale для избежания проблем с локализацией
        // locale: const Locale('ru', 'RU'),
      );
      
      if (picked != null && picked != _selectedBirthDate) {
        setState(() {
          _selectedBirthDate = picked;
          _selectedAgeGroup = _calculateAgeGroup(picked);
          _birthDateController.text = 
            "${picked.day.toString().padLeft(2, '0')}.${picked.month.toString().padLeft(2, '0')}.${picked.year}";
        });
      }
    } catch (e) {
      debugPrint('❌ Error selecting birth date: $e');
      // Показываем пользователю сообщение об ошибке
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка выбора даты: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleRegistration() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_requiresParentalConsent() && !_hasParentalConsent) {
      _showMessage('Требуется согласие родителей для регистрации', isError: true);
      return;
    }
    
    if (!_agreesToTerms) {
      _showMessage('Необходимо согласиться с условиями использования', isError: true);
      return;
    }

    try {
      // 1. Регистрация через Firebase
      final authController = ref.read(authControllerProvider.notifier);
      final user = await authController.signUp(
        email: _emailController.text,
        password: _passwordController.text,
        displayName: _nameController.text,
      );

      if (user == null) {
        _showMessage('Ошибка регистрации через Firebase', isError: true);
        return;
      }

      // 2. Создание профиля через API
      final apiService = ApiService();
      await apiService.createUserProfile(
        userId: user.uid,
        email: _emailController.text,
        name: _nameController.text,
        ageGroup: _selectedAgeGroup!,
        country: _selectedCountry,
        consentFlags: {
          'hasParentalConsent': _hasParentalConsent,
          'agreesToTerms': _agreesToTerms,
          'country': _selectedCountry,
          'registrationDate': DateTime.now().toIso8601String(),
        },
      );

      if (mounted) {
        _showMessage('Регистрация успешна! Добро пожаловать в AIc!');
        context.go('/home');
      }
    } catch (e) {
      _showMessage('Ошибка регистрации: $e', isError: true);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : Colors.green,
          duration: Duration(seconds: isError ? 5 : 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Создать аккаунт',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Заголовок
                const Text(
                  'Присоединяйся к AIc!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Создай аккаунт для персонализированного опыта',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 40),

                // Имя
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Имя',
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Введите имя';
                    }
                    if (value.length < 2) {
                      return 'Имя должно содержать минимум 2 символа';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Введите email';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'Введите корректный email';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Пароль
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Пароль',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Введите пароль';
                    }
                    if (value.length < 6) {
                      return 'Пароль должен содержать минимум 6 символов';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Подтверждение пароля
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Подтвердите пароль',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Подтвердите пароль';
                    }
                    if (value != _passwordController.text) {
                      return 'Пароли не совпадают';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Дата рождения
                TextFormField(
                  controller: _birthDateController,
                  readOnly: true,
                  onTap: _selectBirthDate,
                  decoration: InputDecoration(
                    labelText: 'Дата рождения',
                    prefixIcon: const Icon(Icons.cake),
                    suffixIcon: const Icon(Icons.calendar_today),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Выберите дату рождения';
                    }
                    return null;
                  },
                ),

                if (_selectedAgeGroup != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Возрастная группа: $_selectedAgeGroup',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Страна
                DropdownButtonFormField<String>(
                  value: _selectedCountry,
                  decoration: InputDecoration(
                    labelText: 'Страна',
                    prefixIcon: const Icon(Icons.flag),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: _countries.map((country) {
                    return DropdownMenuItem(
                      value: country,
                      child: Text(_countryNames[country]!),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCountry = value!;
                    });
                  },
                ),

                const SizedBox(height: 24),

                // Родительское согласие (если необходимо)
                if (_requiresParentalConsent()) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.family_restroom, color: Colors.orange[700]),
                            const SizedBox(width: 8),
                            Text(
                              'Родительское согласие',
                              style: TextStyle(
                                color: Colors.orange[700],
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Поскольку тебе меньше ${_selectedCountry == 'DE' ? '16' : _selectedCountry == 'CZ' ? '15' : '13'} лет, необходимо согласие родителей для использования AIc.',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Checkbox(
                              value: _hasParentalConsent,
                              onChanged: (value) {
                                setState(() {
                                  _hasParentalConsent = value!;
                                });
                              },
                            ),
                            Expanded(
                              child: Text(
                                'Родители дали согласие на создание аккаунта',
                                style: TextStyle(color: Colors.grey[700]),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Согласие с условиями
                Row(
                  children: [
                    Checkbox(
                      value: _agreesToTerms,
                      onChanged: (value) {
                        setState(() {
                          _agreesToTerms = value!;
                        });
                      },
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _agreesToTerms = !_agreesToTerms;
                          });
                        },
                        child: Text.rich(
                          TextSpan(
                            text: 'Я соглашаюсь с ',
                            style: TextStyle(color: Colors.grey[600]),
                            children: [
                              TextSpan(
                                text: 'условиями использования',
                                style: TextStyle(
                                  color: Colors.blue[600],
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                              TextSpan(
                                text: ' и ',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              TextSpan(
                                text: 'политикой конфиденциальности',
                                style: TextStyle(
                                  color: Colors.blue[600],
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Кнопка регистрации
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: authState.isLoading ? null : _handleRegistration,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: authState.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Создать аккаунт',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 16),

                // Ссылка на вход
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Уже есть аккаунт? ',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Text(
                        'Войти',
                        style: TextStyle(
                          color: Colors.blue[600],
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}