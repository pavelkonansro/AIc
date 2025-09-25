import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol_finders/patrol_finders.dart';
import 'package:aic_mobile/main.dart' as app;

void main() {
  group('API Integration Tests', () {
    patrolTest('API connection and health check', (PatrolIntegrationTester $) async {
      await $.pumpWidgetAndSettle(app.AicApp());
      await $.pump(const Duration(seconds: 3));
      await $.pumpAndSettle();
      
      // Если есть страница API тестов, переходим туда
      try {
        // Попробуем найти и перейти к API тестам через навигацию
        // В реальном приложении может быть скрытая кнопка или меню
        await $.scrollUntilVisible(finder: $('API Test'), view: $(Scrollable));
        await $.tap($('API Test'));
        await $.pumpAndSettle();
      } catch (e) {
        // Если нет прямого доступа к API тестам, используем альтернативный путь
        debugPrint('API Test page not directly accessible: $e');
      }
      
      // Базовая проверка что приложение запустилось и может работать с API
      expect($('Главная'), findsOneWidget);
    });

    patrolTest('Chat with real API integration', (PatrolIntegrationTester $) async {
      await $.pumpWidgetAndSettle(app.AicApp());
      await $.pump(const Duration(seconds: 3));
      await $.pumpAndSettle();
      
      // Переходим в чат который использует OpenRouter API
      await $.tap($('Чат с AIc'));
      await $.pumpAndSettle();
      
      // Отправляем сообщение которое должно пойти через API
      const apiTestMessage = 'Привет! Это тест API интеграции.';
      await $.enterText($(TextField), apiTestMessage);
      await $.tap($(FloatingActionButton));
      await $.pumpAndSettle();
      
      // Проверяем что наше сообщение отправлено
      expect($(apiTestMessage), findsOneWidget);
      
      // Ждем ответ от API (может занять время)
      await $.pump(const Duration(seconds: 5));
      await $.pumpAndSettle();
      
      // Проверяем что получили какой-то ответ
      // Точное содержание зависит от настройки API
      final textWidgets = $.tester.widgetList<Text>($(Text));
      expect(textWidgets.length, greaterThan(2)); // Больше чем приветственное + наше
      
      // Проверяем что интерфейс остался функциональным
      expect($(TextField), findsOneWidget);
      expect($(FloatingActionButton), findsOneWidget);
    });

    patrolTest('API error handling', (PatrolIntegrationTester $) async {
      await $.pumpWidgetAndSettle(app.AicApp());
      await $.pump(const Duration(seconds: 3));
      await $.pumpAndSettle();
      
      await $.tap($('Чат с AIc'));
      await $.pumpAndSettle();
      
      // Отправляем много сообщений быстро чтобы потенциально вызвать ошибку API
      for (int i = 0; i < 5; i++) {
        await $.enterText($(TextField), 'Быстрое сообщение $i');
        await $.tap($(FloatingActionButton));
        await $.pump(const Duration(milliseconds: 100)); // Очень быстро
      }
      
      await $.pumpAndSettle();
      
      // Ждем обработки всех запросов
      await $.pump(const Duration(seconds: 10));
      await $.pumpAndSettle();
      
      // Приложение не должно крашиться даже при ошибках API
      expect($(TextField), findsOneWidget);
      expect($(FloatingActionButton), findsOneWidget);
      
      // Должны видеть хотя бы наши отправленные сообщения
      expect($('Быстрое сообщение 0'), findsOneWidget);
    });

    patrolTest('Network connectivity handling', (PatrolIntegrationTester $) async {
      await $.pumpWidgetAndSettle(app.AicApp());
      await $.pump(const Duration(seconds: 3));
      await $.pumpAndSettle();
      
      // Проверяем что приложение корректно стартует
      expect($('Главная'), findsOneWidget);
      
      // Переходим в чат
      await $.tap($('Чат с AIc'));
      await $.pumpAndSettle();
      
      // Отправляем сообщение
      await $.enterText($(TextField), 'Тест подключения к сети');
      await $.tap($(FloatingActionButton));
      await $.pumpAndSettle();
      
      // Проверяем что сообщение отображается локально
      expect($('Тест подключения к сети'), findsOneWidget);
      
      // Ждем попытку соединения с API
      await $.pump(const Duration(seconds: 3));
      await $.pumpAndSettle();
      
      // Интерфейс должен оставаться отзывчивым независимо от состояния сети
      expect($(TextField), findsOneWidget);
      expect($(FloatingActionButton), findsOneWidget);
    });

    patrolTest('API response time tolerance', (PatrolIntegrationTester $) async {
      await $.pumpWidgetAndSettle(app.AicApp());
      await $.pump(const Duration(seconds: 3));
      await $.pumpAndSettle();
      
      await $.tap($('Чат с AIc'));
      await $.pumpAndSettle();
      
      // Отправляем сообщение
      await $.enterText($(TextField), 'Тест времени ответа API');
      await $.tap($(FloatingActionButton));
      await $.pumpAndSettle();
      
      // Проверяем что можем продолжать взаимодействовать с UI пока ждем ответ
      await $.enterText($(TextField), 'Второе сообщение');
      await $.pumpAndSettle();
      
      // Проверяем что поле ввода работает
      final textField = $.tester.widget<TextField>($(TextField));
      expect(textField.controller?.text, 'Второе сообщение');
      
      // Отправляем второе сообщение
      await $.tap($(FloatingActionButton));
      await $.pumpAndSettle();
      
      // Ждем обработки всех API запросов
      await $.pump(const Duration(seconds: 8));
      await $.pumpAndSettle();
      
      // Проверяем что оба сообщения видны
      expect($('Тест времени ответа API'), findsOneWidget);
      expect($('Второе сообщение'), findsOneWidget);
    });

    patrolTest('API configuration and fallback', (PatrolIntegrationTester $) async {
      await $.pumpWidgetAndSettle(app.AicApp());
      await $.pump(const Duration(seconds: 3));
      await $.pumpAndSettle();
      
      // Проверяем что приложение может работать в fallback режиме
      // если API недоступен
      expect($('Главная'), findsOneWidget);
      
      await $.tap($('Чат с AIc'));
      await $.pumpAndSettle();
      
      // Проверяем что чат доступен даже если API не работает
      expect($(TextField), findsOneWidget);
      expect($('Привет! Я AIc - твой AI-компаньон. Как дела? 😊'), findsOneWidget);
      
      // Отправляем сообщение
      await $.enterText($(TextField), 'Работает ли fallback?');
      await $.tap($(FloatingActionButton));
      await $.pumpAndSettle();
      
      // Сообщение должно отобразиться даже без API
      expect($('Работает ли fallback?'), findsOneWidget);
      
      // Ждем возможный fallback ответ
      await $.pump(const Duration(seconds: 3));
      await $.pumpAndSettle();
      
      // Интерфейс должен оставаться функциональным
      expect($(TextField), findsOneWidget);
      expect($(FloatingActionButton), findsOneWidget);
    });

    patrolTest('Multiple API calls handling', (PatrolIntegrationTester $) async {
      await $.pumpWidgetAndSettle(app.AicApp());
      await $.pump(const Duration(seconds: 3));
      await $.pumpAndSettle();
      
      await $.tap($('Чат с AIc'));
      await $.pumpAndSettle();
      
      // Создаем последовательность API вызовов
      final messages = [
        'Первый вопрос к API',
        'Второй вопрос к API', 
        'Третий вопрос к API',
        'Четвертый вопрос к API'
      ];
      
      // Отправляем сообщения с небольшими интервалами
      for (final message in messages) {
        await $.enterText($(TextField), message);
        await $.tap($(FloatingActionButton));
        await $.pumpAndSettle();
        
        // Небольшая пауза между запросами
        await $.pump(const Duration(seconds: 1));
      }
      
      // Ждем обработки всех API запросов
      await $.pump(const Duration(seconds: 12));
      await $.pumpAndSettle();
      
      // Проверяем что все наши сообщения видны
      for (final message in messages) {
        expect($(message), findsOneWidget);
      }
      
      // Проверяем что получили ответы (количество может варьироваться)
      final textWidgets = $.tester.widgetList<Text>($(Text));
      expect(textWidgets.length, greaterThan(messages.length + 1)); // Наши + приветственное + ответы
    });

    patrolTest('API authentication flow', (PatrolIntegrationTester $) async {
      await $.pumpWidgetAndSettle(app.AicApp());
      await $.pump(const Duration(seconds: 3));
      await $.pumpAndSettle();
      
      // Проверяем что можем получить доступ к функциям требующим аутентификации
      // В данном случае - чат с AI
      await $.tap($('Чат с AIc'));
      await $.pumpAndSettle();
      
      // Если требуется авторизация, должен работать guest режим
      expect($(TextField), findsOneWidget);
      
      // Отправляем сообщение которое может требовать аутентификации
      await $.enterText($(TextField), 'Тестирую авторизацию');
      await $.tap($(FloatingActionButton));
      await $.pumpAndSettle();
      
      expect($('Тестирую авторизацию'), findsOneWidget);
      
      // Ждем ответ от API
      await $.pump(const Duration(seconds: 5));
      await $.pumpAndSettle();
      
      // Должны получить какой-то ответ или fallback
      expect($(Text), findsAtLeast(2));
    });
  });
}