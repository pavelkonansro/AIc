# 🆕 Предложения по новым компонентным тестам

## 🎯 Недостающие тесты для новых компонентов:

1. **GlobalNavigationWrapper** - пока не тестируется
2. **BottomDrawer** - нет отдельных unit тестов
3. **Взаимодействие между компонентами** - не покрыто

## ✅ Предлагаемые новые тест-файлы:

### 1. test/components/global_navigation_wrapper_test.dart

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aic_mobile/components/global_navigation_wrapper.dart';

void main() {
  group('GlobalNavigationWrapper Tests', () {
    testWidgets('should show child widget', (tester) async {
      const testChild = Text('Test Child Widget');
      
      await tester.pumpWidget(
        MaterialApp(
          home: GlobalNavigationWrapper(
            child: testChild,
          ),
        ),
      );
      
      expect(find.text('Test Child Widget'), findsOneWidget);
    });

    testWidgets('should show floating menu button by default', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: GlobalNavigationWrapper(
            child: Container(),
          ),
        ),
      );
      
      expect(find.text('Меню'), findsOneWidget);
      expect(find.byIcon(Icons.explore_rounded), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('should hide navigation when showNavigation is false', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: GlobalNavigationWrapper(
            showNavigation: false,
            child: Text('Test'),
          ),
        ),
      );
      
      expect(find.text('Меню'), findsNothing);
      expect(find.byType(FloatingActionButton), findsNothing);
      expect(find.text('Test'), findsOneWidget);
    });

    testWidgets('should open bottom drawer when menu button tapped', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: GlobalNavigationWrapper(
            child: Container(),
          ),
        ),
      );
      
      // Нажать на кнопку меню
      await tester.tap(find.text('Меню'));
      await tester.pumpAndSettle();
      
      // Проверить что drawer открылся
      expect(find.text('Навигация AIc'), findsOneWidget);
    });

    testWidgets('should have correct button styling', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: GlobalNavigationWrapper(
            child: Container(),
          ),
        ),
      );
      
      final fab = tester.widget<FloatingActionButton>(
        find.byType(FloatingActionButton)
      );
      
      expect(fab.backgroundColor, Colors.blue);
      expect(fab.foregroundColor, Colors.white);
      expect(fab.elevation, 8);
    });
  });
}
```

### 2. test/components/bottom_drawer_test.dart

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:aic_mobile/components/bottom_drawer.dart';

@GenerateMocks([GoRouter])
import 'bottom_drawer_test.mocks.dart';

void main() {
  group('BottomDrawer Tests', () {
    testWidgets('should display all navigation items', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BottomDrawer(),
          ),
        ),
      );
      
      // Проверить заголовок
      expect(find.text('Навигация AIc'), findsOneWidget);
      expect(find.byIcon(Icons.explore_rounded), findsOneWidget);
      
      // Проверить все пункты меню
      expect(find.text('Главная'), findsOneWidget);
      expect(find.text('Чат с AI'), findsOneWidget);
      expect(find.text('Мотивация'), findsOneWidget);
      expect(find.text('Медитация'), findsOneWidget);
      expect(find.text('Советы'), findsOneWidget);
      expect(find.text('Профиль'), findsOneWidget);
      expect(find.text('Поддержка'), findsOneWidget);
      expect(find.text('Настройки'), findsOneWidget);
      
      // Проверить footer
      expect(find.text('AI компаньон для подростков'), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });

    testWidgets('should show correct subtitles for each item', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BottomDrawer(),
          ),
        ),
      );
      
      expect(find.text('Добро пожаловать в AIc'), findsOneWidget);
      expect(find.text('Поговори с Grok-4'), findsOneWidget);
      expect(find.text('Вдохновение и поддержка'), findsOneWidget);
      expect(find.text('Практики осознанности'), findsOneWidget);
      expect(find.text('Полезные рекомендации'), findsOneWidget);
      expect(find.text('Настройки аккаунта'), findsOneWidget);
      expect(find.text('Помощь и консультации'), findsOneWidget);
      expect(find.text('Конфигурация приложения'), findsOneWidget);
    });

    testWidgets('should show correct icons for each item', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BottomDrawer(),
          ),
        ),
      );
      
      expect(find.byIcon(Icons.home_rounded), findsOneWidget);
      expect(find.byIcon(Icons.smart_toy_rounded), findsOneWidget);
      expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
      expect(find.byIcon(Icons.self_improvement_rounded), findsOneWidget);
      expect(find.byIcon(Icons.lightbulb_rounded), findsOneWidget);
      expect(find.byIcon(Icons.person_rounded), findsOneWidget);
      expect(find.byIcon(Icons.support_agent_rounded), findsOneWidget);
      expect(find.byIcon(Icons.settings_rounded), findsOneWidget);
    });

    testWidgets('should have close button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BottomDrawer(),
          ),
        ),
      );
      
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    });

    testWidgets('should show modal bottom sheet when show() called', (tester) async {
      late BuildContext testContext;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              testContext = context;
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () => BottomDrawer.show(context),
                  child: Text('Open Menu'),
                ),
              );
            },
          ),
        ),
      );
      
      // Нажать кнопку открытия меню
      await tester.tap(find.text('Open Menu'));
      await tester.pumpAndSettle();
      
      // Проверить что BottomSheet открылся
      expect(find.text('Навигация AIc'), findsOneWidget);
      expect(find.byType(DraggableScrollableSheet), findsOneWidget);
    });

    testWidgets('should have correct colors for items', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BottomDrawer(),
          ),
        ),
      );
      
      // Тест цветов для разных пунктов (если важно)
      // Можно проверить что иконки имеют правильные цвета
    });
  });

  group('NavigationItem Tests', () {
    test('should create NavigationItem with all properties', () {
      final item = NavigationItem(
        title: 'Test Title',
        subtitle: 'Test Subtitle', 
        icon: Icons.test_tube,
        route: '/test',
        color: Colors.red,
      );
      
      expect(item.title, 'Test Title');
      expect(item.subtitle, 'Test Subtitle');
      expect(item.icon, Icons.test_tube);
      expect(item.route, '/test');
      expect(item.color, Colors.red);
    });
  });
}
```

### 3. test/features/navigation/bottom_drawer_integration_test.dart

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:aic_mobile/components/global_navigation_wrapper.dart';
import 'package:aic_mobile/components/bottom_drawer.dart';

void main() {
  group('Bottom Drawer Integration Tests', () {
    testWidgets('should integrate with GlobalNavigationWrapper', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: GlobalNavigationWrapper(
            child: Scaffold(
              body: Center(child: Text('Test Page')),
            ),
          ),
        ),
      );
      
      // Проверить что страница отображается
      expect(find.text('Test Page'), findsOneWidget);
      
      // Проверить что кнопка меню есть
      expect(find.text('Меню'), findsOneWidget);
      
      // Открыть меню
      await tester.tap(find.text('Меню'));
      await tester.pumpAndSettle();
      
      // Проверить что drawer открылся поверх контента
      expect(find.text('Test Page'), findsOneWidget); // Контент остается
      expect(find.text('Навигация AIc'), findsOneWidget); // Drawer появился
    });

    testWidgets('should handle drawer scrolling', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: GlobalNavigationWrapper(
            child: Container(),
          ),
        ),
      );
      
      // Открыть drawer
      await tester.tap(find.text('Меню'));
      await tester.pumpAndSettle();
      
      // Проверить что можно скроллить (DraggableScrollableSheet)
      expect(find.byType(DraggableScrollableSheet), findsOneWidget);
      
      // Попробовать скролл
      await tester.drag(
        find.byType(DraggableScrollableSheet), 
        Offset(0, -200)
      );
      await tester.pumpAndSettle();
      
      // Drawer должен остаться открытым
      expect(find.text('Навигация AIc'), findsOneWidget);
    });

    testWidgets('should close drawer with close button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: GlobalNavigationWrapper(
            child: Container(),
          ),
        ),
      );
      
      // Открыть drawer
      await tester.tap(find.text('Меню'));
      await tester.pumpAndSettle();
      
      // Закрыть через кнопку X
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();
      
      // Drawer должен закрыться
      expect(find.text('Навигация AIc'), findsNothing);
    });

    testWidgets('should persist menu button across navigation', (tester) async {
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => GlobalNavigationWrapper(
              child: Scaffold(body: Text('Home')),
            ),
          ),
          GoRoute(
            path: '/other',
            builder: (context, state) => GlobalNavigationWrapper(
              child: Scaffold(body: Text('Other')),
            ),
          ),
        ],
      );
      
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );
      
      // Проверить что на главной есть меню
      expect(find.text('Меню'), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      
      // Навигация на другую страницу
      router.go('/other');
      await tester.pumpAndSettle();
      
      // Проверить что меню есть и на новой странице
      expect(find.text('Меню'), findsOneWidget);
      expect(find.text('Other'), findsOneWidget);
    });
  });
}
```

### 4. test/utils/navigation_test_helpers.dart

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class NavigationTestHelpers {
  /// Открыть bottom drawer через кнопку меню
  static Future<void> openBottomMenu(WidgetTester tester) async {
    await tester.tap(find.text('Меню'));
    await tester.pumpAndSettle();
  }
  
  /// Закрыть drawer через кнопку X
  static Future<void> closeBottomMenu(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
  }
  
  /// Нажать на секцию в drawer
  static Future<void> tapDrawerSection(WidgetTester tester, String sectionName) async {
    await tester.tap(find.text(sectionName));
    await tester.pumpAndSettle();
  }
  
  /// Проверить что drawer открыт
  static void expectDrawerOpen(WidgetTester tester) {
    expect(find.text('Навигация AIc'), findsOneWidget);
    expect(find.byType(DraggableScrollableSheet), findsOneWidget);
  }
  
  /// Проверить что drawer закрыт
  static void expectDrawerClosed(WidgetTester tester) {
    expect(find.text('Навигация AIc'), findsNothing);
  }
  
  /// Проверить что кнопка меню видна
  static void expectMenuButtonVisible(WidgetTester tester) {
    expect(find.text('Меню'), findsOneWidget);
    expect(find.byIcon(Icons.explore_rounded), findsOneWidget);
  }
  
  /// Создать приложение с router для тестов
  static Widget createTestAppWithNavigation({
    required Widget child,
    bool showNavigation = true,
  }) {
    return MaterialApp(
      home: GlobalNavigationWrapper(
        showNavigation: showNavigation,
        child: child,
      ),
    );
  }
  
  /// Проверить все секции drawer
  static void expectAllDrawerSections(WidgetTester tester) {
    final sections = [
      'Главная', 'Чат с AI', 'Мотивация', 'Медитация',
      'Советы', 'Профиль', 'Поддержка', 'Настройки'
    ];
    
    for (final section in sections) {
      expect(find.text(section), findsOneWidget);
    }
  }
}
```

## 🎯 Приоритет создания тестов:

1. **Высокий**: GlobalNavigationWrapper тесты (основной компонент)
2. **Высокий**: BottomDrawer unit тесты (новая функциональность)
3. **Средний**: Integration тесты между компонентами
4. **Низкий**: Helper утилиты (упростят разработку других тестов)

## 🔧 Технические рекомендации:

1. **Моки**: Использовать моки для GoRouter в тестах навигации
2. **Таймауты**: Учесть анимации DraggableScrollableSheet
3. **Изоляция**: Каждый тест должен быть независимым
4. **Coverage**: Стремиться к 90%+ покрытию новых компонентов