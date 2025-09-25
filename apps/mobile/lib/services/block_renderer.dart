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
      case 'support_contacts':
        return _SupportContactsBlock(data: blockData);
      case 'meditation_exercises':
        return _MeditationExercisesBlock(data: blockData);
      case 'tips_list':
        return _TipsListBlock(data: blockData);
      case 'info_card':
        return _InfoCardBlock(data: blockData);
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
    final gradient = (data['gradient'] as List<dynamic>?)
        ?.map((c) => Color(int.parse(c.toString().replaceFirst('#', '0xFF'))))
        .toList() ?? [Colors.blue, Colors.purple];

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
          Wrap(
            alignment: WrapAlignment.spaceAround,
            spacing: 8.0,
            runSpacing: 8.0,
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
    final actions = (data['actions'] as List<dynamic>?) ?? [];

    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              data['title'] ?? 'Untitled',
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
                onTap: () => context.go(action['route'] ?? '/'),
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
                        _getIconData(action['icon'] ?? 'help'),
                        size: 32,
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        action['label'] ?? action['title'] ?? 'Unnamed',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (action['subtitle'] != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          action['subtitle'],
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
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
    final categories = (data['categories'] as List<dynamic>?) ?? [];

    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (data['title'] != null) ...[
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
          ],
          GridView.builder(
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
                    category['title'] ?? 'Untitled',
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
        ],
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

class _SupportContactsBlock extends StatelessWidget {
  final Map<String, dynamic> data;

  const _SupportContactsBlock({required this.data});

  @override
  Widget build(BuildContext context) {
    final contacts = data['contacts'] as List<dynamic>;

    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data['title'] ?? 'Контакты',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ...contacts.map((contact) => Container(
            margin: const EdgeInsets.only(bottom: 12),
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
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.phone,
                    color: Colors.blue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contact['title'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        contact['phone'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      if (contact['description'] != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          contact['description'],
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

class _MeditationExercisesBlock extends StatelessWidget {
  final Map<String, dynamic> data;

  const _MeditationExercisesBlock({required this.data});

  @override
  Widget build(BuildContext context) {
    final exercises = data['exercises'] as List<dynamic>;

    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data['title'] ?? 'Упражнения',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ...exercises.map((exercise) => Container(
            margin: const EdgeInsets.only(bottom: 12),
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
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.self_improvement,
                    color: Colors.green,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise['title'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        exercise['description'],
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (exercise['duration'] != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Длительность: ${exercise['duration']}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

class _TipsListBlock extends StatelessWidget {
  final Map<String, dynamic> data;

  const _TipsListBlock({required this.data});

  @override
  Widget build(BuildContext context) {
    final tips = data['tips'] as List<dynamic>;

    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data['title'] ?? 'Советы',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ...tips.map((tip) => Container(
            margin: const EdgeInsets.only(bottom: 12),
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
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.lightbulb,
                    color: Colors.orange,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tip['title'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        tip['description'],
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

class _InfoCardBlock extends StatelessWidget {
  final Map<String, dynamic> data;

  const _InfoCardBlock({required this.data});

  @override
  Widget build(BuildContext context) {
    final color = data['color'] != null
        ? Color(int.parse(data['color'].toString().replaceFirst('#', '0xFF')))
        : Colors.blue;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (data['icon'] != null)
            Icon(
              _getIconForInfo(data['icon']),
              color: Colors.white,
              size: 32,
            ),
          if (data['icon'] != null) const SizedBox(height: 16),
          Text(
            data['title'],
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            data['description'],
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
              height: 1.4,
            ),
          ),
          if (data['items'] != null) ...[
            const SizedBox(height: 16),
            ...(data['items'] as List<dynamic>).map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }

  IconData _getIconForInfo(String iconName) {
    switch (iconName) {
      case 'info':
        return Icons.info_outline;
      case 'warning':
        return Icons.warning_outlined;
      case 'help':
        return Icons.help_outline;
      case 'tips':
        return Icons.lightbulb_outline;
      default:
        return Icons.info_outline;
    }
  }
}

// Provider для загрузки экранов из JSON
final screenDataProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, screenName) async {
  final jsonString = await rootBundle.loadString('assets/data/screens.json');
  final jsonData = json.decode(jsonString) as Map<String, dynamic>;
  return jsonData['screens'][screenName] as Map<String, dynamic>;
});