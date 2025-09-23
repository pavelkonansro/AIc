import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    if (kIsWeb) {
      debugPrint('🌐 AIc Web билд загружается из: ${Uri.base.origin}');
    } else {
      debugPrint(
          '📱 AIc запускается на платформе: ${defaultTargetPlatform.toString()}');
    }
  } catch (_) {
    // Игнорируем, если Uri.base недоступен (например, на desktop ранней инициализации)
  }

  // Инициализируем Firebase с обработкой ошибок
  debugPrint('� Инициализируем Firebase...');
  
  // Временно отключаем Firebase для тестирования
  // try {
  //   await Firebase.initializeApp(
  //     options: DefaultFirebaseOptions.currentPlatform,
  //   );
  //   debugPrint('✅ Firebase инициализирован успешно');
  // } catch (error) {
  //   debugPrint('⚠️ Firebase initialization failed: $error');
  //   // Продолжаем без Firebase
  // }

  // Временно отключаем уведомления для тестирования
  // try {
  //   await NotificationService.initialize();
  //   debugPrint('✅ NotificationService инициализирован успешно');
  // } catch (error) {
  //   debugPrint('⚠️ Notification service initialization failed: $error');
  //   // Продолжаем без уведомлений
  // }

  debugPrint('🚀 Запуск простого AIc для тестирования...');
  runApp(const ProviderScope(child: SimpleTestApp()));
}

class SimpleTestApp extends StatelessWidget {
  const SimpleTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AIc Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const TestHomePage(),
    );
  }
}

class TestHomePage extends StatelessWidget {
  const TestHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AIc Test App'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle,
              size: 100,
              color: Colors.green,
            ),
            SizedBox(height: 20),
            Text(
              'AIc App Works!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Simplified version for testing',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 30),
            Text(
              '✅ No Firebase crashes',
              style: TextStyle(fontSize: 14, color: Colors.green),
            ),
            Text(
              '✅ No router issues',
              style: TextStyle(fontSize: 14, color: Colors.green),
            ),
            Text(
              '✅ Basic Flutter working',
              style: TextStyle(fontSize: 14, color: Colors.green),
            ),
          ],
        ),
      ),
    );
  }
}
