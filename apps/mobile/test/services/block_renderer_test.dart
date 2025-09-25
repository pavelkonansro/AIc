import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aic_mobile/services/block_renderer.dart';

void main() {
  group('Dynamic Content System Tests', () {
    testWidgets('should render hero_card block', (tester) async {
      final blockData = {
        'type': 'hero_card',
        'title': 'Тестовый заголовок',
        'subtitle': 'Тестовый подзаголовок',
        'background_color': '#FFE0E0E0',
        'text_color': '#FF000000',
      };

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: BlockRenderer(blockData: blockData),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Тестовый заголовок'), findsOneWidget);
      expect(find.text('Тестовый подзаголовок'), findsOneWidget);
    });

    testWidgets('should render mood_selector block', (tester) async {
      final blockData = {
        'type': 'mood_selector',
        'title': 'Как дела?',
        'moods': [
          {'emoji': '😊', 'label': 'Хорошо'},
          {'emoji': '😐', 'label': 'Нормально'},
          {'emoji': '😞', 'label': 'Плохо'},
        ],
      };

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: BlockRenderer(blockData: blockData),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Как дела?'), findsOneWidget);
      expect(find.text('😊'), findsOneWidget);
      expect(find.text('😐'), findsOneWidget);
      expect(find.text('😞'), findsOneWidget);
    });

    testWidgets('should render streak_card block', (tester) async {
      final blockData = {
        'type': 'streak_card',
        'title': 'Твоя серия',
        'subtitle': 'дней подряд',
        'icon': 'flame',
      };

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: BlockRenderer(blockData: blockData),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Твоя серия'), findsOneWidget);
      expect(find.text('дней подряд'), findsOneWidget);
    });

    testWidgets('should render quick_actions block', (tester) async {
      final blockData = {
        'type': 'quick_actions',
        'title': 'Быстрые действия',
        'actions': [
          {
            'title': 'Чат',
            'subtitle': 'Поговорить с Айком',
            'icon': 'chat',
            'color': '#FF2196F3',
            'route': '/chat',
          },
          {
            'title': 'Медитация',
            'subtitle': 'Расслабиться',
            'icon': 'self_improvement', 
            'color': '#FF4CAF50',
            'route': '/meditation',
          },
        ],
      };

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: BlockRenderer(blockData: blockData),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Быстрые действия'), findsOneWidget);
      expect(find.text('Чат'), findsOneWidget);
      expect(find.text('Поговорить с Айком'), findsOneWidget);
      expect(find.text('Медитация'), findsOneWidget);
      expect(find.text('Расслабиться'), findsOneWidget);
    });

    testWidgets('should render category_grid block', (tester) async {
      final blockData = {
        'type': 'category_grid',
        'title': 'Категории',
        'categories': [
          {
            'title': 'Эмоции',
            'icon': 'favorite',
            'color': '#FFFF5722',
            'route': '/emotions',
          },
          {
            'title': 'Учеба',
            'icon': 'school',
            'color': '#FF9C27B0',
            'route': '/study',
          },
        ],
      };

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: BlockRenderer(blockData: blockData),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Категории'), findsOneWidget);
      expect(find.text('Эмоции'), findsOneWidget);
      expect(find.text('Учеба'), findsOneWidget);
    });

    testWidgets('should handle unknown block type gracefully', (tester) async {
      final blockData = {
        'type': 'unknown_block_type',
        'title': 'Неизвестный блок',
      };

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: BlockRenderer(blockData: blockData),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should not crash and show some fallback
      expect(tester.takeException(), isNull);
      expect(find.byType(Container), findsAtLeastNWidgets(1));
    });

    testWidgets('should handle tap events on quick actions', (tester) async {
      final blockData = {
        'type': 'quick_actions',
        'title': 'Быстрые действия',
        'actions': [
          {
            'title': 'Чат',
            'subtitle': 'Поговорить с Айком',
            'icon': 'chat',
            'color': '#FF2196F3',
            'route': '/chat',
          },
        ],
      };

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: BlockRenderer(blockData: blockData),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Try tapping the action - should not crash
      await tester.tap(find.text('Чат'));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });
}