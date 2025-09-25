// Firebase Test Helper - правильная инициализация Firebase для тестов
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Mock Firebase Options для тестов
class MockFirebaseOptions {
  static const FirebaseOptions currentPlatform = FirebaseOptions(
    apiKey: 'AIzaSyTest_firebase_api_key_for_tests',
    appId: '1:123456789:test:abcdef',
    messagingSenderId: '123456789',
    projectId: 'aic-test-project',
    storageBucket: 'aic-test-project.appspot.com',
    authDomain: 'aic-test-project.firebaseapp.com',
  );
}

/// Инициализирует Firebase для тестового окружения
/// Это позволяет использовать настоящий Firebase Auth в тестах
Future<void> setupFirebaseForTests() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Проверяем, не инициализирован ли уже Firebase
    Firebase.app();
    print('🔥 Firebase already initialized for tests');
  } catch (e) {
    // Firebase не инициализирован, инициализируем его
    await Firebase.initializeApp(
      options: MockFirebaseOptions.currentPlatform,
    );
    print('🔥 Firebase initialized for tests');
    
    // Настраиваем Firebase Auth для использования эмулятора в тестах
    try {
      await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
      print('🔥 Firebase Auth emulator connected');
    } catch (e) {
      print('⚠️ Firebase Auth emulator not available, using mock: $e');
    }
  }
}

/// Очищает состояние Firebase после тестов
Future<void> cleanupFirebaseAfterTests() async {
  try {
    // Выходим из всех аккаунтов
    await FirebaseAuth.instance.signOut();
    print('🧹 Firebase Auth cleaned up');
  } catch (e) {
    print('⚠️ Firebase cleanup failed: $e');
  }
}