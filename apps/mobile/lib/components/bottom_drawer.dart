import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NavigationItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
  final Color color;

  NavigationItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
    required this.color,
  });
}

class BottomDrawer extends StatelessWidget {
  const BottomDrawer({super.key});

  static final List<NavigationItem> _navigationItems = [
    NavigationItem(
      title: 'Главная',
      subtitle: 'Добро пожаловать в AIc',
      icon: Icons.home_rounded,
      route: '/',
      color: Colors.blue,
    ),
    NavigationItem(
      title: 'Чат с AI',
      subtitle: 'Поговори с Grok-4',
      icon: Icons.smart_toy_rounded,
      route: '/chat',
      color: Colors.green,
    ),
    NavigationItem(
      title: 'Мотивация',
      subtitle: 'Вдохновение и поддержка',
      icon: Icons.favorite_rounded,
      route: '/motivation',
      color: Colors.pink,
    ),
    NavigationItem(
      title: 'Медитация',
      subtitle: 'Практики осознанности',
      icon: Icons.self_improvement_rounded,
      route: '/meditation',
      color: Colors.purple,
    ),
    NavigationItem(
      title: 'Советы',
      subtitle: 'Полезные рекомендации',
      icon: Icons.lightbulb_rounded,
      route: '/tips',
      color: Colors.orange,
    ),
    NavigationItem(
      title: 'Профиль',
      subtitle: 'Настройки аккаунта',
      icon: Icons.person_rounded,
      route: '/profile',
      color: Colors.indigo,
    ),
    NavigationItem(
      title: 'Поддержка',
      subtitle: 'Помощь и консультации',
      icon: Icons.support_agent_rounded,
      route: '/support',
      color: Colors.teal,
    ),
    NavigationItem(
      title: 'Настройки',
      subtitle: 'Конфигурация приложения',
      icon: Icons.settings_rounded,
      route: '/settings',
      color: Colors.grey,
    ),
  ];

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const BottomDrawer(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(
                      Icons.explore_rounded,
                      color: Colors.blue,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Навигация AIc',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C2C2C),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.grey[100],
                      ),
                    ),
                  ],
                ),
              ),
              // Navigation items
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _navigationItems.length,
                  itemBuilder: (context, index) {
                    final item = _navigationItems[index];
                    return _buildNavigationTile(context, item);
                  },
                ),
              ),
              // Footer
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  border: Border(
                    top: BorderSide(color: Colors.grey[200]!),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.favorite,
                      color: Colors.red,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'AI компаньон для подростков',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNavigationTile(BuildContext context, NavigationItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.of(context).pop();
            context.go(item.route);
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey[200]!,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: item.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    item.icon,
                    color: item.color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2C2C2C),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.grey[400],
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}