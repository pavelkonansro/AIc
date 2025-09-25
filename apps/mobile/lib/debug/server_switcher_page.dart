import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/api_config.dart';
import '../state/server_config_provider.dart';

class ServerSwitcherPage extends ConsumerStatefulWidget {
  const ServerSwitcherPage({Key? key}) : super(key: key);

  @override
  ConsumerState<ServerSwitcherPage> createState() => _ServerSwitcherPageState();
}

class _ServerSwitcherPageState extends ConsumerState<ServerSwitcherPage> {
  
  @override
  Widget build(BuildContext context) {
    final currentConfig = ref.watch(currentApiConfigProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Переключение серверов'),
        backgroundColor: Colors.purple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Текущий сервер:',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text('Название: ${currentConfig['name']}'),
                    Text('URL: ${currentConfig['baseUrl']}'),
                    Text('Описание: ${currentConfig['description']}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Доступные серверы:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: [
                  _buildServerOption(
                    'Mac Local',
                    'http://192.168.68.65:3001',
                    'Локальный сервер на Mac разработчика',
                    Colors.green,
                    () => _showSwitchDialog('Mac Local', 'К сожалению, нужно изменить код для переключения на локальный сервер'),
                  ),
                  _buildServerOption(
                    'ngrok Tunnel',
                    'https://subcuticular-latrisha-commemoratively.ngrok-free.dev',
                    'ngrok туннель для обхода сетевых ограничений',
                    Colors.blue,
                    () => _showSwitchDialog('ngrok Tunnel', 'Уже используется ngrok сервер'),
                  ),
                  _buildServerOption(
                    'Beget Hosting',
                    'https://konans6z.beget.tech',
                    'Тестовый сервер на Beget хостинге с SSL',
                    Colors.orange,
                    () => _showSwitchDialog('Beget Hosting', 'К сожалению, нужно изменить код для переключения на Beget'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Card(
              color: Colors.amber,
              child: Padding(
                padding: EdgeInsets.all(12.0),
                child: Text(
                  '⚠️ Примечание:\n'
                  'Для переключения серверов нужно изменить код в api_config.dart и перезапустить приложение.\n\n'
                  'Сейчас используется ngrok сервер, который должен работать из любой сети.',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServerOption(String name, String url, String description, Color color, VoidCallback onTap) {
    final currentConfig = ref.watch(currentApiConfigProvider);
    final isActive = currentConfig['baseUrl'] == url;
    
    return Card(
      elevation: isActive ? 4 : 1,
      color: isActive ? color.withOpacity(0.1) : null,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: Text(
            name.substring(0, 1),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          name,
          style: TextStyle(
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(url, style: const TextStyle(fontSize: 12)),
            Text(description, style: const TextStyle(fontSize: 11)),
          ],
        ),
        trailing: isActive 
            ? const Icon(Icons.check_circle, color: Colors.green)
            : const Icon(Icons.radio_button_unchecked),
        onTap: onTap,
      ),
    );
  }

  void _showSwitchDialog(String serverName, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Переключение на $serverName'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}