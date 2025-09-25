import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import 'dart:convert';
import '../models/chat_provider.dart';

/// Провайдер для управления настройками чата
class ChatSettingsNotifier extends StateNotifier<ChatProviderConfig> {
  static const String _storageKey = 'chat_provider_config';
  final Logger _logger = Logger();

  ChatSettingsNotifier() : super(ChatProviderConfig.grok()) {
    _loadSettings();
  }

  /// Загрузить настройки из локального хранилища
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);
      
      if (jsonString != null) {
        final json = jsonDecode(jsonString) as Map<String, dynamic>;
        state = ChatProviderConfig.fromJson(json);
      }
    } catch (e) {
      // В случае ошибки используем настройки по умолчанию
      state = ChatProviderConfig.grok();
    }
  }

  /// Сохранить настройки в локальное хранилище
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(state.toJson());
      await prefs.setString(_storageKey, jsonString);
    } catch (e) {
      // Игнорируем ошибки сохранения
    }
  }

  /// Инициализация провайдера (для совместимости с тестами)
  Future<void> initialize() async {
    await _loadSettings();
  }

  /// Сменить провайдера чата
  Future<void> setProvider(ChatProviderType type) async {
    state = ChatProviderConfig.getDefault(type);
    await _saveSettings();
  }

  /// Сменить провайдера чата (альтернативный метод для тестов)
  Future<void> switchProvider(ChatProviderType type) async {
    await setProvider(type);
  }

  /// Обновить конфигурацию провайдера
  Future<void> updateConfig(ChatProviderConfig config) async {
    state = config;
    await _saveSettings();
  }

  /// Обновить API ключ (оставлено для совместимости)
  Future<void> updateApiKey(String apiKey) async {
    // В новой модели API ключ не изменяется
    _logger.w('updateApiKey вызван, но в новой модели API ключ фиксированный');
  }

  /// Обновить настройки (оставлено для совместимости)
  Future<void> updateSettings(Map<String, dynamic> settings) async {
    // В новой модели настройки не изменяются
    _logger.w('updateSettings вызван, но в новой модели настройки фиксированные');
  }

  /// Сбросить к настройкам по умолчанию
  Future<void> resetToDefault() async {
    state = ChatProviderConfig.getDefault(state.type);
    await _saveSettings();
  }
}

/// Провайдер настроек чата
final chatSettingsProvider = StateNotifierProvider<ChatSettingsNotifier, ChatProviderConfig>(
  (ref) => ChatSettingsNotifier(),
);

/// Провайдер для получения конфигурации провайдера
final chatProviderConfigProvider = Provider<ChatProviderConfig>((ref) {
  return ref.watch(chatSettingsProvider);
});

/// Провайдер для получения текущего типа провайдера
final currentChatProviderProvider = Provider<ChatProviderType>((ref) {
  final config = ref.watch(chatSettingsProvider);
  return config.type;
});

/// Провайдер для проверки, используется ли mock провайдер
final isMockProviderProvider = Provider<bool>((ref) {
  final type = ref.watch(currentChatProviderProvider);
  return type == ChatProviderType.mock;
});

/// Провайдер для проверки, используется ли Grok провайдер
final isGrokProviderProvider = Provider<bool>((ref) {
  final type = ref.watch(currentChatProviderProvider);
  return type == ChatProviderType.grok;
});

/// Legacy провайдеры для совместимости
final isMockChatProvider = isMockProviderProvider;
final isGrokChatProvider = isGrokProviderProvider;