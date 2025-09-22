import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeDashboardPage extends StatefulWidget {
  const HomeDashboardPage({super.key});

  @override
  State<HomeDashboardPage> createState() => _HomeDashboardPageState();
}

class _HomeDashboardPageState extends State<HomeDashboardPage> {
  final List<_HomeSection> _sections = const [
    _HomeSection(
      title: 'Чат',
      description: 'Поговори с AIc о любом, что волнует прямо сейчас',
      icon: Icons.chat_bubble_outline_rounded,
      color: Color(0xFF6366F1),
      route: '/chat',
    ),
    _HomeSection(
      title: 'Ситуации',
      description: 'Разбери типичные жизненные ситуации',
      icon: Icons.psychology_outlined,
      color: Color(0xFF10B981),
      route: '/situations',
    ),
    _HomeSection(
      title: 'Мотивация',
      description: 'Найди вдохновение и цель на сегодня',
      icon: Icons.bolt_outlined,
      color: Color(0xFF22D3EE),
      route: '/motivation',
    ),
    _HomeSection(
      title: 'Медитация',
      description: 'Спокойные практики и дыхательные упражнения',
      icon: Icons.self_improvement_outlined,
      color: Color(0xFF34D399),
      route: '/meditation',
    ),
    _HomeSection(
      title: 'Советы',
      description: 'Полезные подсказки для школы, друзей и семьи',
      icon: Icons.lightbulb_outline_rounded,
      color: Color(0xFFFBBF24),
      route: '/tips',
    ),
    _HomeSection(
      title: 'Поддержка',
      description: 'Контакты, ресурсы и кризисные линии',
      icon: Icons.volunteer_activism_outlined,
      color: Color(0xFFFB7185),
      route: '/support',
    ),
    _HomeSection(
      title: 'Настройки',
      description: 'Персонализация, уведомления и аккаунт',
      icon: Icons.settings_outlined,
      color: Color(0xFFA78BFA),
      route: '/settings',
    ),
  ];

  String _userNick = '';
  bool _loadingUser = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final nick = prefs.getString('user_nick') ?? '';
    if (!mounted) return;
    setState(() {
      _userNick = nick;
      _loadingUser = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final greeting = _loadingUser
        ? 'Привет!'
        : (_userNick.isEmpty ? 'Привет!' : 'Привет, $_userNick!');

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F9),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: _buildHeader(theme, greeting),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final section = _sections[index];
                    return _HomeCard(
                      section: section,
                      onTap: () => context.go(section.route),
                    );
                  },
                  childCount: _sections.length,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.1,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
                child: _buildQuickActions(theme),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, String greeting) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withValues(alpha: 0.25),
            blurRadius: 30,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            greeting,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Я рядом, чтобы поддержать тебя. Выбери то, что сейчас важнее всего.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _TagChip(
                icon: Icons.favorite_rounded,
                label: 'Забота о себе',
              ),
              _TagChip(
                icon: Icons.psychology_alt_rounded,
                label: 'Осознанность',
              ),
              _TagChip(
                icon: Icons.color_lens_rounded,
                label: 'Настроение',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Быстрые действия',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 12),
        Column(
          children: [
            _QuickActionTile(
              icon: Icons.monitor_heart_rounded,
              title: 'Проверить настроение',
              description: 'Отметь, как ты себя чувствуешь прямо сейчас',
              color: const Color(0xFF22D3EE),
              onTap: () => context.go('/chat'),
            ),
            _QuickActionTile(
              icon: Icons.favorite_outline,
              title: '3 минуты дыхания',
              description: 'Получить короткую практику для успокоения',
              color: const Color(0xFF34D399),
              onTap: () => context.go('/meditation'),
            ),
            _QuickActionTile(
              icon: Icons.group_rounded,
              title: 'Найти поддержку',
              description: 'Контакты специалистов и горячие линии',
              color: const Color(0xFFFB7185),
              onTap: () => context.go('/support'),
            ),
          ],
        ),
      ],
    );
  }
}

class _HomeCard extends StatelessWidget {
  const _HomeCard({required this.section, required this.onTap});

  final _HomeSection section;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [
              section.color.withValues(alpha: 0.65),
              section.color.withValues(alpha: 0.95),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: section.color.withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(section.icon, size: 28, color: Colors.white),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  section.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  section.description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                        height: 1.2,
                        fontSize: 11,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeSection {
  const _HomeSection({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.route,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final String route;
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: Colors.white.withValues(alpha: 0.16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          description,
          style: TextStyle(color: Theme.of(context).colorScheme.outline),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }
}
