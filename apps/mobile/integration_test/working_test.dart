import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:aic_mobile/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('AIc App Working Tests', () {
    testWidgets('App successfully launches and initializes', (WidgetTester tester) async {
      // Запускаем приложение
      app.main();
      
      // Даем время приложению инициализироваться
      await tester.pump(Duration(seconds: 2));
      await tester.pump();
      
      // Проверяем что MaterialApp есть на экране
      expect(find.byType(MaterialApp), findsOneWidget);
      
      print('✅ Integration Test: App launched successfully');
    });

    testWidgets('App contains basic UI elements', (WidgetTester tester) async {
      app.main();
      
      // Даем время приложению загрузиться
      await tester.pump(Duration(seconds: 3));
      
      // Проверяем что есть Scaffold (основная структура UI)
      expect(find.byType(Scaffold), findsAtLeastNWidgets(1));
      
      print('✅ Integration Test: Basic UI elements found');
    });
  });
}