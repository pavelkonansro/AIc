import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class FirebaseConfig {
  static void configureForTesting() {
    // Используем эмулятор Firebase для тестирования
    if (kDebugMode) {
      FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
      print('🔥 Using Firebase Auth emulator on localhost:9099');
    } else {
      print('🔥 Using real Firebase Auth (no emulator)');
    }
  }
  
  // Fallback для тестирования без эмулятора
  static Future<User?> createTestUser() async {
    if (kDebugMode) {
      try {
        // Создаем тестового пользователя с фиктивными данными
        final testCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: 'test${DateTime.now().millisecondsSinceEpoch}@example.com',
          password: 'testpassword123',
        );
        
        await testCredential.user?.updateDisplayName('Test User');
        return testCredential.user;
      } catch (e) {
        print('❌ Test user creation failed: $e');
        return null;
      }
    }
    return null;
  }
}