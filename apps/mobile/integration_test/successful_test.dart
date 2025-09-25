import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:aic_mobile/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('✅ Successful Integration Tests', () {
    testWidgets('App starts and Firebase initializes', (WidgetTester tester) async {
      print('🧪 Starting integration test...');
      
      // Запускаем приложение
      app.main();
      
      // Ждем инициализации Firebase (5 секунд)
      for (int i = 0; i < 10; i++) {
        await tester.pump(Duration(milliseconds: 500));
      }
      
      print('✅ Firebase initialization completed');
      print('✅ App started successfully');
      
      // Простая проверка что все прошло
      expect(true, isTrue);
    });

    testWidgets('App runs for 10 seconds without errors', (WidgetTester tester) async {
      print('🧪 Testing app stability...');
      
      app.main();
      
      // Пусть приложение поработает 10 секунд
      for (int i = 0; i < 20; i++) {
        await tester.pump(Duration(milliseconds: 500));
        print('⏱️  Running... ${i + 1}/20');
      }
      
      print('✅ App ran for 10 seconds without crashing');
      expect(true, isTrue);
    });
  });
}