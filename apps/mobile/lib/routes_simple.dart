import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'services/api_client_simple.dart';
import 'features/chat/simple_chat_page.dart';
import 'features/motivation/simple_motivation_page.dart';
import 'features/profile/simple_profile_page.dart';

// Простые страницы для начального тестирования
class SimplePage extends StatelessWidget {
  final String title;

  const SimplePage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle,
              size: 60,
              color: Colors.blue,
            ),
            SizedBox(height: 20),
            Text(
              '$title Page',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: Text('Go Home'),
            ),
          ],
        ),
      ),
    );
  }
}

class SimpleHomePage extends ConsumerStatefulWidget {
  const SimpleHomePage({super.key});

  @override
  ConsumerState<SimpleHomePage> createState() => _SimpleHomePageState();
}

class _SimpleHomePageState extends ConsumerState<SimpleHomePage> {
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Симулируем инициализацию приложения
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() {
        _isInitializing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.blue.withOpacity(0.1), Colors.white],
            ),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.favorite,
                  size: 80,
                  color: Colors.blue,
                ),
                SizedBox(height: 20),
                Text(
                  'AIc',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'AI companion for teens',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 40),
                CircularProgressIndicator(),
                SizedBox(height: 20),
                Text(
                  'Загрузка...',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('AIc Home'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.home,
              size: 80,
              color: Colors.blue,
            ),
            SizedBox(height: 20),
            Text(
              'AIc App',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'AI companion for teens',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 40),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ElevatedButton(
                  onPressed: () => context.go('/chat'),
                  child: Text('Chat'),
                ),
                ElevatedButton(
                  onPressed: () => context.go('/profile'),
                  child: Text('Profile'),
                ),
                ElevatedButton(
                  onPressed: () => context.go('/settings'),
                  child: Text('Settings'),
                ),
                ElevatedButton(
                  onPressed: () => context.go('/support'),
                  child: Text('Support'),
                ),
                ElevatedButton(
                  onPressed: () => context.go('/motivation'),
                  child: Text('Мотивация'),
                ),
                ElevatedButton(
                  onPressed: () => context.go('/api-test'),
                  child: Text('API Test'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ApiTestPage extends ConsumerStatefulWidget {
  const ApiTestPage({super.key});

  @override
  ConsumerState<ApiTestPage> createState() => _ApiTestPageState();
}

class _ApiTestPageState extends ConsumerState<ApiTestPage> {
  String _status = 'Ready to test API connection';
  bool _isLoading = false;

  Future<void> _testConnection() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing API connection...';
    });

    final apiClient = ref.read(apiClientProvider);
    final result = await apiClient.checkConnection();

    setState(() {
      _isLoading = false;
      _status = result != null
        ? 'API Connected! ✅\n${result.toString()}'
        : 'API Connection Failed ❌';
    });
  }

  Future<void> _testGuestUser() async {
    setState(() {
      _isLoading = true;
      _status = 'Creating guest user...';
    });

    final apiClient = ref.read(apiClientProvider);
    final result = await apiClient.createGuestUser();

    setState(() {
      _isLoading = false;
      _status = result != null
        ? 'Guest User Created! ✅\n${result.toString()}'
        : 'Guest User Creation Failed ❌';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API Test'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _status,
                style: const TextStyle(fontSize: 14),
                maxLines: 10,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _testConnection,
              child: _isLoading
                ? const CircularProgressIndicator()
                : const Text('Test API Connection'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _isLoading ? null : _testGuestUser,
              child: const Text('Create Guest User'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    );
  }
}

final simpleRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (_, __) => const SimpleHomePage(),
    ),
    GoRoute(
      path: '/chat',
      builder: (_, __) => const SimpleChatPage(),
    ),
    GoRoute(
      path: '/profile',
      builder: (_, __) => const SimpleProfilePage(),
    ),
    GoRoute(
      path: '/settings',
      builder: (_, __) => const SimplePage(title: 'Settings'),
    ),
    GoRoute(
      path: '/support',
      builder: (_, __) => const SimplePage(title: 'Support'),
    ),
    GoRoute(
      path: '/motivation',
      builder: (_, __) => const SimpleMotivationPage(),
    ),
    GoRoute(
      path: '/api-test',
      builder: (_, __) => const ApiTestPage(),
    ),
  ],
);