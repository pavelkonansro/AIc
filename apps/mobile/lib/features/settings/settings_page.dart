import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _dailyReminderEnabled = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 20, minute: 0);

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('pref_notifications') ?? true;
      _dailyReminderEnabled = prefs.getBool('pref_daily_reminder') ?? false;
      final hour = prefs.getInt('pref_reminder_hour');
      final minute = prefs.getInt('pref_reminder_minute');
      if (hour != null && minute != null) {
        _reminderTime = TimeOfDay(hour: hour, minute: minute);
      }
    });
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('pref_notifications', _notificationsEnabled);
    await prefs.setBool('pref_daily_reminder', _dailyReminderEnabled);
    await prefs.setInt('pref_reminder_hour', _reminderTime.hour);
    await prefs.setInt('pref_reminder_minute', _reminderTime.minute);
  }

  Future<void> _pickReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
    );
    if (picked != null) {
      setState(() => _reminderTime = picked);
      await _savePreferences();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
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
                  icon: Icons.self_improvement,
                  label: 'Медитации',
                  route: '/meditation'),
              _NavDestination(
                  icon: Icons.lightbulb_outline,
                  label: 'Советы',
                  route: '/tips'),
              _NavDestination(
                  icon: Icons.favorite_outline,
                  label: 'Поддержка',
                  route: '/support'),
            ],
          ),
          const SizedBox(height: 16),
          _SettingsGroup(
            title: 'Уведомления',
            children: [
              SwitchListTile.adaptive(
                value: _notificationsEnabled,
                title: const Text('Получать уведомления'),
                subtitle: const Text('Сообщения от AIc и напоминания'),
                onChanged: (value) {
                  setState(() => _notificationsEnabled = value);
                  _savePreferences();
                },
              ),
              SwitchListTile.adaptive(
                value: _dailyReminderEnabled,
                title: const Text('Ежедневное напоминание'),
                subtitle:
                    Text('Каждый день в ${_reminderTime.format(context)}'),
                onChanged: (value) {
                  setState(() => _dailyReminderEnabled = value);
                  _savePreferences();
                },
              ),
              ListTile(
                enabled: _dailyReminderEnabled,
                leading: const Icon(Icons.schedule_rounded),
                title: const Text('Время напоминания'),
                subtitle: Text('Сейчас: ${_reminderTime.format(context)}'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: _dailyReminderEnabled ? _pickReminderTime : null,
              ),
            ],
          ),
          _SettingsGroup(
            title: 'Профиль',
            children: [
              ListTile(
                leading: const Icon(Icons.person_outline_rounded),
                title: const Text('Посмотреть профиль'),
                subtitle: const Text('Имя, возраст и страна'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => context.push('/profile'),
              ),
            ],
          ),
          _SettingsGroup(
            title: 'О приложении',
            children: const [
              ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('Версия'),
                subtitle: Text('AIc v1.0.0'),
              ),
              ListTile(
                leading: Icon(Icons.privacy_tip_outlined),
                title: Text('Конфиденциальность'),
                subtitle: Text(
                    'Мы храним только необходимые данные, ты контролируешь свои настройки.'),
              ),
            ],
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

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}
