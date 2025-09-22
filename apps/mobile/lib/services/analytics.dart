// Временно отключен Amplitude до исправления API
import 'logger.dart';

class AnalyticsService {
  static bool _initialized = false;

  static Future<void> initialize(String apiKey) async {
    if (_initialized) return;

    // TODO: Исправить Amplitude API
    AppLogger.w('Analytics initialized with placeholder. API Key: ${apiKey.substring(0, 8)}...');
    _initialized = true;
  }

  static Future<void> setUserId(String userId) async {
    if (!_initialized) return;
    AppLogger.d('Analytics setUserId: $userId');
  }

  static Future<void> setUserProperties(Map<String, dynamic> properties) async {
    if (!_initialized) return;
    AppLogger.d('Analytics setUserProperties: $properties');
  }

  static Future<void> trackEvent(String eventName,
      [Map<String, dynamic>? properties]) async {
    if (!_initialized) return;
    AppLogger.i('Analytics trackEvent: $eventName, properties: $properties');
  }
}