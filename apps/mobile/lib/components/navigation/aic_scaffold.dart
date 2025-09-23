import 'package:flutter/material.dart';
import 'aic_app_bar.dart';
import 'aic_bottom_navigation.dart';

class AicScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? appBarActions;
  final bool showBottomNavigation;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final Color? appBarBackgroundColor;
  final bool transparentAppBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final String? currentRoute;

  const AicScaffold({
    super.key,
    required this.title,
    required this.body,
    this.appBarActions,
    this.showBottomNavigation = true,
    this.showBackButton = true,
    this.onBackPressed,
    this.appBarBackgroundColor,
    this.transparentAppBar = false,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.currentRoute,
  });

  @override
  Widget build(BuildContext context) {
    // Определяем текущий маршрут из GoRouter если не передан
    final route = currentRoute ?? ModalRoute.of(context)?.settings.name ?? '/home';

    return Scaffold(
      extendBodyBehindAppBar: transparentAppBar,
      appBar: AicAppBar(
        title: title,
        actions: appBarActions,
        showBackButton: showBackButton,
        onBackPressed: onBackPressed,
        backgroundColor: appBarBackgroundColor,
        transparent: transparentAppBar,
      ),
      body: body,
      bottomNavigationBar: showBottomNavigation
          ? AicBottomNavigation(currentRoute: route)
          : null,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
    );
  }
}

// Специализированные варианты для разных случаев

/// Scaffold для главных страниц с полной навигацией
class AicMainScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? appBarActions;
  final String? currentRoute;

  const AicMainScaffold({
    super.key,
    required this.title,
    required this.body,
    this.appBarActions,
    this.currentRoute,
  });

  @override
  Widget build(BuildContext context) {
    return AicScaffold(
      title: title,
      body: body,
      appBarActions: appBarActions,
      showBottomNavigation: true,
      showBackButton: false,
      currentRoute: currentRoute,
    );
  }
}

/// Scaffold для детальных страниц с кнопкой назад
class AicDetailScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? appBarActions;
  final VoidCallback? onBackPressed;
  final Color? appBarBackgroundColor;
  final bool transparentAppBar;

  const AicDetailScaffold({
    super.key,
    required this.title,
    required this.body,
    this.appBarActions,
    this.onBackPressed,
    this.appBarBackgroundColor,
    this.transparentAppBar = false,
  });

  @override
  Widget build(BuildContext context) {
    return AicScaffold(
      title: title,
      body: body,
      appBarActions: appBarActions,
      showBottomNavigation: false,
      showBackButton: true,
      onBackPressed: onBackPressed,
      appBarBackgroundColor: appBarBackgroundColor,
      transparentAppBar: transparentAppBar,
    );
  }
}

/// Scaffold для чата с прозрачным AppBar
class AicChatScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? appBarActions;
  final String? currentRoute;

  const AicChatScaffold({
    super.key,
    required this.title,
    required this.body,
    this.appBarActions,
    this.currentRoute,
  });

  @override
  Widget build(BuildContext context) {
    return AicScaffold(
      title: title,
      body: body,
      appBarActions: appBarActions,
      showBottomNavigation: false,
      showBackButton: true,
      transparentAppBar: true,
      currentRoute: currentRoute,
    );
  }
}