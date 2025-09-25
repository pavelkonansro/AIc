// Временно отключен Amplitude до исправления API
import '../utils/app_logger.dart';
import '../utils/string_utils.dart';

class AnalyticsService {
  static bool _initialized = false;

  static Future<void> initialize(String apiKey) async {
    if (_initialized) return;

    // TODO: Исправить Amplitude API
    AppLogger.logInfo('Analytics initialized with placeholder. API Key: ${StringUtils.logPreview(apiKey, 8)}');
    _initialized = true;
  }

  static Future<void> setUserId(String userId) async {
    if (!_initialized) return;
    AppLogger.logDebug('Analytics setUserId: $userId');
  }

  static Future<void> setUserProperties(Map<String, dynamic> properties) async {
    if (!_initialized) return;
    AppLogger.logDebug('Analytics setUserProperties: $properties');
  }

  static Future<void> trackEvent(String eventName,
      [Map<String, dynamic>? properties]) async {
    if (!_initialized) return;
    AppLogger.logInfo('Analytics trackEvent: $eventName, properties: $properties');
  }
}