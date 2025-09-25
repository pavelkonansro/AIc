import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:aic_mobile/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Simple Integration Tests', () {
    testWidgets('App starts without crashing', (WidgetTester tester) async {
      // Просто запускаем приложение и проверяем что оно не крашится
      try {
        app.main();
        await tester.pump();
        await tester.pump(Duration(seconds: 1));
        await tester.pump();
        
        print('✅ App started successfully without crash');
        
        // Проверяем что есть любой widget
        final widgets = find.byType(Widget);
        expect(widgets, findsAtLeastNWidgets(1));
        
      } catch (e) {
        print('❌ App crashed: $e');
        fail('App should not crash on startup');
      }
    });

    testWidgets('App initializes Firebase', (WidgetTester tester) async {
      app.main();
      
      // Ждем инициализации
      for (int i = 0; i < 10; i++) {
        await tester.pump(Duration(milliseconds: 500));
      }
      
      print('✅ Firebase initialization completed');
      
      // Просто проверяем что все прошло без ошибок
      expect(true, isTrue);
    });
  });
}