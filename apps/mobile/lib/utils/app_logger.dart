import 'package:flutter/foundation.dart';

class AppLogger {
  static void logEvent(String event, {Map<String, dynamic>? parameters}) {
    if (kDebugMode) {
      print('📊 Analytics Event: $event');
      if (parameters != null && parameters.isNotEmpty) {
        print('   Parameters: $parameters');
      }
    }
  }

  static void logError(String error, {dynamic exception, StackTrace? stackTrace}) {
    if (kDebugMode) {
      print('❌ Error: $error');
      if (exception != null) {
        print('   Exception: $exception');
      }
      if (stackTrace != null) {
        print('   Stack trace: $stackTrace');
      }
    }
  }

  static void logInfo(String message) {
    if (kDebugMode) {
      print('ℹ️ Info: $message');
    }
  }

  static void logDebug(String message) {
    if (kDebugMode) {
      print('🐛 Debug: $message');
    }
  }
}