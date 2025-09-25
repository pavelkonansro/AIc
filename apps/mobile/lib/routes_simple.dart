import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'services/api_client_simple.dart';
import 'state/server_config_provider.dart';
import 'features/chat/simple_chat_page.dart';
import 'features/chat/openrouter_chat_page.dart';
import 'features/motivation/simple_motivation_page.dart';
import 'features/profile/simple_profile_page.dart';
import 'features/auth/registration_page.dart';
import 'components/auth_wrapper.dart';
import 'components/global_navigation_wrapper.dart';
import 'services/block_renderer.dart';
import 'screens/dynamic_screen.dart';
import 'debug/auth_debug_page.dart';
import 'debug/network_diagnostics_page.dart';
import 'debug/server_switcher_page.dart';

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

    // Используем динамический контент из JSON
    final screenDataAsync = ref.watch(screenDataProvider('home'));

    return screenDataAsync.when(
      data: (screenData) => _buildDynamicScreen(context, screenData),
      loading: () => Scaffold(
        appBar: AppBar(
          title: const Text('AIc Home'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => _buildFallbackScreen(context),
    );
  }

  Widget _buildDynamicScreen(BuildContext context, Map<String, dynamic> screenData) {
    final blocks = screenData['blocks'] as List<dynamic>;
    final title = screenData['title'] as String? ?? 'AIc Home';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: CustomScrollView(
        slivers: [
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final blockData = blocks[index] as Map<String, dynamic>;
                return BlockRenderer(blockData: blockData);
              },
              childCount: blocks.length,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackScreen(BuildContext context) {
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
                ElevatedButton(
                  onPressed: () => context.go('/debug/auth'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('🐛 Auth Debug'),
                ),
                ElevatedButton(
                  onPressed: () => context.go('/debug/network'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('🌐 Network Test'),
                ),
                ElevatedButton(
                  onPressed: () => context.go('/debug/servers'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('🔄 Servers'),
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
    final apiConfig = ref.watch(currentApiConfigProvider);
    final currentServer = ref.watch(serverConfigProvider);

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
            // Информация о сервере
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🌐 Текущий сервер: ${apiConfig['name']}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'URL: ${apiConfig['baseUrl']}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    apiConfig['description']!,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
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
      builder: (_, __) => const AuthWrapper(
        child: GlobalNavigationWrapper(
          child: SimpleHomePage(),
        ),
      ),
    ),
    GoRoute(
      path: '/home',
      builder: (_, __) => const AuthWrapper(
        child: GlobalNavigationWrapper(
          child: SimpleHomePage(),
        ),
      ),
    ),
    GoRoute(
      path: '/chat',
      builder: (_, __) => const AuthWrapper(
        child: GlobalNavigationWrapper(
          showNavigation: false,
          child: OpenRouterChatPage(),
        ),
      ),
    ),
    GoRoute(
      path: '/profile',
      builder: (_, __) => const AuthWrapper(
        child: GlobalNavigationWrapper(
          child: SimpleProfilePage(),
        ),
      ),
    ),
    GoRoute(
      path: '/settings',
      builder: (_, __) => const AuthWrapper(
        child: GlobalNavigationWrapper(
          child: DynamicScreen(screenName: 'settings'),
        ),
      ),
    ),
    GoRoute(
      path: '/support',
      builder: (_, __) => const AuthWrapper(
        child: GlobalNavigationWrapper(
          child: DynamicScreen(screenName: 'support'),
        ),
      ),
    ),
    GoRoute(
      path: '/meditation',
      builder: (_, __) => const AuthWrapper(
        child: GlobalNavigationWrapper(
          child: DynamicScreen(screenName: 'meditation'),
        ),
      ),
    ),
    GoRoute(
      path: '/tips',
      builder: (_, __) => const AuthWrapper(
        child: GlobalNavigationWrapper(
          child: DynamicScreen(screenName: 'tips'),
        ),
      ),
    ),
    GoRoute(
      path: '/motivation',
      builder: (_, __) => const AuthWrapper(
        child: GlobalNavigationWrapper(
          child: SimpleMotivationPage(),
        ),
      ),
    ),
    GoRoute(
      path: '/api-test',
      builder: (_, __) => const AuthWrapper(
        child: GlobalNavigationWrapper(
          child: ApiTestPage(),
        ),
      ),
    ),
    GoRoute(
      path: '/situations',
      builder: (_, __) => const AuthWrapper(
        child: GlobalNavigationWrapper(
          child: DynamicScreen(screenName: 'situations'),
        ),
      ),
    ),
    GoRoute(
      path: '/register',
      builder: (_, __) => const RegistrationPage(),
    ),
    GoRoute(
      path: '/debug/auth',
      builder: (_, __) => const AuthDebugPage(),
    ),
    GoRoute(
      path: '/debug/network',
      builder: (_, __) => const NetworkDiagnosticsPage(),
    ),
    GoRoute(
      path: '/debug/servers',
      builder: (_, __) => const ServerSwitcherPage(),
    ),
    GoRoute(
      path: '/debug/environment',
      builder: (_, __) => const SimplePage(title: 'Environment Settings (Coming Soon)'),
    ),
  ],
);