import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _nickController = TextEditingController();
  String _selectedAge = '13-15';
  String _selectedCountry = 'CZ';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              const Text(
                'Твой дружелюбный AI-компаньон',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
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
                onChanged: (value) => setState(() => _selectedCountry = value!),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  if (_nickController.text.trim().isNotEmpty) {
                    // TODO: Сохранить данные пользователя
                    context.go('/chat');
                  }
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('Начать общение'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



