// Firebase Test Setup - обходим инициализацию Firebase
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';

class TestFirebaseOptions {
  static const FirebaseOptions currentPlatform = FirebaseOptions(
    apiKey: 'test-api-key',
    appId: 'test-app-id',
    messagingSenderId: 'test-sender-id',
    projectId: 'test-project-id',
    storageBucket: 'test-storage-bucket',
  );
}

Future<void> setupFirebaseForTests() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Пытаемся инициализировать Firebase для тестов
    await Firebase.initializeApp(
      options: TestFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Игнорируем ошибки инициализации в тестах
    print('Firebase test setup skipped: $e');
  }
}

// Вспомогательная функция для безопасного вызова Firebase операций в тестах
T? safeFirebaseCall<T>(T Function() operation) {
  try {
    return operation();
  } catch (e) {
    print('Firebase operation skipped in test: $e');
    return null;
  }
}