import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'services/notifications.dart';

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

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (error) {
    debugPrint('Firebase initialization skipped: $error');
  }

  try {
    await NotificationService.initialize();
  } catch (error) {
    debugPrint('Notification service initialization skipped: $error');
  }

  runApp(const AicApp());
}
