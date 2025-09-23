import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum MoodType { great, good, neutral, bad, terrible }

class MoodState {
  final MoodType currentMood;
  final DateTime lastUpdated;
  final List<MoodEntry> history;

  MoodState({
    required this.currentMood,
    required this.lastUpdated,
    required this.history,
  });

  MoodState copyWith({
    MoodType? currentMood,
    DateTime? lastUpdated,
    List<MoodEntry>? history,
  }) {
    return MoodState(
      currentMood: currentMood ?? this.currentMood,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      history: history ?? this.history,
    );
  }
}

class MoodEntry {
  final MoodType mood;
  final DateTime date;
  final String? note;

  MoodEntry({required this.mood, required this.date, this.note});

  Map<String, dynamic> toJson() => {
    'mood': mood.index,
    'date': date.toIso8601String(),
    'note': note,
  };

  factory MoodEntry.fromJson(Map<String, dynamic> json) => MoodEntry(
    mood: MoodType.values[json['mood']],
    date: DateTime.parse(json['date']),
    note: json['note'],
  );
}

final moodProvider = StateNotifierProvider<MoodNotifier, MoodState>((ref) {
  return MoodNotifier();
});

class MoodNotifier extends StateNotifier<MoodState> {
  MoodNotifier() : super(MoodState(
    currentMood: MoodType.neutral,
    lastUpdated: DateTime.now(),
    history: [],
  )) {
    _loadMood();
  }

  Future<void> _loadMood() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final moodIndex = prefs.getInt('current_mood') ?? MoodType.neutral.index;
      final lastUpdatedStr = prefs.getString('mood_last_updated');
      final historyJson = prefs.getStringList('mood_history') ?? [];

      final history = historyJson
          .map((json) => MoodEntry.fromJson(Map<String, dynamic>.from(
              jsonDecode(json))))
          .toList();

      state = MoodState(
        currentMood: MoodType.values[moodIndex],
        lastUpdated: lastUpdatedStr != null
            ? DateTime.parse(lastUpdatedStr)
            : DateTime.now(),
        history: history,
      );
    } catch (e) {
      // Error loading mood, keep default state
    }
  }

  Future<void> updateMood(MoodType mood, {String? note}) async {
    final entry = MoodEntry(mood: mood, date: DateTime.now(), note: note);
    final updatedHistory = [...state.history, entry];

    state = state.copyWith(
      currentMood: mood,
      lastUpdated: DateTime.now(),
      history: updatedHistory,
    );

    await _saveMood();
  }

  Future<void> _saveMood() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('current_mood', state.currentMood.index);
      await prefs.setString('mood_last_updated', state.lastUpdated.toIso8601String());

      final historyJson = state.history
          .map((entry) => jsonEncode(entry.toJson()))
          .toList();
      await prefs.setStringList('mood_history', historyJson);
    } catch (e) {
      // Error saving mood
    }
  }
}