import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';

class SimpleProfilePage extends ConsumerStatefulWidget {
  const SimpleProfilePage({super.key});

  @override
  ConsumerState<SimpleProfilePage> createState() => _SimpleProfilePageState();
}

class _SimpleProfilePageState extends ConsumerState<SimpleProfilePage> {
  String _userName = 'Пользователь';
  String _userMood = 'Хорошее';
  int _dailyStreak = 0;
  bool _isLoading = true;

  final List<String> _moods = [
    'Отлично! 😄',
    'Хорошо 😊',
    'Нормально 😐',
    'Грустно 😢',
    'Устал(а) 😴',
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_name') ?? 'Пользователь';
      _userMood = prefs.getString('user_mood') ?? 'Хорошо 😊';
      _dailyStreak = prefs.getInt('daily_streak') ?? 0;
      _isLoading = false;
    });
  }

  Future<void> _saveName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', name);
    setState(() {
      _userName = name;
    });
  }

  Future<void> _saveMood(String mood) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_mood', mood);
    setState(() {
      _userMood = mood;
    });
  }

  Future<void> _updateStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final newStreak = _dailyStreak + 1;
    await prefs.setInt('daily_streak', newStreak);
    setState(() {
      _dailyStreak = newStreak;
    });
  }

  void _showNameDialog() {
    final controller = TextEditingController(text: _userName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Изменить имя'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Ваше имя',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                _saveName(controller.text);
              }
              Navigator.pop(context);
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  void _showMoodDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Как ваше настроение?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _moods.map((mood) => ListTile(
            title: Text(mood),
            onTap: () {
              _saveMood(mood);
              Navigator.pop(context);
            },
          )).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/');
            }
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Аватар и имя
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.withOpacity(0.1), Colors.white],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.blue,
                    child: Text(
                      _userName.isNotEmpty ? _userName[0].toUpperCase() : 'П',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _userName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Настроение: $_userMood',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Статистика
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.local_fire_department, color: Colors.orange),
                  const SizedBox(width: 8),
                  Text(
                    'Серия дней: $_dailyStreak',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Кнопки действий
            Expanded(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.edit, color: Colors.blue),
                    title: const Text('Изменить имя'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: _showNameDialog,
                    tileColor: Colors.grey.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    leading: const Icon(Icons.mood, color: Colors.green),
                    title: const Text('Изменить настроение'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: _showMoodDialog,
                    tileColor: Colors.grey.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    leading: const Icon(Icons.add, color: Colors.orange),
                    title: const Text('Отметить день'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: _updateStreak,
                    tileColor: Colors.grey.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}