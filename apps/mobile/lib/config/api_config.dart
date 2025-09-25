import 'package:flutter/foundation.dart';

// Среды для тестирования
enum ServerEnvironment { 
  local,      // Mac разработчика
  beget,      // Beget hosting для тестирования
  production  // Продакшн сервер
}

class ApiConfig {
  // 🔄 ПЕРЕКЛЮЧАТЕЛЬ СЕРВЕРОВ - измени здесь для переключения
  static const ServerEnvironment _currentEnv = ServerEnvironment.beget;
  
  // Конфигурация серверов
  static const String _macIp = '192.168.68.65';        // IP Mac
  static const String _begetDomain = 'konans6z.beget.tech';  // ✅ Ваш Beget домен
  static const String _prodUrl = 'https://api.aic-app.com';     // Продакшн
  static const String _port = '3000';
  
  // Конфигурация для каждой среды
  static const Map<ServerEnvironment, Map<String, String>> _configs = {
    ServerEnvironment.local: {
      'name': 'Mac Local',
      'baseUrl': 'http://$_macIp:$_port',
      'wsUrl': 'ws://$_macIp:$_port',
      'description': 'Локальный сервер на Mac разработчика'
    },
    ServerEnvironment.beget: {
      'name': 'Beget Hosting',
      'baseUrl': 'https://$_begetDomain',
      'wsUrl': 'wss://$_begetDomain',
      'description': 'Тестовый сервер на Beget хостинге с SSL'
    },
    ServerEnvironment.production: {
      'name': 'Production',
      'baseUrl': _prodUrl,
      'wsUrl': 'wss://api.aic-app.com',
      'description': 'Продакшн сервер'
    },
  };
  
  // Получение текущей конфигурации
  static Map<String, String> get _currentConfig => _configs[_currentEnv]!;
  
  static String get baseUrl {
    if (kIsWeb) {
      // Для веба используем текущую конфигурацию
      return _currentConfig['baseUrl']!;
    }
    
    // Для всех платформ используем текущую конфигурацию
    return _currentConfig['baseUrl']!;
  }
  
  static String get wsUrl {
    if (kIsWeb) {
      return _currentConfig['wsUrl']!;
    }
    
    return _currentConfig['wsUrl']!;
  }
  
  // Информация о текущем сервере
  static ServerEnvironment get currentEnvironment => _currentEnv;
  static String get currentServerName => _currentConfig['name']!;
  static String get currentServerDescription => _currentConfig['description']!;
  
  // Все доступные серверы (для UI переключения)
  static List<ServerEnvironment> get availableEnvironments => 
      ServerEnvironment.values;
  
  static String getServerName(ServerEnvironment env) => 
      _configs[env]!['name']!;
  
  static String getServerUrl(ServerEnvironment env) => 
      _configs[env]!['baseUrl']!;
  
  // Вспомогательные методы для обратной совместимости
  static String get localIp => _macIp;
  static String get begetDomain => _begetDomain;
  static String get port => _port;
  
  // Проверка доступности сервера
  static bool get isLocalServer => _currentEnv == ServerEnvironment.local;
  static bool get isBegetServer => _currentEnv == ServerEnvironment.beget;
  static bool get isProductionServer => _currentEnv == ServerEnvironment.production;
}