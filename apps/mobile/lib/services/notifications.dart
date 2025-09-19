import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final _localNotifications = FlutterLocalNotificationsPlugin();
  static final _firebaseMessaging = FirebaseMessaging.instance;

  static Future<void> initialize() async {
    // Запрос разрешений для уведомлений
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Настройка локальных уведомлений
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(initSettings);

    // Обработка уведомлений в фоне
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);
    
    // Обработка уведомлений в активном состоянии
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
  }

  static Future<String?> getToken() {
    return _firebaseMessaging.getToken();
  }

  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    print('Фоновое уведомление: ${message.messageId}');
  }

  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification != null) {
      await showLocalNotification(
        title: notification.title ?? 'AIc',
        body: notification.body ?? 'У вас новое сообщение',
      );
    }
  }

  static Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'ike_channel',
      'Ike Notifications',
      channelDescription: 'Уведомления от AIc',
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
    await _localNotifications.zonedSchedule(
      1,
      title,
      body,
      _nextInstanceOfTime(hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder',
          'Ежедневные напоминания',
          channelDescription: 'Ежедневные напоминания от AIc',
        ),
      ),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    
    return scheduledDate;
  }
}
