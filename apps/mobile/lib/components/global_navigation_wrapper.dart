import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'bottom_drawer.dart';

class GlobalNavigationWrapper extends StatelessWidget {
  final Widget child;
  final bool showNavigation;

  const GlobalNavigationWrapper({
    super.key,
    required this.child,
    this.showNavigation = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!showNavigation) {
      return child;
    }

    return Stack(
      children: [
        child,
        Positioned(
          bottom: 20,
          left: 0,
          right: 0,
          child: Center(
            child: FloatingActionButton.extended(
              onPressed: () => BottomDrawer.show(context),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              elevation: 8,
              icon: const Icon(Icons.explore_rounded, size: 28),
              label: const Text(
                'Меню',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}