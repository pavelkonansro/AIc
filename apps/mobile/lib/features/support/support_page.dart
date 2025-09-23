import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../components/navigation/navigation.dart';

class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final contacts = [
      _SupportContact(
        title: 'Европейский экстренный номер',
        phone: '112',
        description: 'Если ты или кто-то рядом в опасности — звони немедленно.',
        color: const Color(0xFFEF4444),
        icon: Icons.emergency_share,
      ),
      _SupportContact(
        title: 'Детский телефон доверия',
        phone: '116 111',
        description: 'Бесплатные анонимные разговоры с психологами 24/7.',
        color: const Color(0xFF3B82F6),
        icon: Icons.support_agent,
      ),
      _SupportContact(
        title: 'Кризисный центр',
        phone: '800 123 456',
        description: 'Помощь при эмоциональных кризисах, есть чат и email.',
        color: const Color(0xFF22C55E),
        icon: Icons.health_and_safety,
      ),
    ];

    return AicMainScaffold(
      title: 'Поддержка',
      currentRoute: '/support',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF97316), Color(0xFFFB7185)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFB7185).withValues(alpha: 0.3),
                  blurRadius: 22,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Важно помнить',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                _SupportReminder(text: 'Ты не обязан справляться в одиночку.'),
                _SupportReminder(text: 'Просить о помощи — это сильный шаг.'),
                _SupportReminder(
                    text:
                        'Если страшно говорить лично, начни с телефонного звонка или чата.'),
              ],
            ),
          ),
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
                  icon: Icons.self_improvement,
                  label: 'Медитации',
                  route: '/meditation'),
              _NavDestination(
                  icon: Icons.lightbulb_outline,
                  label: 'Советы',
                  route: '/tips'),
              _NavDestination(
                  icon: Icons.settings, label: 'Настройки', route: '/settings'),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Контакты, которым можно доверять',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          ...contacts.map((contact) => _ContactCard(contact: contact)),
          const SizedBox(height: 24),
          Text(
            'Ресурсы',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          _ResourceTile(
            title: 'Подготовься к разговору',
            description:
                'Запиши основные мысли и эмоции, чтобы легче было сказать их взрослому.',
            icon: Icons.notes_rounded,
          ),
          _ResourceTile(
            title: 'Дыхание перед звонком',
            description:
                'Сделай 5 глубоких вдохов и выдохов, чтобы голос звучал увереннее.',
            icon: Icons.air_rounded,
          ),
          _ResourceTile(
            title: 'Если не ответили сразу',
            description:
                'Позвони ещё раз или напиши сообщение. Иногда линия загружена, но это не повод сдаватьcя.',
            icon: Icons.sms_rounded,
          ),
        ],
      ),
    );
  }
}

class _SupportContact {
  const _SupportContact({
    required this.title,
    required this.phone,
    required this.description,
    required this.color,
    required this.icon,
  });

  final String title;
  final String phone;
  final String description;
  final Color color;
  final IconData icon;
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({required this.contact});

  final _SupportContact contact;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: contact.color.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ListTile(
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: contact.color.withValues(alpha: 0.14),
          child: Icon(contact.icon, color: contact.color, size: 28),
        ),
        title: Text(
          contact.title,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                contact.phone,
                style: TextStyle(
                  color: contact.color,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                contact.description,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(height: 1.4),
              ),
            ],
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.call),
          color: contact.color,
          onPressed: () => _makePhoneCall(contact.phone),
        ),
        onTap: () => _makePhoneCall(contact.phone),
      ),
    );
  }

  Future<void> _makePhoneCall(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone.replaceAll(' ', ''));
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}

class _SupportReminder extends StatelessWidget {
  const _SupportReminder({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResourceTile extends StatelessWidget {
  const _ResourceTile(
      {required this.title, required this.description, required this.icon});

  final String title;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(height: 1.35),
                ),
              ],
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
