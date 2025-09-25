import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'chat_adapter_interface.dart';
import 'chat_adapter_factory.dart';
import '../../components/navigation/aic_scaffold.dart';
import '../../providers/chat_settings_provider.dart';
import '../../models/chat_provider.dart';

class NewChatPage extends ConsumerStatefulWidget {
  final String? initialMessage;
  final Map<String, dynamic>? context;

  const NewChatPage({
    super.key,
    this.initialMessage,
    this.context,
  });

  @override
  ConsumerState<NewChatPage> createState() => _NewChatPageState();
}

class _NewChatPageState extends ConsumerState<NewChatPage> {
  final List<types.Message> _messages = [];
  final _user = const types.User(id: 'user', firstName: 'Ты');
  final _assistant = const types.User(id: 'assistant', firstName: 'AIc');

  ChatAdapter? _chatAdapter;
  bool _isConnected = false;
  Map<String, dynamic> _stats = {
    'model': 'unknown',
    'isConnected': false,
    'totalTokens': 0,
    'messagesCount': 0,
  };

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  Future<void> _initChat() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? sessionId = prefs.getString('session_id');

      if (sessionId == null) {
        // Генерируем уникальный sessionId для чата
        sessionId = DateTime.now().millisecondsSinceEpoch.toString();
        await prefs.setString('session_id', sessionId);
      }

      // Получаем конфигурацию чата из провайдера настроек
      final chatConfig = ref.read(chatSettingsProvider);
      
      // Создаем адаптер на основе конфигурации
      _chatAdapter = ChatAdapterFactory.create(chatConfig);
      _chatAdapter!.initialize(
        sessionId: sessionId!,
        config: chatConfig,
        onMessageReceived: _handleMessageReceived,
        onError: _showError,
        onConnectionStatusChanged: _handleConnectionStatusChanged,
        onStatsUpdated: _handleStatsUpdated,
      );

    // Добавляем приветственное сообщение
    final welcomeMessage = types.TextMessage(
      author: _assistant,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: 'welcome',
      text: _getWelcomeMessage(),
    );

    setState(() {
      _messages.insert(0, welcomeMessage);
      _isConnected = true;
    });

    // Автоматически отправляем начальное сообщение
    if (widget.initialMessage?.isNotEmpty == true) {
      _handleSendPressed(types.PartialText(text: widget.initialMessage!));
    }
    } catch (e) {
      _showError('Ошибка инициализации: $e');
    }
  }

  String _getWelcomeMessage() {
    if (widget.context != null) {
      final category = widget.context!['category'] as String?;
      final subcategory = widget.context!['subcategory'] as String?;

      if (category != null && subcategory != null) {
        return 'Привет! Я AIc 🐶 Вижу, ты интересуешься темой "$subcategory" из раздела "$category". Готов помочь разобраться с этим вопросом!';
      }
    }

    return 'Привет! Я AIc 🐶 Как у тебя настроение?';
  }

  void _handleMessageReceived(types.Message message) {
    setState(() {
      _messages.insert(0, message);
    });
  }

  void _handleConnectionStatusChanged(bool isConnected) {
    setState(() {
      _isConnected = isConnected;
      _stats['isConnected'] = isConnected;
    });
  }

  void _handleStatsUpdated(Map<String, dynamic> stats) {
    setState(() {
      _stats = stats;
    });
  }

  void _handleSendPressed(types.PartialText message) {
    final textMessage = types.TextMessage(
      author: _user,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: message.text,
    );

    setState(() {
      _messages.insert(0, textMessage);
    });

    // Отправляем сообщение через адаптер
    _chatAdapter?.sendMessage(message.text);
  }

  void _showError(String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final providerConfig = ref.watch(chatProviderConfigProvider);
        final isGrok = ref.watch(isGrokProviderProvider);
        final isMock = ref.watch(isMockProviderProvider);
        
        return AicChatScaffold(
          title: 'Чат с AIc',
          currentRoute: '/chat',
          appBarActions: [
            // Provider selector
            PopupMenuButton<ChatProviderType>(
              onSelected: (ChatProviderType selectedType) {
                ref.read(chatSettingsProvider.notifier).switchProvider(selectedType);
              },
              itemBuilder: (BuildContext context) => [
                PopupMenuItem(
                  value: ChatProviderType.grok,
                  child: Row(
                    children: [
                      Icon(
                        Icons.smart_toy,
                        color: isGrok ? Colors.green : Colors.grey,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text('Grok AI'),
                      if (isGrok) ...[
                        const Spacer(),
                        const Icon(Icons.check, color: Colors.green, size: 16),
                      ],
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: ChatProviderType.mock,
                  child: Row(
                    children: [
                      Icon(
                        Icons.test_tube,
                        color: isMock ? Colors.green : Colors.grey,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text('Mock (тест)'),
                      if (isMock) ...[
                        const Spacer(),
                        const Icon(Icons.check, color: Colors.green, size: 16),
                      ],
                    ],
                  ),
                ),
              ],
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (_stats['isConnected'] ? Colors.green : Colors.red).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isGrok ? Icons.smart_toy : Icons.test_tube,
                      color: _stats['isConnected'] ? Colors.green : Colors.red,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isGrok ? 'Grok-4' : 'Mock',
                          style: TextStyle(
                            color: _stats['isConnected'] ? Colors.green : Colors.red,
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                        Text(
                          '${_stats['totalTokens']}t • ${_stats['messagesCount']}m',
                          style: TextStyle(
                            color: (_stats['isConnected'] ? Colors.green : Colors.red).withValues(alpha: 0.7),
                            fontSize: 8,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_drop_down,
                      color: _stats['isConnected'] ? Colors.green : Colors.red,
                      size: 12,
                    ),
                  ],
                ),
              ),
            ),
          ],
      ],
          body: Chat(
            messages: _messages,
            onSendPressed: _handleSendPressed,
            user: _user,
            theme: DefaultChatTheme(
              backgroundColor: const Color(0xFFF8FAFC),
              primaryColor: Theme.of(context).colorScheme.primary,
              secondaryColor: const Color(0xFFF1F5F9),
            ),
          ),
        );
      },
    );
  }
    );
  }

  @override
  void dispose() {
    _chatAdapter?.dispose();
    super.dispose();
  }
}