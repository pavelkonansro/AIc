import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'firebase_options.dart';
import 'config/firebase_config.dart';

// Импорт компонентов приложения
import 'routes_simple.dart';
import 'components/auth_wrapper.dart';
import 'state/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    debugPrint('🚀 Starting AIc App...');

    // Initialize Firebase
    debugPrint('🔥 Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Configure Firebase for testing (emulator or fallback)
    if (kDebugMode) {
      FirebaseConfig.configureForTesting();
    }
    
    debugPrint('✅ Firebase initialized successfully');

    // Initialize Firebase Messaging
    debugPrint('📱 Setting up Firebase Messaging...');
    await _initializeFirebaseMessaging();
    debugPrint('✅ Firebase Messaging initialized');

    runApp(const ProviderScope(child: AicApp()));
  } catch (e) {
    debugPrint('❌ Error starting app: $e');
    // Fallback to debug app
    runApp(const ProviderScope(child: FallbackApp()));
  }
}

Future<void> _initializeFirebaseMessaging() async {
  try {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Request permission for iOS
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    debugPrint('User granted permission: ${settings.authorizationStatus}');

    // Get the token
    String? token = await messaging.getToken();
    debugPrint('FCM Token: $token');

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint('Message notification: ${message.notification}');
      }
    });
  } catch (e) {
    debugPrint('⚠️ Firebase Messaging initialization failed: $e');
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("Handling a background message: ${message.messageId}");
}

class AicApp extends StatelessWidget {
  const AicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'AIc - AI Companion',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          elevation: 2,
        ),
      ),
      routerConfig: simpleRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}


class FallbackApp extends StatelessWidget {
  const FallbackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AIc Fallback',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('AIc Fallback'),
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 80, color: Colors.red),
              SizedBox(height: 20),
              Text(
                'AIc Fallback Mode',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                'There was an issue loading the main app',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}