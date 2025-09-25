import 'package:flutter/foundation.dart';
import 'dart:io';

enum ServerEnvironment {
  lanDev,      // Локальная сеть: симулятор → 127.0.0.1:3000, iPhone → Mac IP:3000
  tunnelDev,   // Туннель: все → https://aic-dev-stable.ngrok.app
  production   // Продакшн: позже
}

class ApiConfig {
  // Автоопределение окружения
  static ServerEnvironment get currentEnvironment {
    // По умолчанию lanDev для разработки
    return ServerEnvironment.lanDev;
  }
  
  // Получение IP Mac для LAN режима
  static String get _macLocalIP => '192.168.68.65';
  
  // Определение устройства: симулятор или физическое
  static bool get _isSimulator {
    if (kDebugMode && Platform.isIOS) {
      // В симуляторе Environment.version содержит 'Simulator'
      return Platform.environment['SIMULATOR_DEVICE_NAME'] != null;
    }
    return false;
  }
  
  // Главные getters для текущего окружения
  static String get baseUrl => _getBaseUrl(currentEnvironment);
  static String get wsUrl => _getWsUrl(currentEnvironment);
  static String get currentServerName => getServerName(currentEnvironment);
  static String get currentServerDescription => getServerDescription(currentEnvironment);
  static String get environmentName => getServerName(currentEnvironment);
  
  static List<ServerEnvironment> get availableEnvironments => ServerEnvironment.values;
  
  // Внутренние методы для получения URL по окружению
  static String _getBaseUrl(ServerEnvironment env) {
    switch (env) {
      case ServerEnvironment.lanDev:
        // LAN: симулятор → localhost, iPhone → Mac IP
        return _isSimulator ? 'http://127.0.0.1:3000' : 'http://$_macLocalIP:3000';
      case ServerEnvironment.tunnelDev:
        return 'https://subcuticular-latrisha-commemoratively.ngrok-free.dev';
      case ServerEnvironment.production:
        return 'https://api.aic-app.com';
    }
  }
  
  static String _getWsUrl(ServerEnvironment env) {
    switch (env) {
      case ServerEnvironment.lanDev:
        // WebSocket: симулятор → ws://localhost, iPhone → ws://Mac IP
        return _isSimulator ? 'ws://127.0.0.1:3000' : 'ws://$_macLocalIP:3000';
      case ServerEnvironment.tunnelDev:
        return 'wss://subcuticular-latrisha-commemoratively.ngrok-free.dev';
      case ServerEnvironment.production:
        return 'wss://api.aic-app.com';
    }
  }
  
  static String getServerName(ServerEnvironment env) {
    switch (env) {
      case ServerEnvironment.lanDev:
        return _isSimulator ? 'LAN Dev (Simulator → localhost)' : 'LAN Dev (iPhone → Mac IP)';
      case ServerEnvironment.tunnelDev:
        return 'Tunnel Dev (ngrok)';
      case ServerEnvironment.production:
        return 'Production';
    }
  }
  
  static String getServerDescription(ServerEnvironment env) {
    switch (env) {
      case ServerEnvironment.lanDev:
        return _isSimulator 
          ? 'Симулятор подключается к 127.0.0.1:3000' 
          : 'iPhone подключается к Mac $_macLocalIP:3000';
      case ServerEnvironment.tunnelDev:
        return 'Все устройства через ngrok туннель';
      case ServerEnvironment.production:
        return 'Продакшн сервер';
    }
  }
  
  static String getServerUrl(ServerEnvironment env) {
    return _getBaseUrl(env);
  }
  
  static Map<String, String> getConfig(ServerEnvironment env) {
    return {
      'name': getServerName(env),
      'baseUrl': _getBaseUrl(env),
      'wsUrl': _getWsUrl(env),
      'description': getServerDescription(env),
    };
  }
  
  // Методы для переключения окружений
  static ServerEnvironment switchToLanDev() => ServerEnvironment.lanDev;
  static ServerEnvironment switchToTunnelDev() => ServerEnvironment.tunnelDev;
  
  // Debug информация
  static Map<String, dynamic> get debugInfo => {
    'isSimulator': _isSimulator,
    'macLocalIP': _macLocalIP,
    'currentEnvironment': currentEnvironment.name,
    'currentBaseUrl': baseUrl,
    'currentWsUrl': wsUrl,
    'deviceType': _isSimulator ? 'iOS Simulator' : 'Physical Device',
  };
}
