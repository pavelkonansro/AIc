import 'package:amplitude_flutter/amplitude.dart';

class AnalyticsService {
  static late Amplitude _amplitude;
  static bool _initialized = false;

  static Future<void> initialize(String apiKey) async {
    if (_initialized) return;

    _amplitude = Amplitude.getInstance(instanceName: 'ike');
    await _amplitude.init(apiKey);
    _initialized = true;
  }

  static Future<void> setUserId(String userId) async {
    if (!_initialized) return;
    await _amplitude.setUserId(userId);
  }

  static Future<void> setUserProperties(Map<String, dynamic> properties) async {
    if (!_initialized) return;
    await _amplitude.setUserProperties(properties);
  }

  static Future<void> trackEvent(String eventName, [Map<String, dynamic>? properties]) async {
    if (!_initialized) return;
    await _amplitude.logEvent(eventName, eventProperties: properties);
  }

  // Специфичные события для Ike
  static Future<void> trackSignup({
    required String ageGroup,
    required String country,
  }) async {
    await trackEvent('user_signup', {
      'age_group': ageGroup,
      'country': country,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  static Future<void> trackChatMessage({
    required String sessionId,
    required bool isUser,
    int? messageLength,
  }) async {
    await trackEvent('chat_message', {
      'session_id': sessionId,
      'is_user': isUser,
      'message_length': messageLength,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  static Future<void> trackSosAccess({
    required String country,
    String? contactType,
  }) async {
    await trackEvent('sos_access', {
      'country': country,
      'contact_type': contactType,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  static Future<void> trackSubscriptionEvent({
    required String action, // 'purchase', 'cancel', 'restore'
    required String productId,
  }) async {
    await trackEvent('subscription_$action', {
      'product_id': productId,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  static Future<void> trackScreenView(String screenName) async {
    await trackEvent('screen_view', {
      'screen_name': screenName,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
}
