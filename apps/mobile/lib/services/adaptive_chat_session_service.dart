import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/api_config.dart';
import '../services/logger.dart';
import '../state/server_config_provider.dart';
import '../state/app_state.dart';
import 'chat_session_service.dart';
import 'local_chat_session_service.dart';
import 'remote_chat_session_service.dart';

/// Адаптивный сервис чат-сессий с автоматическим fallback
/// Выбирает оптимальную реализацию в зависимости от конфигурации и доступности
class AdaptiveChatSessionService implements ChatSessionService {
  final ProviderRef ref;
  late final ChatSessionService _localService;
  late final ChatSessionService _remoteService;
  
  // Кэшируем результат проверки доступности сервера
  bool? _serverAvailable;
  DateTime? _lastCheck;
  static const Duration _checkCooldown = Duration(minutes: 1);

  AdaptiveChatSessionService(this.ref) {
    _localService = LocalChatSessionService();
    _remoteService = RemoteChatSessionService(ref);
  }

  @override
  String get serviceType => 'Adaptive (${_currentService.serviceType})';

  /// Получает текущий активный сервис
  ChatSessionService get _currentService {
    final environment = ref.read(serverConfigProvider);
    
    // Для LAN Dev среды всегда используем локальный сервис
    if (environment == ServerEnvironment.lanDev) {
      return _localService;
    }
    
    // Для удаленных сред проверяем доступность
    return _remoteService;
  }

  /// Проверяет доступность удаленного сервера с кэшированием
  Future<bool> _isRemoteServerAvailable() async {
    final now = DateTime.now();
    
    // Используем кэшированный результат если проверка была недавно
    if (_serverAvailable != null && 
        _lastCheck != null && 
        now.difference(_lastCheck!) < _checkCooldown) {
      return _serverAvailable!;
    }
    
    // Проверяем доступность сервера
    _serverAvailable = await _remoteService.isAvailable();
    _lastCheck = now;
    
    return _serverAvailable!;
  }

  /// Выполняет операцию с автоматическим fallback на локальный сервис
  Future<T> _executeWithFallback<T>(
    Future<T> Function(ChatSessionService service) operation,
    {T? fallbackValue}
  ) async {
    final environment = ref.read(serverConfigProvider);
    
    // Для LAN Dev среды используем только локальный сервис
    if (environment == ServerEnvironment.lanDev) {
      AppLogger.d('[Adaptive] Используем локальный сервис (среда: LAN Dev)');
      return await operation(_localService);
    }
    
    try {
      // Пробуем удаленный сервис
      if (await _isRemoteServerAvailable()) {
        AppLogger.d('[Adaptive] Используем удаленный сервис');
        return await operation(_remoteService);
      } else {
        throw Exception('Remote server unavailable');
      }
    } catch (e) {
      AppLogger.w('[Adaptive] Удаленный сервис недоступен, переключаемся на локальный: $e');
      
      try {
        // Fallback на локальный сервис
        final result = await operation(_localService);
        AppLogger.i('[Adaptive] Успешно использован fallback на локальный сервис');
        return result;
      } catch (localError) {
        AppLogger.e('[Adaptive] Ошибка локального сервиса: $localError');
        if (fallbackValue != null) {
          return fallbackValue;
        }
        rethrow;
      }
    }
  }

  @override
  Future<ChatSession> createSession(String userId) async {
    AppLogger.i('[Adaptive] Создаем сессию для пользователя: $userId');
    return await _executeWithFallback((service) => service.createSession(userId));
  }

  @override
  Future<ChatSession?> getSession(String sessionId) async {
    AppLogger.d('[Adaptive] Получаем сессию: $sessionId');
    return await _executeWithFallback(
      (service) => service.getSession(sessionId),
      fallbackValue: null,
    );
  }

  @override
  Future<List<ChatSession>> getUserSessions(String userId) async {
    AppLogger.d('[Adaptive] Получаем сессии пользователя: $userId');
    return await _executeWithFallback(
      (service) => service.getUserSessions(userId),
      fallbackValue: <ChatSession>[],
    );
  }

  @override
  Future<ChatMessage> addMessage(String sessionId, ChatMessage message) async {
    AppLogger.d('[Adaptive] Добавляем сообщение в сессию: $sessionId');
    return await _executeWithFallback(
      (service) => service.addMessage(sessionId, message),
    );
  }

  @override
  Future<void> endSession(String sessionId) async {
    AppLogger.i('[Adaptive] Завершаем сессию: $sessionId');
    await _executeWithFallback(
      (service) => service.endSession(sessionId),
      fallbackValue: null,
    );
  }

  @override
  Future<bool> isAvailable() async {
    final environment = ref.read(serverConfigProvider);
    
    if (environment == ServerEnvironment.lanDev) {
      return await _localService.isAvailable();
    }
    
    // Для удаленных сред проверяем оба сервиса
    final remoteAvailable = await _remoteService.isAvailable();
    final localAvailable = await _localService.isAvailable();
    
    // Считается доступным если хотя бы один сервис работает
    return remoteAvailable || localAvailable;
  }

  /// Принудительная очистка кэша проверки сервера
  void clearServerCheckCache() {
    _serverAvailable = null;
    _lastCheck = null;
    AppLogger.d('[Adaptive] Кэш проверки сервера очищен');
  }

  /// Получает информацию о состоянии сервисов
  Future<Map<String, dynamic>> getServicesStatus() async {
    final environment = ref.read(serverConfigProvider);
    final localAvailable = await _localService.isAvailable();
    final remoteAvailable = await _remoteService.isAvailable();
    
    return {
      'environment': environment.name,
      'currentService': _currentService.serviceType,
      'localService': {
        'available': localAvailable,
        'type': _localService.serviceType,
      },
      'remoteService': {
        'available': remoteAvailable,
        'type': _remoteService.serviceType,
        'url': ref.read(currentApiConfigProvider)['baseUrl'],
      },
    };
  }
}