import 'package:flutter/foundation.dart';

class ApiConfig {
  // IP адрес вашего Mac в локальной сети
  static const String _localIp = '192.168.68.65';
  static const String _port = '3000';
  
  static String get baseUrl {
    if (kIsWeb) {
      // Для веба можем использовать localhost или IP
      return 'http://$_localIp:$_port';
    }
    
    // Для всех платформ (macOS, iOS, Android) используем IP адрес
    // Это позволит тестировать с любого устройства в локальной сети
    return 'http://$_localIp:$_port';
  }
  
  static String get wsUrl {
    if (kIsWeb) {
      return 'ws://$_localIp:$_port';
    }
    
    // WebSocket также по IP для всех устройств
    return 'ws://$_localIp:$_port';
  }
  
  // Вспомогательные методы
  static String get localIp => _localIp;
  static String get port => _port;
}