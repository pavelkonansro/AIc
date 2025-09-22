import 'dart:convert';
import 'dart:ui' as ui;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'api_client.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await NotificationService.handleBackgroundMessage(message);
}

class NotificationService {
  static final _localNotifications = FlutterLocalNotificationsPlugin();
  static final _firebaseMessaging = FirebaseMessaging.instance;
  static bool _isInitialized = false;
  static String? _currentUserId;

  static Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }
    _isInitialized = true;

    if (kIsWeb) {
      debugPrint(
          'NotificationService: web platform detected, skipping FCM setup.');
      return;
    }

    tz_data.initializeTimeZones();

    await _firebaseMessaging.setAutoInitEnabled(true);
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _handleNotificationResponse,
    );

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleOpenedNotification);
    FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
      if (_currentUserId != null) {
        await _syncToken(userId: _currentUserId!, token: token);
      }
    });

    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      await _handleOpenedNotification(initialMessage);
    }

    await restoreUserContext();
  }

  static Future<void> restoreUserContext() async {
    final prefs = await SharedPreferences.getInstance();
    final storedUserId = prefs.getString('user_id');
    if (storedUserId != null) {
      await setUserContext(storedUserId);
    }
  }

  static Future<void> setUserContext(String? userId) async {
    if (kIsWeb) {
      return;
    }

    _currentUserId = userId;
    if (userId == null) {
      return;
    }

    final token = await _firebaseMessaging.getToken();
    if (token != null) {
      await _syncToken(userId: userId, token: token);
    }
  }

  static Future<void> clearCachedToken(String userId) async {
    if (kIsWeb) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('fcm_token_$userId');
  }

  static Future<void> handleBackgroundMessage(RemoteMessage message) async {
    debugPrint('Background notification: ${message.messageId}');
  }

  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification != null) {
      await showLocalNotification(
        title: notification.title ?? 'AIc',
        body: notification.body ?? 'У вас новое сообщение',
        payload: jsonEncode(message.data),
      );
    }
  }

  static Future<void> _handleOpenedNotification(RemoteMessage message) async {
    debugPrint(
        'Notification opened: ${message.messageId}, data: ${message.data}');
  }

  static void _handleNotificationResponse(NotificationResponse response) {
    debugPrint('Local notification tapped: ${response.payload}');
  }

  static Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'aic_chat_channel',
      'AIc Chat Notifications',
      channelDescription: 'Notifications about new chat activity',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      0,
      title,
      body,
      details,
      payload: payload,
    );
  }

  static Future<void> scheduleDaily({
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    if (kIsWeb) {
      debugPrint('Daily notifications are not supported on web.');
      return;
    }

    await _localNotifications.zonedSchedule(
      1,
      title,
      body,
      _nextInstanceOfTime(hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder',
          'Daily Reminders',
          channelDescription: 'Daily check-in reminders from AIc',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      matchDateTimeComponents: DateTimeComponents.time,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  static Future<void> _syncToken({
    required String userId,
    required String token,
  }) async {
    if (kIsWeb) {
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = 'fcm_token_$userId';
      final cachedToken = prefs.getString(cacheKey);
      if (cachedToken == token) {
        return;
      }

      final response = await http.post(
        Uri.parse('${ApiClient.baseUrl}/notifications/device'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'platform': _detectPlatform(),
          'deviceToken': token,
          'locale': _currentLocaleTag(),
          'metadata': {
            'timezone': tz.local.name,
          },
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        await prefs.setString(cacheKey, token);
        debugPrint('Device token synced for user $userId');
      } else {
        debugPrint(
          'Failed to sync device token (${response.statusCode}): ${response.body}',
        );
      }
    } catch (error) {
      debugPrint('Error syncing device token: $error');
    }
  }

  static String _detectPlatform() {
    if (kIsWeb) {
      return 'web';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.macOS:
        return 'macos';
      default:
        return 'unknown';
    }
  }

  static String _currentLocaleTag() {
    try {
      final locale = ui.PlatformDispatcher.instance.locale;
      return locale.toLanguageTag();
    } catch (error) {
      debugPrint('Failed to resolve locale: $error');
      return 'en';
    }
  }
}
