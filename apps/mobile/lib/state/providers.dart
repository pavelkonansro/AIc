import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/api_client.dart';
import '../services/logger.dart';
import 'app_state.dart';

// API Client provider
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

// User state provider
final userProvider = StateNotifierProvider<UserNotifier, User?>((ref) {
  return UserNotifier();
});

class UserNotifier extends StateNotifier<User?> {
  UserNotifier() : super(null) {
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final box = await Hive.openBox('user');
      final userData = box.get('current_user');
      if (userData != null) {
        state = User.fromJson(Map<String, dynamic>.from(userData));
      }
    } catch (e) {
      AppLogger.e('Ошибка загрузки пользователя: $e');
    }
  }

  Future<void> setUser(User user) async {
    state = user;
    try {
      final box = await Hive.openBox('user');
      await box.put('current_user', user.toJson());
    } catch (e) {
      AppLogger.e('Ошибка сохранения пользователя: $e');
    }
  }

  Future<void> logout() async {
    state = null;
    try {
      final box = await Hive.openBox('user');
      await box.delete('current_user');
    } catch (e) {
      AppLogger.e('Ошибка при выходе: $e');
    }
  }
}

// Current chat session provider
final currentChatSessionProvider =
    StateNotifierProvider<ChatSessionNotifier, ChatSession?>((ref) {
  return ChatSessionNotifier();
});

class ChatSessionNotifier extends StateNotifier<ChatSession?> {
  ChatSessionNotifier() : super(null);

  void setSession(ChatSession session) {
    state = session;
  }

  void addMessage(ChatMessage message) {
    if (state != null) {
      final updatedMessages = [...state!.messages, message];
      state = ChatSession(
        id: state!.id,
        userId: state!.userId,
        startedAt: state!.startedAt,
        status: state!.status,
        messages: updatedMessages,
      );
    }
  }

  void clearSession() {
    state = null;
  }
}

// App settings provider
final appSettingsProvider =
    StateNotifierProvider<AppSettingsNotifier, AppSettings>((ref) {
  return AppSettingsNotifier();
});

class AppSettingsNotifier extends StateNotifier<AppSettings> {
  AppSettingsNotifier() : super(AppSettings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final box = await Hive.openBox('settings');
      final themeIndex = box.get('theme', defaultValue: AppTheme.system.index);
      final notificationsEnabled =
          box.get('notificationsEnabled', defaultValue: true);
      final dailyRemindersEnabled =
          box.get('dailyRemindersEnabled', defaultValue: false);
      final reminderHour = box.get('reminderHour', defaultValue: 20);
      final reminderMinute = box.get('reminderMinute', defaultValue: 0);

      state = AppSettings(
        theme: AppTheme.values[themeIndex],
        notificationsEnabled: notificationsEnabled,
        dailyRemindersEnabled: dailyRemindersEnabled,
        reminderHour: reminderHour,
        reminderMinute: reminderMinute,
      );
    } catch (e) {
      AppLogger.e('Ошибка загрузки настроек: $e');
    }
  }

  Future<void> updateSettings(AppSettings settings) async {
    state = settings;
    try {
      final box = await Hive.openBox('settings');
      await box.put('theme', settings.theme.index);
      await box.put('notificationsEnabled', settings.notificationsEnabled);
      await box.put('dailyRemindersEnabled', settings.dailyRemindersEnabled);
      await box.put('reminderHour', settings.reminderHour);
      await box.put('reminderMinute', settings.reminderMinute);
    } catch (e) {
      AppLogger.e('Ошибка сохранения настроек: $e');
    }
  }
}

// SOS contacts provider
final sosContactsProvider =
    FutureProvider.family<List<SosContact>, String>((ref, country) async {
  final apiClient = ref.read(apiClientProvider);
  try {
    final contacts = await apiClient.getSosContacts(country: country);
    return contacts.map((c) => SosContact.fromJson(c)).toList();
  } catch (e) {
    AppLogger.e('Ошибка загрузки SOS контактов: $e');
    return [];
  }
});

// Loading state provider
final loadingProvider = StateProvider<bool>((ref) => false);
