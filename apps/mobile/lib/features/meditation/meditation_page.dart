import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../components/navigation/navigation.dart';

class MeditationPage extends StatelessWidget {
  const MeditationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final sessions = [
      _MeditationSession(
        title: 'Дыхание 4-6',
        description:
            'Медленный вдох на 4 счета и выдох на 6. Помогает снизить тревогу и вернуть контроль над дыханием.',
        duration: '3 минуты',
        color: const Color(0xFF60A5FA),
      ),
      _MeditationSession(
        title: 'Сканирование тела',
        description:
            'Спокойно пройди вниманием от макушки до стоп, замечая ощущения без оценок.',
        duration: '7 минут',
        color: const Color(0xFF34D399),
      ),
      _MeditationSession(
        title: 'Мягкая визуализация',
        description:
            'Представь место, где тебе спокойно. Дополни картинку звуками, запахами и ощущениями.',
        duration: '5 минут',
        color: const Color(0xFFF59E0B),
      ),
    ];

    final quickTips = [
      'Используй технику «квадратного дыхания»: вдох — задержка — выдох — задержка по 4 счета.',
      'Положи руку на живот и убедись, что дыхание идёт глубоко в диафрагму.',
      'Сфокусируйся на трёх вещах, которые видишь; двух, которые слышишь; одной, которую чувствуешь.',
    ];

    return AicMainScaffold(
      title: 'Медитация',
      currentRoute: '/meditation',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          _ActiveSessionBanner(onStart: () {}),
          const SizedBox(height: 24),
          _NavigationWrap(
            items: const [
              _NavDestination(
                  icon: Icons.home_rounded, label: 'Домой', route: '/home'),
              _NavDestination(
                  icon: Icons.chat_bubble_rounded,
                  label: 'Чат',
                  route: '/chat'),
              _NavDestination(
                  icon: Icons.bolt, label: 'Мотивация', route: '/motivation'),
              _NavDestination(
                  icon: Icons.lightbulb_outline,
                  label: 'Советы',
                  route: '/tips'),
              _NavDestination(
                  icon: Icons.settings, label: 'Настройки', route: '/settings'),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Короткие практики',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          ...sessions.map((session) => _MeditationCard(session: session)),
          const SizedBox(height: 24),
          Text(
            'Советы',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          ...quickTips.map(
            (tip) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(fontSize: 20, height: 1.4)),
                  Expanded(
                    child: Text(
                      tip,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveSessionBanner extends StatelessWidget {
  const _ActiveSessionBanner({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF818CF8), Color(0xFFA855F7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFA855F7).withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 14),
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
                  '3 минуты для спокойствия',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Сядь поудобнее, закрой глаза и позволь себе просто дышать вместе с AIc.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: onStart,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.deepPurple,
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Начать сейчас'),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          const Icon(Icons.self_improvement, color: Colors.white, size: 48),
        ],
      ),
    );
  }
}

class _MeditationSession {
  const _MeditationSession({
    required this.title,
    required this.description,
    required this.duration,
    required this.color,
  });

  final String title;
  final String description;
  final String duration;
  final Color color;
}

class _MeditationCard extends StatelessWidget {
  const _MeditationCard({required this.session});

  final _MeditationSession session;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: session.color.withValues(alpha: 0.16),
                child: Icon(Icons.timer_rounded, color: session.color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.title,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      session.duration,
                      style: TextStyle(
                          color: session.color, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.play_circle_fill_rounded, size: 32),
                color: session.color,
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            session.description,
            style:
                Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.35),
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
