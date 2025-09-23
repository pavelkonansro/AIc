import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AicAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final Color? backgroundColor;
  final bool transparent;

  const AicAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBackButton = true,
    this.onBackPressed,
    this.backgroundColor,
    this.transparent = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: transparent ? Colors.transparent : backgroundColor,
      elevation: transparent ? 0 : null,
      title: Text(title),
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: onBackPressed ?? () => _handleBack(context),
            )
          : null,
      actions: [
        ...?actions,
        // Основная навигация
        IconButton(
          icon: const Icon(Icons.home_rounded),
          onPressed: () => context.go('/home'),
          tooltip: 'Главная',
        ),
        IconButton(
          icon: const Icon(Icons.chat_rounded),
          onPressed: () => context.go('/chat'),
          tooltip: 'Чат',
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded),
          tooltip: 'Меню',
          onSelected: (value) => _handleMenuAction(context, value),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'profile',
              child: ListTile(
                leading: Icon(Icons.person_rounded),
                title: Text('Профиль'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'motivation',
              child: ListTile(
                leading: Icon(Icons.favorite_rounded),
                title: Text('Мотивация'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'meditation',
              child: ListTile(
                leading: Icon(Icons.spa_rounded),
                title: Text('Медитация'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'tips',
              child: ListTile(
                leading: Icon(Icons.lightbulb_rounded),
                title: Text('Советы'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'situations',
              child: ListTile(
                leading: Icon(Icons.psychology_rounded),
                title: Text('Ситуации'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'support',
              child: ListTile(
                leading: Icon(Icons.support_agent_rounded),
                title: Text('Поддержка'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'sos',
              child: ListTile(
                leading: Icon(Icons.emergency_rounded),
                title: Text('SOS'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'settings',
              child: ListTile(
                leading: Icon(Icons.settings_rounded),
                title: Text('Настройки'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'logout',
              child: ListTile(
                leading: Icon(Icons.logout_rounded),
                title: Text('Выйти'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _handleBack(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      context.go('/home');
    }
  }

  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'profile':
        context.go('/profile');
        break;
      case 'motivation':
        context.go('/motivation');
        break;
      case 'meditation':
        context.go('/meditation');
        break;
      case 'tips':
        context.go('/tips');
        break;
      case 'situations':
        context.go('/situations');
        break;
      case 'support':
        context.go('/support');
        break;
      case 'sos':
        context.go('/sos');
        break;
      case 'settings':
        context.go('/settings');
        break;
      case 'logout':
        // TODO: Implement logout logic
        _showLogoutDialog(context);
        break;
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выйти'),
        content: const Text('Вы уверены, что хотите выйти из приложения?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/');
            },
            child: const Text('Выйти'),
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}