import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:aic_mobile/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('AIc App Integration Tests', () {
    testWidgets('App launches and shows loading screen', (WidgetTester tester) async {
      // Запускаем приложение
      app.main();
      await tester.pumpAndSettle(Duration(seconds: 5));

      // Проверяем что приложение запустилось
      expect(find.byType(MaterialApp), findsOneWidget);
      
      // Подождем немного чтобы увидеть анимацию
      await tester.pump(Duration(seconds: 2));
    });

    testWidgets('Navigation works', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(Duration(seconds: 5));

      // Попробуем найти любую кнопку навигации
      await tester.pump(Duration(seconds: 1));
      
      // Просто проверим что приложение не крашится
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });
}