import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/chat/real_chat_page.dart';
import '../features/motivation/simple_motivation_page.dart';
import '../features/profile/simple_profile_page.dart';
import '../routes_simple.dart';
import 'bottom_drawer.dart';

// Provider для текущего индекса навигации
final navigationIndexProvider = StateProvider<int>((ref) => 0);

// Provider для индикатора загрузки
final loadingProvider = StateProvider<bool>((ref) => false);

class MainNavigationPage extends ConsumerStatefulWidget {
  const MainNavigationPage({super.key});

  @override
  ConsumerState<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends ConsumerState<MainNavigationPage> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  final List<Widget> _pages = [
    const SimpleHomePage(),
    const RealChatPage(),
    const SimpleMotivationPage(),
    const SimpleProfilePage(),
    const ApiTestPage(),
  ];


  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(loadingProvider);

    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            children: _pages,
            onPageChanged: (index) {
              ref.read(navigationIndexProvider.notifier).state = index;
            },
          ),
          // Глобальный индикатор загрузки
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Загрузка...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Компонент для показа индикатора загрузки
class LoadingOverlay extends ConsumerWidget {
  final String message;

  const LoadingOverlay({
    super.key,
    this.message = 'Загрузка...',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Card(
          margin: const EdgeInsets.all(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  message,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}