import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StreakState {
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastCheckin;
  final List<DateTime> checkinHistory;

  StreakState({
    required this.currentStreak,
    required this.longestStreak,
    this.lastCheckin,
    required this.checkinHistory,
  });

  StreakState copyWith({
    int? currentStreak,
    int? longestStreak,
    DateTime? lastCheckin,
    List<DateTime>? checkinHistory,
  }) {
    return StreakState(
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastCheckin: lastCheckin ?? this.lastCheckin,
      checkinHistory: checkinHistory ?? this.checkinHistory,
    );
  }

  bool get canCheckinToday {
    if (lastCheckin == null) return true;
    final today = DateTime.now();
    return !_isSameDay(lastCheckin!, today);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

final streakProvider = StateNotifierProvider<StreakNotifier, StreakState>((ref) {
  return StreakNotifier();
});

class StreakNotifier extends StateNotifier<StreakState> {
  StreakNotifier() : super(StreakState(
    currentStreak: 0,
    longestStreak: 0,
    checkinHistory: [],
  )) {
    _loadStreak();
  }

  Future<void> _loadStreak() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentStreak = prefs.getInt('current_streak') ?? 0;
      final longestStreak = prefs.getInt('longest_streak') ?? 0;
      final lastCheckinStr = prefs.getString('last_checkin');
      final historyStrs = prefs.getStringList('checkin_history') ?? [];

      final history = historyStrs
          .map((str) => DateTime.parse(str))
          .toList();

      state = StreakState(
        currentStreak: currentStreak,
        longestStreak: longestStreak,
        lastCheckin: lastCheckinStr != null ? DateTime.parse(lastCheckinStr) : null,
        checkinHistory: history,
      );
    } catch (e) {
      // Error loading streak, keep default state
    }
  }

  Future<void> checkin() async {
    if (!state.canCheckinToday) return;

    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));

    // Проверяем, был ли чекин вчера
    final wasYesterday = state.lastCheckin != null &&
        _isSameDay(state.lastCheckin!, yesterday);

    final newStreak = wasYesterday ? state.currentStreak + 1 : 1;
    final newLongest = newStreak > state.longestStreak ? newStreak : state.longestStreak;

    state = state.copyWith(
      currentStreak: newStreak,
      longestStreak: newLongest,
      lastCheckin: now,
      checkinHistory: [...state.checkinHistory, now],
    );

    await _saveStreak();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> _saveStreak() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('current_streak', state.currentStreak);
      await prefs.setInt('longest_streak', state.longestStreak);
      if (state.lastCheckin != null) {
        await prefs.setString('last_checkin', state.lastCheckin!.toIso8601String());
      }

      final historyStrs = state.checkinHistory
          .map((date) => date.toIso8601String())
          .toList();
      await prefs.setStringList('checkin_history', historyStrs);
    } catch (e) {
      // Error saving streak
    }
  }

  Future<void> resetStreak() async {
    state = state.copyWith(currentStreak: 0, lastCheckin: null);
    await _saveStreak();
  }
}