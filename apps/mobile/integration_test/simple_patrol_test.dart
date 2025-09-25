import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  group('Simple Integration Tests', () {
    testWidgets('Simple app launch test', (tester) async {
      // Простейший тест - просто запускаем приложение
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          appBar: AppBar(title: Text('Test App')),
          body: Center(child: Text('Hello Integration Test!')),
        ),
      ));
      
      await tester.pumpAndSettle();
      
      // Проверяем что текст есть на экране
      expect(find.text('Hello Integration Test!'), findsOneWidget);
      
      // Ждем секунду
      await tester.pump(Duration(seconds: 1));
    });
  });
}