import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_client_simple.dart';
import '../config/api_config.dart';

class NetworkDiagnosticsPage extends ConsumerStatefulWidget {
  const NetworkDiagnosticsPage({Key? key}) : super(key: key);

  @override
  ConsumerState<NetworkDiagnosticsPage> createState() => _NetworkDiagnosticsPageState();
}

class _NetworkDiagnosticsPageState extends ConsumerState<NetworkDiagnosticsPage> {
  String _diagnosticResults = 'Готов к диагностике...';
  bool _isRunning = false;

  Future<void> _runDiagnostics() async {
    setState(() {
      _isRunning = true;
      _diagnosticResults = 'Запуск диагностики...\n';
    });

    final buffer = StringBuffer();
    buffer.writeln('=== СЕТЕВАЯ ДИАГНОСТИКА ===');
    buffer.writeln('Время: ${DateTime.now()}');
    buffer.writeln('');

    // 1. Проверяем конфигурацию
    buffer.writeln('📋 КОНФИГУРАЦИЯ:');
    buffer.writeln('Текущий сервер: ${ApiConfig.currentServerName}');
    buffer.writeln('URL: ${ApiConfig.baseUrl}');
    buffer.writeln('WebSocket: ${ApiConfig.wsUrl}');
    buffer.writeln('');

    setState(() => _diagnosticResults = buffer.toString());

    try {
      // 2. Проверяем health endpoint
      buffer.writeln('🏥 ПРОВЕРКА HEALTH ENDPOINT:');
      final apiClient = ref.read(apiClientProvider);
      final healthResponse = await apiClient.checkConnection();
      
      if (healthResponse != null) {
        buffer.writeln('✅ Сервер доступен');
        buffer.writeln('Ответ: $healthResponse');
      } else {
        buffer.writeln('❌ Health endpoint недоступен');
      }
      buffer.writeln('');

      setState(() => _diagnosticResults = buffer.toString());

      // 3. Тестируем создание сессии чата
      buffer.writeln('💬 ТЕСТ СОЗДАНИЯ СЕССИИ ЧАТА:');
      final sessionResponse = await apiClient.createChatSession();
      
      if (sessionResponse != null && sessionResponse.containsKey('sessionId')) {
        buffer.writeln('✅ Сессия создана успешно');
        buffer.writeln('ID сессии: ${sessionResponse['sessionId']}');
        
        setState(() => _diagnosticResults = buffer.toString());

        // 4. Тестируем отправку сообщения
        buffer.writeln('');
        buffer.writeln('📤 ТЕСТ ОТПРАВКИ СООБЩЕНИЯ:');
        final messageResponse = await apiClient.sendChatMessage(
          sessionResponse['sessionId'], 
          'Тестовое сообщение из диагностики'
        );
        
        if (messageResponse != null && messageResponse['content'] != null) {
          buffer.writeln('✅ Сообщение отправлено и получен ответ');
          buffer.writeln('Ответ: ${messageResponse['content']}');
        } else {
          buffer.writeln('❌ Ошибка отправки сообщения');
          buffer.writeln('Ответ: $messageResponse');
        }
      } else {
        buffer.writeln('❌ Не удалось создать сессию');
        buffer.writeln('Ответ: $sessionResponse');
      }

    } catch (e) {
      buffer.writeln('💥 КРИТИЧЕСКАЯ ОШИБКА:');
      buffer.writeln('Тип: ${e.runtimeType}');
      buffer.writeln('Сообщение: $e');
    }

    buffer.writeln('');
    buffer.writeln('=== ДИАГНОСТИКА ЗАВЕРШЕНА ===');

    setState(() {
      _diagnosticResults = buffer.toString();
      _isRunning = false;
    });
  }

  Future<void> _testDifferentServers() async {
    setState(() {
      _isRunning = true;
      _diagnosticResults = 'Тестирование разных серверов...\n';
    });

    final buffer = StringBuffer();
    buffer.writeln('=== ТЕСТ РАЗНЫХ СЕРВЕРОВ ===');
    
    // Список серверов для тестирования
    final serversToTest = [
      {'name': 'Mac Local (3001)', 'url': 'http://192.168.68.65:3001'},
      {'name': 'Mac Local (3000)', 'url': 'http://192.168.68.65:3000'},
      {'name': 'Beget Hosting', 'url': 'https://konans6z.beget.tech'},
    ];

    for (final server in serversToTest) {
      buffer.writeln('');
      buffer.writeln('🔍 Тестируем: ${server['name']}');
      buffer.writeln('URL: ${server['url']}');
      
      setState(() => _diagnosticResults = buffer.toString());

      try {
        final testClient = ApiClient(server['url']!);
        final healthResponse = await testClient.checkConnection();
        
        if (healthResponse != null) {
          buffer.writeln('✅ Доступен');
        } else {
          buffer.writeln('❌ Недоступен');
        }
      } catch (e) {
        buffer.writeln('❌ Ошибка: $e');
      }
      
      setState(() => _diagnosticResults = buffer.toString());
    }

    buffer.writeln('');
    buffer.writeln('=== ТЕСТ ЗАВЕРШЕН ===');

    setState(() {
      _diagnosticResults = buffer.toString();
      _isRunning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Сетевая диагностика'),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isRunning ? null : _runDiagnostics,
                    child: _isRunning 
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Запустить диагностику'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isRunning ? null : _testDifferentServers,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Тест серверов'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _diagnosticResults,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Инструкции:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '1. "Запустить диагностику" - проверит текущий сервер\n'
              '2. "Тест серверов" - проверит все доступные серверы\n'
              '3. Если все тесты проваливаются, проблема в сети\n'
              '4. Если работает только Beget - используйте его',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}