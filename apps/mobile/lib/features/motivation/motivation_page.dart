import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MotivationPage extends StatelessWidget {
  const MotivationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final highlights = [
      _MotivationCardData(
        title: 'Сегодня ты уже справился',
        subtitle:
            'Вспомни хотя бы одну вещь, которая получилась сегодня. Даже маленькая победа — уже повод для гордости.',
        gradient: const [Color(0xFF60A5FA), Color(0xFFA78BFA)],
        emoji: '✨',
      ),
      _MotivationCardData(
        title: 'Не сравнивай',
        subtitle:
            'Твоя история уникальна. Делай шаги в своём темпе, сравнивай себя только с вчерашним собой.',
        gradient: const [Color(0xFF34D399), Color(0xFF10B981)],
        emoji: '🌱',
      ),
      _MotivationCardData(
        title: 'Спрашивать о помощи нормально',
        subtitle:
            'Смелость — это признавать свои чувства и искать поддержку, когда она нужна.',
        gradient: const [Color(0xFFF97316), Color(0xFFFCD34D)],
        emoji: '🤝',
      ),
    ];

    final ideas = [
      'Напиши три вещи, за которые ты благодарен сегодня.',
      'Сделай короткую растяжку или прогуляйся 5 минут, чтобы перезагрузить голову.',
      'Улыбнись себе в зеркале и скажи вслух: «У меня получится».',
      'Напиши сообщение человеку, с которым давно хотел поговорить.',
      'Составь мини-план на завтра из двух простых пунктов.',
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Мотивация'),
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF9FAFB), Color(0xFFF1F5F9)],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            Text(
              'Выбери заряд на день',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Пусть эти идеи помогут почувствовать поддержку и уверенность.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            _NavigationWrap(
              items: const [
                _NavDestination(
                    icon: Icons.home_rounded, label: 'Домой', route: '/home'),
                _NavDestination(
                    icon: Icons.chat_bubble_rounded,
                    label: 'Чат',
                    route: '/chat'),
                _NavDestination(
                    icon: Icons.self_improvement,
                    label: 'Медитации',
                    route: '/meditation'),
                _NavDestination(
                    icon: Icons.lightbulb_outline,
                    label: 'Советы',
                    route: '/tips'),
                _NavDestination(
                    icon: Icons.settings,
                    label: 'Настройки',
                    route: '/settings'),
              ],
            ),
            const SizedBox(height: 20),
            ...highlights.map((card) => _MotivationCard(data: card)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('💡', style: TextStyle(fontSize: 24)),
                      const SizedBox(width: 8),
                      Text(
                        'Идеи на сегодня',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...ideas.map(
                    (idea) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 8),
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              idea,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MotivationCardData {
  const _MotivationCardData({
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.emoji,
  });

  final String title;
  final String subtitle;
  final List<Color> gradient;
  final String emoji;
}

class _MotivationCard extends StatelessWidget {
  const _MotivationCard({required this.data});

  final _MotivationCardData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: data.gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: data.gradient.last.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(data.emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(height: 16),
          Text(
            data.title,
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            data.subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.92),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavigationWrap extends StatelessWidget {
  const _NavigationWrap({required this.items});

  final List<_NavDestination> items;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: items
          .map(
            (item) => ActionChip(
              avatar: Icon(item.icon, size: 16),
              label: Text(item.label),
              onPressed: () => context.go(item.route),
            ),
          )
          .toList(),
    );
  }
}

class _NavDestination {
  const _NavDestination({
    required this.icon,
    required this.label,
    required this.route,
  });

  final IconData icon;
  final String label;
  final String route;
}
