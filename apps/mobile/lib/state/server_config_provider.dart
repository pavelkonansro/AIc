import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

// Провайдер для выбора сервера
final serverConfigProvider = StateNotifierProvider<ServerConfigNotifier, ServerEnvironment>((ref) {
  return ServerConfigNotifier();
});

class ServerConfigNotifier extends StateNotifier<ServerEnvironment> {
  ServerConfigNotifier() : super(ServerEnvironment.lanDev) {
    _initializeServerConfig();
  }

  Future<void> _initializeServerConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedServer = prefs.getString('server_environment');

      if (savedServer != null) {
        final serverEnv = ServerEnvironment.values.firstWhere(
          (env) => env.name == savedServer,
          orElse: () => ServerEnvironment.lanDev,
        );
        state = serverEnv;
      } else {
        // По умолчанию - LAN Dev режим
        state = ServerEnvironment.lanDev;
      }
    } catch (e) {
      // В случае ошибки используем LAN Dev
      state = ServerEnvironment.lanDev;
    }
  }

  Future<void> changeServer(ServerEnvironment newServer) async {
    state = newServer;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('server_environment', newServer.name);
    } catch (e) {
      // Игнорируем ошибки сохранения
    }
  }
}

// Провайдер для получения текущих URL серверов
final currentApiConfigProvider = Provider<Map<String, String>>((ref) {
  final currentServer = ref.watch(serverConfigProvider);
  return ApiConfig.getConfig(currentServer);
});

// Провайдер для получения debug информации
final debugInfoProvider = Provider<Map<String, dynamic>>((ref) {
  return ApiConfig.debugInfo;
});