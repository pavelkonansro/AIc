import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol_finders/patrol_finders.dart';
import 'package:aic_mobile/main.dart' as app;

void main() {
  group('Chat Feature Tests', () {
    patrolTest('Chat UI components are present', (PatrolIntegrationTester $) async {
      await $.pumpWidgetAndSettle(app.AicApp());
      await $.pump(const Duration(seconds: 3));
      await $.pumpAndSettle();
      
      // Переходим в чат
      await $.tap($('Чат с AIc'));
      await $.pumpAndSettle();
      
      // Проверяем основные UI элементы чата
      expect($(TextField), findsOneWidget);
      expect($(FloatingActionButton), findsOneWidget);
      
      // Проверяем что есть область для сообщений
      expect($(ListView), findsOneWidget);  // Chat messages container
      
      // Проверяем приветственное сообщение
      expect($('Привет! Я AIc - твой AI-компаньон. Как дела? 😊'), findsOneWidget);
    });

    patrolTest('Send message functionality', (PatrolIntegrationTester $) async {
      await $.pumpWidgetAndSettle(app.AicApp());
      await $.pump(const Duration(seconds: 3));
      await $.pumpAndSettle();
      
      await $.tap($('Чат с AIc'));
      await $.pumpAndSettle();
      
      const testMessage = 'Это тестовое сообщение';
      
      // Вводим текст
      await $.enterText($(TextField), testMessage);
      await $.pumpAndSettle();
      
      // Проверяем что текст появился в поле ввода
      expect($(testMessage), findsOneWidget);
      
      // Отправляем сообщение
      await $.tap($(FloatingActionButton));
      await $.pumpAndSettle();
      
      // Проверяем что сообщение появилось в чате
      expect($(testMessage), findsOneWidget);
      
      // Проверяем что поле ввода очистилось
      final textField = $.tester.widget<TextField>($(TextField));
      expect(textField.controller?.text, isEmpty);
    });

    patrolTest('Multiple messages conversation', (PatrolIntegrationTester $) async {
      await $.pumpWidgetAndSettle(app.AicApp());
      await $.pump(const Duration(seconds: 3));
      await $.pumpAndSettle();
      
      await $.tap($('Чат с AIc'));
      await $.pumpAndSettle();
      
      final messages = [
        'Привет!',
        'Как дела?',
        'Расскажи что-нибудь интересное',
        'Спасибо за помощь!'
      ];
      
      for (final message in messages) {
        await $.enterText($(TextField), message);
        await $.tap($(FloatingActionButton));
        await $.pumpAndSettle();
        
        // Небольшая пауза между сообщениями
        await $.pump(const Duration(milliseconds: 500));
        
        // Проверяем что сообщение появилось
        expect($(message), findsOneWidget);
      }
      
      // Проверяем что все сообщения видны
      for (final message in messages) {
        expect($(message), findsOneWidget);
      }
      
      // Ждем возможных ответов от AI
      await $.pump(const Duration(seconds: 2));
      await $.pumpAndSettle();
      
      // Должно быть минимум: приветственное + наши сообщения
      expect($(Text), findsAtLeast(5));
    });

    patrolTest('Chat handles empty messages', (PatrolIntegrationTester $) async {
      await $.pumpWidgetAndSettle(app.AicApp());
      await $.pump(const Duration(seconds: 3));
      await $.pumpAndSettle();
      
      await $.tap($('Чат с AIc'));
      await $.pumpAndSettle();
      
      // Пробуем отправить пустое сообщение
      await $.tap($(FloatingActionButton));
      await $.pumpAndSettle();
      
      // Пробуем отправить сообщение только из пробелов
      await $.enterText($(TextField), '   ');
      await $.tap($(FloatingActionButton));
      await $.pumpAndSettle();
      
      // Приложение не должно крашиться
      expect($(TextField), findsOneWidget);
      expect($('Привет! Я AIc - твой AI-компаньон. Как дела? 😊'), findsOneWidget);
    });

    patrolTest('Chat handles long messages', (PatrolIntegrationTester $) async {
      await $.pumpWidgetAndSettle(app.AicApp());
      await $.pump(const Duration(seconds: 3));
      await $.pumpAndSettle();
      
      await $.tap($('Чат с AIc'));
      await $.pumpAndSettle();
      
      const longMessage = 'Это очень длинное сообщение, которое должно правильно отображаться в чате. '
          'Оно содержит много текста и может занимать несколько строк. '
          'Важно проверить, что интерфейс корректно обрабатывает такие сообщения '
          'и не ломается при их отображении. Также нужно убедиться, что все '
          'элементы интерфейса остаются доступными и функциональными.';
      
      await $.enterText($(TextField), longMessage);
      await $.tap($(FloatingActionButton));
      await $.pumpAndSettle();
      
      // Проверяем что длинное сообщение отобразилось
      expect($(longMessage), findsOneWidget);
      
      // Проверяем что интерфейс не сломался
      expect($(TextField), findsOneWidget);
      expect($(FloatingActionButton), findsOneWidget);
    });

    patrolTest('Chat scroll functionality', (PatrolIntegrationTester $) async {
      await $.pumpWidgetAndSettle(app.AicApp());
      await $.pump(const Duration(seconds: 3));
      await $.pumpAndSettle();
      
      await $.tap($('Чат с AIc'));
      await $.pumpAndSettle();
      
      // Отправляем много сообщений чтобы заполнить экран
      for (int i = 1; i <= 10; i++) {
        await $.enterText($(TextField), 'Сообщение номер $i');
        await $.tap($(FloatingActionButton));
        await $.pumpAndSettle();
        await $.pump(const Duration(milliseconds: 200));
      }
      
      // Проверяем что можем скроллить чат
      final listView = $(ListView);
      expect(listView, findsOneWidget);
      
      // Пробуем скролл вверх
      await $.drag(listView, const Offset(0, 200));
      await $.pumpAndSettle();
      
      // Пробуем скролл вниз
      await $.drag(listView, const Offset(0, -200));
      await $.pumpAndSettle();
      
      // Интерфейс должен остаться функциональным
      expect($(TextField), findsOneWidget);
      expect($(FloatingActionButton), findsOneWidget);
    });

    patrolTest('Chat response time handling', (PatrolIntegrationTester $) async {
      await $.pumpWidgetAndSettle(app.AicApp());
      await $.pump(const Duration(seconds: 3));
      await $.pumpAndSettle();
      
      await $.tap($('Чат с AIc'));
      await $.pumpAndSettle();
      
      // Отправляем сообщение
      await $.enterText($(TextField), 'Привет, как дела?');
      await $.tap($(FloatingActionButton));
      await $.pumpAndSettle();
      
      // Проверяем что наше сообщение сразу появилось
      expect($('Привет, как дела?'), findsOneWidget);
      
      // Ждем ответ от AI (если есть реальная интеграция)
      await $.pump(const Duration(seconds: 3));
      await $.pumpAndSettle();
      
      // Проверяем что интерфейс остается отзывчивым во время ожидания
      expect($(TextField), findsOneWidget);
      expect($(FloatingActionButton), findsOneWidget);
      
      // Можем отправить еще одно сообщение пока ждем ответ
      await $.enterText($(TextField), 'Еще одно сообщение');
      await $.tap($(FloatingActionButton));
      await $.pumpAndSettle();
      
      expect($('Еще одно сообщение'), findsOneWidget);
    });

    patrolTest('Chat navigation and back button', (PatrolIntegrationTester $) async {
      await $.pumpWidgetAndSettle(app.AicApp());
      await $.pump(const Duration(seconds: 3));
      await $.pumpAndSettle();
      
      await $.tap($('Чат с AIc'));
      await $.pumpAndSettle();
      
      // Отправляем сообщение чтобы создать состояние
      await $.enterText($(TextField), 'Тестовое сообщение');
      await $.tap($(FloatingActionButton));
      await $.pumpAndSettle();
      
      // Возвращаемся назад
      await $.tap($(Icons.arrow_back));
      await $.pumpAndSettle();
      
      // Проверяем что вернулись на главный экран
      expect($('Главная'), findsOneWidget);
      expect($('Быстрые действия'), findsOneWidget);
      
      // Снова заходим в чат
      await $.tap($('Чат с AIc'));
      await $.pumpAndSettle();
      
      // Проверяем базовое состояние чата
      expect($(TextField), findsOneWidget);
      expect($('Привет! Я AIc - твой AI-компаньон. Как дела? 😊'), findsOneWidget);
    });

    patrolTest('Chat keyboard interaction', (PatrolIntegrationTester $) async {
      await $.pumpWidgetAndSettle(app.AicApp());
      await $.pump(const Duration(seconds: 3));
      await $.pumpAndSettle();
      
      await $.tap($('Чат с AIc'));
      await $.pumpAndSettle();
      
      // Тапаем на поле ввода
      await $.tap($(TextField));
      await $.pumpAndSettle();
      
      // Вводим текст по символам (имитация печати)
      const message = 'Привет';
      for (int i = 0; i < message.length; i++) {
        await $.enterText($(TextField), message.substring(0, i + 1));
        await $.pump(const Duration(milliseconds: 100));
      }
      
      await $.pumpAndSettle();
      
      // Отправляем сообщение
      await $.tap($(FloatingActionButton));
      await $.pumpAndSettle();
      
      expect($(message), findsOneWidget);
    });

    patrolTest('Chat special characters and emojis', (PatrolIntegrationTester $) async {
      await $.pumpWidgetAndSettle(app.AicApp());
      await $.pump(const Duration(seconds: 3));
      await $.pumpAndSettle();
      
      await $.tap($('Чат с AIc'));
      await $.pumpAndSettle();
      
      final specialMessages = [
        'Привет! 😊🎉💝',
        'Как дела? ¿¡§±',
        'Тест 123 !@#\$%^&*()',
        'Русский текст с ёъьыэю',
        'Mixed text with émojis 🚀🌟'
      ];
      
      for (final message in specialMessages) {
        await $.enterText($(TextField), message);
        await $.tap($(FloatingActionButton));
        await $.pumpAndSettle();
        await $.pump(const Duration(milliseconds: 300));
        
        // Проверяем что сообщение корректно отобразилось
        expect($(message), findsOneWidget);
      }
      
      // Интерфейс должен остаться функциональным
      expect($(TextField), findsOneWidget);
      expect($(FloatingActionButton), findsOneWidget);
    });
  });
}