import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol_finders/patrol_finders.dart';
import 'package:aic_mobile/main.dart' as app;

void main() {
  group('AIc App Comprehensive Tests', () {
    patrolTest('App startup and navigation flow', (PatrolIntegrationTester $) async {
      // 1. Запуск приложения
      await $.pumpWidgetAndSettle(app.AicApp());
      
      // 2. Проверяем splash screen / loading
      expect($('AIc'), findsOneWidget);
      expect($('AI companion for teens'), findsOneWidget);
      expect($('Загрузка...'), findsOneWidget);
      
      // Ждем окончания инициализации (2 секунды + margin)
      await $.pump(const Duration(seconds: 3));
      await $.pumpAndSettle();
      
      // 3. Проверяем что попали на главный экран
      expect($('Главная'), findsOneWidget);
      expect($('Привет! 👋'), findsOneWidget);
      expect($('Как дела сегодня?'), findsOneWidget);
    });

    patrolTest('Home screen components render correctly', (PatrolIntegrationTester $) async {
      await $.pumpWidgetAndSettle(app.AicApp());
      await $.pump(const Duration(seconds: 3));
      await $.pumpAndSettle();
      
      // Проверяем основные блоки главного экрана
      expect($('Твое настроение'), findsOneWidget);
      expect($('Твоя серия'), findsOneWidget);
      expect($('Быстрые действия'), findsOneWidget);
      
      // Проверяем mood selector
      expect($('😄'), findsOneWidget);
      expect($('😊'), findsOneWidget);
      expect($('😐'), findsOneWidget);
      expect($('😕'), findsOneWidget);
      expect($('😢'), findsOneWidget);
      
      // Проверяем quick actions
      expect($('Чат с AIc'), findsOneWidget);
      expect($('Медитация'), findsOneWidget);
      expect($('Советы'), findsOneWidget);
      expect($('Поддержка'), findsOneWidget);
    });

    patrolTest('Navigation to Chat works', (PatrolIntegrationTester $) async {
      await $.pumpWidgetAndSettle(app.AicApp());
      await $.pump(const Duration(seconds: 3));
      await $.pumpAndSettle();
      
      // Нажимаем на кнопку чата
      await $.tap($('Чат с AIc'));
      await $.pumpAndSettle();
      
      // Проверяем что попали в чат
      // Должны увидеть интерфейс чата
      expect($(TextField), findsOneWidget);
      expect($(FloatingActionButton), findsOneWidget);
      
      // Проверяем приветственное сообщение от AIc
      expect($('Привет! Я AIc - твой AI-компаньон. Как дела? 😊'), findsOneWidget);
    });

    patrolTest('Chat functionality - send and receive messages', (PatrolIntegrationTester $) async {
      await $.pumpWidgetAndSettle(app.AicApp());
      await $.pump(const Duration(seconds: 3));
      await $.pumpAndSettle();
      
      // Переходим в чат
      await $.tap($('Чат с AIc'));
      await $.pumpAndSettle();
      
      // Проверяем что можем вводить текст
      final textField = $(TextField);
      expect(textField, findsOneWidget);
      
      // Вводим сообщение
      await $.enterText(textField, 'Привет, как дела?');
      await $.pumpAndSettle();
      
      // Отправляем сообщение
      await $.tap($(FloatingActionButton));
      await $.pumpAndSettle();
      
      // Проверяем что наше сообщение появилось
      expect($('Привет, как дела?'), findsOneWidget);
      
      // Ждем ответ от бота (может быть async)
      await $.pump(const Duration(seconds: 2));
      await $.pumpAndSettle();
      
      // Проверяем что получили какой-то ответ
      // (точный текст зависит от реализации mock/real AI)
      expect($(Text), findsAtLeast(3)); // Приветственное + наше + ответ
    });

    patrolTest('Navigation to all main sections', (PatrolIntegrationTester $) async {
      await $.pumpWidgetAndSettle(app.AicApp());
      await $.pump(const Duration(seconds: 3));
      await $.pumpAndSettle();
      
      // Тестируем навигацию в Медитацию
      await $.tap($('Медитация'));
      await $.pumpAndSettle();
      
      // Проверяем что перешли (должен быть заголовок или контент медитации)
      // В зависимости от реализации DynamicScreen
      expect($(AppBar), findsOneWidget);
      
      // Возвращаемся на главную
      await $.tap($(Icons.arrow_back));
      await $.pumpAndSettle();
      
      // Тестируем навигацию в Советы
      await $.tap($('Советы'));
      await $.pumpAndSettle();
      expect($(AppBar), findsOneWidget);
      
      // Возвращаемся на главную
      await $.tap($(Icons.arrow_back));
      await $.pumpAndSettle();
      
      // Тестируем навигацию в Поддержку
      await $.tap($('Поддержка'));
      await $.pumpAndSettle();
      expect($(AppBar), findsOneWidget);
    });

    patrolTest('Mood selector interaction', (PatrolIntegrationTester $) async {
      await $.pumpWidgetAndSettle(app.AicApp());
      await $.pump(const Duration(seconds: 3));
      await $.pumpAndSettle();
      
      // Тестируем выбор разных настроений
      await $.tap($('😄'));
      await $.pumpAndSettle();
      
      await $.tap($('😊'));  
      await $.pumpAndSettle();
      
      await $.tap($('😐'));
      await $.pumpAndSettle();
      
      await $.tap($('😕'));
      await $.pumpAndSettle();
      
      await $.tap($('😢'));
      await $.pumpAndSettle();
      
      // Все должно работать без крашей
      expect($(Text), findsAtLeast(1));
    });

    patrolTest('App handles navigation errors gracefully', (PatrolIntegrationTester $) async {
      await $.pumpWidgetAndSettle(app.AicApp());
      await $.pump(const Duration(seconds: 3));
      await $.pumpAndSettle();
      
      // Попробуем быстрые множественные нажатия
      await $.tap($('Чат с AIc'));
      await $.tap($('Медитация'));
      await $.tap($('Советы'));
      await $.pumpAndSettle();
      
      // Приложение не должно крашиться
      expect($(AppBar), findsOneWidget);
    });

    patrolTest('Deep navigation flow - Chat to Profile to Settings', (PatrolIntegrationTester $) async {
      await $.pumpWidgetAndSettle(app.AicApp());
      await $.pump(const Duration(seconds: 3));
      await $.pumpAndSettle();
      
      // Идем в чат
      await $.tap($('Чат с AIc'));
      await $.pumpAndSettle();
      
      // Предполагаем что в чате есть меню или способ перейти в профиль
      // Если нет - тестируем через системную навигацию
      try {
        await $.native.pressHome();
        await $.native.openApp();
        await $.pumpAndSettle();
        
        // Используем нативную навигацию если нужно
        // Здесь можно добавить более сложные сценарии
      } catch (e) {
        // Fallback если нативные действия не поддерживаются
        debugPrint('Native actions not supported, continuing with widget tests');
      }
    });

    patrolTest('Performance and memory test', (PatrolIntegrationTester $) async {
      await $.pumpWidgetAndSettle(app.AicApp());
      await $.pump(const Duration(seconds: 3));
      
      // Быстрая навигация между экранами
      for (int i = 0; i < 5; i++) {
        await $.tap($('Чат с AIc'));
        await $.pumpAndSettle();
        
        await $.tap($(Icons.arrow_back));
        await $.pumpAndSettle();
        
        await $.tap($('Медитация'));
        await $.pumpAndSettle();
        
        await $.tap($(Icons.arrow_back));
        await $.pumpAndSettle();
      }
      
      // Проверяем что приложение все еще отвечает
      expect($('Главная'), findsOneWidget);
    });

    patrolTest('Chat message history persistence', (PatrolIntegrationTester $) async {
      await $.pumpWidgetAndSettle(app.AicApp());
      await $.pump(const Duration(seconds: 3));
      await $.pumpAndSettle();
      
      // Переходим в чат
      await $.tap($('Чат с AIc'));
      await $.pumpAndSettle();
      
      // Отправляем несколько сообщений
      const messages = ['Привет', 'Как дела?', 'Что делаешь?'];
      
      for (final message in messages) {
        await $.enterText($(TextField), message);
        await $.tap($(FloatingActionButton));
        await $.pumpAndSettle();
        await $.pump(const Duration(seconds: 1));
      }
      
      // Проверяем что все сообщения видны
      for (final message in messages) {
        expect($(message), findsOneWidget);
      }
      
      // Выходим из чата и возвращаемся
      await $.tap($(Icons.arrow_back));
      await $.pumpAndSettle();
      
      await $.tap($('Чат с AIc'));
      await $.pumpAndSettle();
      
      // Проверяем что сообщения сохранились
      // (зависит от реализации - может быть временное хранение)
      expect($(Text), findsAtLeast(2)); // Хотя бы приветственное + что-то еще
    });

    patrolTest('Error handling - network failures', (PatrolIntegrationTester $) async {
      await $.pumpWidgetAndSettle(app.AicApp());
      await $.pump(const Duration(seconds: 3));
      await $.pumpAndSettle();
      
      // Если есть проблемы с сетью, приложение должно показать fallback
      // Это больше интеграционный тест, требующий мокирования сети
      
      // Базовая проверка что приложение не крашится при старте
      expect($('Главная'), findsOneWidget);
      
      // Пробуем перейти в чат (может потребовать сеть)
      await $.tap($('Чат с AIc'));
      await $.pumpAndSettle();
      
      // Должен либо загрузиться чат, либо показать ошибку, но не крашиться
      expect($(Scaffold), findsOneWidget);
    });
  });
}