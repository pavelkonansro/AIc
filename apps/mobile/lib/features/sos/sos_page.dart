import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SosPage extends StatelessWidget {
  const SosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SOS Помощь'),
        backgroundColor: Colors.red.shade400,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Column(
              children: [
                Icon(Icons.emergency, size: 48, color: Colors.red.shade600),
                const SizedBox(height: 8),
                Text(
                  'Экстренная помощь',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade800,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Если ты находишься в опасности или нуждаешься в срочной помощи, обратись к взрослому или по телефонам экстренных служб.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Контакты помощи',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildContactCard(
            'Экстренные службы',
            '112',
            'Общий номер экстренных служб в Европе',
            Icons.local_hospital,
            Colors.red,
          ),
          _buildContactCard(
            'Детский телефон доверия',
            '116 111',
            'Бесплатная психологическая помощь детям',
            Icons.phone,
            Colors.blue,
          ),
          _buildContactCard(
            'Кризисный центр',
            '800 123 456',
            'Помощь в кризисных ситуациях 24/7',
            Icons.support_agent,
            Colors.green,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Помни:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text('• Ты не одинок в своих переживаниях'),
                const Text('• Обращение за помощью - это смелость'),
                const Text('• Всегда есть люди, готовые помочь'),
                const Text('• Каждая проблема имеет решение'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(String title, String phone, String description, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(phone, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            Text(description, style: const TextStyle(fontSize: 12)),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.call),
          onPressed: () => _makePhoneCall(phone),
        ),
        onTap: () => _makePhoneCall(phone),
      ),
    );
  }

  void _makePhoneCall(String phone) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phone.replaceAll(' ', ''));
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }
}
