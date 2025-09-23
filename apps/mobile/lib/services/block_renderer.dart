import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../state/mood_provider.dart';
import '../state/streak_provider.dart';

class BlockRenderer extends ConsumerWidget {
  final Map<String, dynamic> blockData;

  const BlockRenderer({
    super.key,
    required this.blockData,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final type = blockData['type'] as String;

    switch (type) {
      case 'hero_card':
        return _HeroCardBlock(data: blockData);
      case 'mood_selector':
        return _MoodSelectorBlock(data: blockData);
      case 'streak_card':
        return _StreakCardBlock(data: blockData);
      case 'quick_actions':
        return _QuickActionsBlock(data: blockData);
      case 'category_grid':
        return _CategoryGridBlock(data: blockData);
      default:
        return Container(
          padding: const EdgeInsets.all(16),
          child: Text('Unknown block type: $type'),
        );
    }
  }
}

class _HeroCardBlock extends StatelessWidget {
  final Map<String, dynamic> data;

  const _HeroCardBlock({required this.data});

  @override
  Widget build(BuildContext context) {
    final gradient = (data['gradient'] as List<dynamic>)
        .map((c) => Color(int.parse(c.toString().replaceFirst('#', '0xFF'))))
        .toList();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data['title'],
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            data['subtitle'],
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _MoodSelectorBlock extends ConsumerWidget {
  final Map<String, dynamic> data;

  const _MoodSelectorBlock({required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moodState = ref.watch(moodProvider);
    final moods = data['moods'] as List<dynamic>;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data['title'],
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: moods.map((mood) {
              final moodType = MoodType.values.firstWhere(
                (m) => m.name == mood['value'],
                orElse: () => MoodType.neutral,
              );
              final isSelected = moodState.currentMood == moodType;

              return GestureDetector(
                onTap: () => ref.read(moodProvider.notifier).updateMood(moodType),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue.withValues(alpha: 0.1) : null,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        mood['emoji'],
                        style: const TextStyle(fontSize: 32),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        mood['label'],
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected ? Colors.blue : Colors.grey,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _StreakCardBlock extends ConsumerWidget {
  final Map<String, dynamic> data;

  const _StreakCardBlock({required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streakState = ref.watch(streakProvider);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['title'],
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data['subtitle'],
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      '${streakState.currentStreak}',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'дней',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              if (streakState.canCheckinToday)
                ElevatedButton(
                  onPressed: () => ref.read(streakProvider.notifier).checkin(),
                  child: const Text('Отметиться'),
                )
              else
                const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 32,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionsBlock extends StatelessWidget {
  final Map<String, dynamic> data;

  const _QuickActionsBlock({required this.data});

  @override
  Widget build(BuildContext context) {
    final actions = data['actions'] as List<dynamic>;

    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              data['title'],
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
            ),
            itemCount: actions.length,
            itemBuilder: (context, index) {
              final action = actions[index];
              return GestureDetector(
                onTap: () => context.go(action['route']),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _getIconData(action['icon']),
                        size: 32,
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        action['label'],
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'chat':
        return Icons.chat;
      case 'meditation':
        return Icons.self_improvement;
      case 'tips':
        return Icons.lightbulb;
      case 'support':
        return Icons.support_agent;
      default:
        return Icons.help;
    }
  }
}

class _CategoryGridBlock extends StatelessWidget {
  final Map<String, dynamic> data;

  const _CategoryGridBlock({required this.data});

  @override
  Widget build(BuildContext context) {
    final categories = data['categories'] as List<dynamic>;

    return Container(
      margin: const EdgeInsets.all(16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.0,
        ),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final color = Color(int.parse(
              category['color'].toString().replaceFirst('#', '0xFF')));

          return GestureDetector(
            onTap: () {
              context.go('/situations/${category['id']}', extra: category);
            },
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _getIconData(category['icon']),
                    size: 40,
                    color: color,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    category['title'],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'school':
        return Icons.school;
      case 'people':
        return Icons.people;
      case 'home':
        return Icons.home;
      default:
        return Icons.category;
    }
  }
}

// Provider для загрузки экранов из JSON
final screenDataProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, screenName) async {
  final jsonString = await rootBundle.loadString('assets/data/screens.json');
  final jsonData = json.decode(jsonString) as Map<String, dynamic>;
  return jsonData['screens'][screenName] as Map<String, dynamic>;
});