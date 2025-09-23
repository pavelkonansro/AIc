import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../components/navigation/navigation.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return AicMainScaffold(
      title: 'Профиль',
      currentRoute: '/profile',
      appBarActions: [
        IconButton(
          icon: const Icon(Icons.settings_rounded),
          onPressed: () => context.go('/settings'),
          tooltip: 'Настройки',
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const CircleAvatar(
            radius: 50,
            child: Text('🐶', style: TextStyle(fontSize: 40)),
          ),
          const SizedBox(height: 16),
          const Text(
            'Пользователь',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Возраст: 13-15 лет',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 32),
          Card(
            child: ListTile(
              leading: const Icon(Icons.chat),
              title: const Text('Чат с AIc'),
              onTap: () => context.go('/chat'),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.emergency, color: Colors.red),
              title: const Text('SOS Помощь'),
              onTap: () => context.go('/sos'),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.star),
              title: const Text('Премиум подписка'),
              subtitle: const Text('Получи больше возможностей'),
              onTap: () {
                // TODO: Открыть экран подписки
              },
            ),
          ),
          const SizedBox(height: 32),
          OutlinedButton(
            onPressed: () {
              context.go('/');
            },
            child: const Text('Выйти'),
          ),
        ],
      ),
    );
  }
}
