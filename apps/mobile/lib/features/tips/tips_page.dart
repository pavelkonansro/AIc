import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TipsPage extends StatefulWidget {
  const TipsPage({super.key});

  @override
  State<TipsPage> createState() => _TipsPageState();
}

class _TipsPageState extends State<TipsPage> {
  final List<_TipCategory> _categories = [
    _TipCategory(
      title: 'Учёба',
      icon: Icons.school_rounded,
      color: const Color(0xFF60A5FA),
      tips: const [
        'Разбей крупные задачи на маленькие шаги. Это даёт ощущение прогресса.',
        'Составь «учебное гнездо»: место, где ты занимаешься только учебой.',
        'Используй правило 25/5: 25 минут занятий и 5 минут отдыха.',
      ],
    ),
    _TipCategory(
      title: 'Друзья и общение',
      icon: Icons.people_alt_rounded,
      color: const Color(0xFF34D399),
      tips: const [
        'Говори о своих чувствах, используя фразы «я чувствую…» вместо обвинений.',
        'Если разговор заходит в тупик — сделай паузу и вернись к нему позже.',
        'Настоящие друзья принимают «нет» и твои границы. Это нормально.',
      ],
    ),
    _TipCategory(
      title: 'Семья',
      icon: Icons.home_rounded,
      color: const Color(0xFFF97316),
      tips: const [
        'Выбирай спокойный момент, чтобы обсудить важные темы с родителями.',
        'Подготовь пример, чтобы объяснить, как ты себя чувствуешь.',
        'Если сложно говорить вслух — напиши письмо или сообщение.',
      ],
    ),
    _TipCategory(
      title: 'Самочувствие',
      icon: Icons.favorite_rounded,
      color: const Color(0xFFA855F7),
      tips: const [
        'Отслеживай сон, воду и движение: это база, на которой держится настроение.',
        'Дыши глубоко, когда чувствуешь стресс: 4 секунды вдох, 4 пауза, 6 выдох.',
        'Записывай мысли: когда они на бумаге, их проще понять и отпустить.',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Советы'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          Text(
            'Полезные подборки',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Выбирай ситуацию, и я подскажу, как можно действовать.',
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
                  icon: Icons.favorite_outline,
                  label: 'Поддержка',
                  route: '/support'),
              _NavDestination(
                  icon: Icons.settings, label: 'Настройки', route: '/settings'),
            ],
          ),
          const SizedBox(height: 20),
          ..._categories.map((category) => _TipsExpansion(category: category)),
        ],
      ),
    );
  }
}

class _TipsExpansion extends StatefulWidget {
  const _TipsExpansion({required this.category});

  final _TipCategory category;

  @override
  State<_TipsExpansion> createState() => _TipsExpansionState();
}

class _TipsExpansionState extends State<_TipsExpansion> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: widget.category.color.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: _expanded,
          onExpansionChanged: (value) => setState(() => _expanded = value),
          leading: CircleAvatar(
            backgroundColor: widget.category.color.withValues(alpha: 0.15),
            child: Icon(widget.category.icon, color: widget.category.color),
          ),
          iconColor: widget.category.color,
          collapsedIconColor: widget.category.color,
          title: Text(
            widget.category.title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          children: widget.category.tips
              .map(
                (tip) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.check_circle,
                          size: 18, color: widget.category.color),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          tip,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      )
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _TipCategory {
  const _TipCategory({
    required this.title,
    required this.icon,
    required this.color,
    required this.tips,
  });

  final String title;
  final IconData icon;
  final Color color;
  final List<String> tips;
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
