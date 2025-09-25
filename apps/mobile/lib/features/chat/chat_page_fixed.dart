import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as socket_io;
import '../../utils/string_utils.dart';

class ChatPageFixed extends StatefulWidget {
  final String? initialMessage;
  final Map<String, dynamic>? context;

  const ChatPageFixed({
    super.key,
    this.initialMessage,
    this.context,
  });

  @override
  State<ChatPageFixed> createState() => _ChatPageFixedState();
}

class _ChatPageFixedState extends State<ChatPageFixed> {
  final _controller = TextEditingController();
  late final List<Map<String, String>> _messages;
  socket_io.Socket? _socket;
  String? _sessionId;
  bool _isConnected = false;
  bool _isLoading = false;
  
  // Отладочная информация
  String _currentModel = 'Загрузка...';
  int _totalTokens = 0;
  bool _debugMode = true; // Включить для отладки

  bool get _hasSelectedTopic => widget.initialMessage != null;
  ThemeData? _theme;

  @override
  void initState() {
    super.initState();

    // Инициализируем сообщения с учетом контекста
    _messages = <Map<String, String>>[
      {
        'role': 'assistant',
        'content': _getWelcomeMessage(),
      }
    ];

    // Если есть initialMessage, сразу показываем его в UI
    if (widget.initialMessage != null && widget.initialMessage!.trim().isNotEmpty) {
      _messages.add({'role': 'user', 'content': widget.initialMessage!});
    }

    _initSocket();
  }

  String _getWelcomeMessage() {
    if (widget.context != null) {
      final context = widget.context!;
      final category = context['category'] as String?;
      final subcategory = context['subcategory'] as String?;
      
      if (category != null && subcategory != null) {
        return 'Привет! Я AIc 🐶 Вижу, ты интересуешься темой "$subcategory" из раздела "$category". Готов помочь разобраться с этим вопросом!';
      }
    }
    
    return 'Привет! Я AIc 🐶 Как у тебя настроение?';
  }

  Future<void> _initSocket() async {
    try {
      debugPrint('🔄 Инициализируем WebSocket...');
      final prefs = await SharedPreferences.getInstance();
      _sessionId = prefs.getString('session_id');

      debugPrint('📋 Session ID: $_sessionId');

      if (_sessionId == null) {
        debugPrint('❌ Session ID не найден');
        _showError(
            'Сессия не найдена. Пожалуйста, вернитесь на страницу авторизации.');
        return;
      }

      debugPrint('🌐 Подключаемся к WebSocket...');
      _socket = socket_io.io(
          'http://192.168.68.65:3000/chat',
          socket_io.OptionBuilder()
              .setTransports(['websocket'])
              .enableAutoConnect()
              .build());

      _socket!.onConnect((_) {
        debugPrint('✅ WebSocket подключен');
        setState(() => _isConnected = true);
        if (_sessionId != null) {
          _socket!.emit('join_session', {'sessionId': _sessionId!});
          _addMessage('system', 'Подключено к чату');
          
          // Автоматически отправляем начальное сообщение, если оно есть
          // НЕ добавляем в UI, так как оно уже добавлено в initState
          if (widget.initialMessage != null && widget.initialMessage!.trim().isNotEmpty) {
            Future.delayed(const Duration(milliseconds: 500), () {
              _sendMessageToServer(widget.initialMessage!);
            });
          }
        }
      });

      _socket!.onDisconnect((_) {
        debugPrint('❌ WebSocket отключен');
        if (mounted) {
          setState(() => _isConnected = false);
          _addMessage('system', 'Отключено от чату');
        }
      });

      _socket!.on('message', (data) {
        debugPrint('📨 Получено сообщение: $data');
        final role = data['role'] ?? 'assistant';
        final content = data['content'] ?? '';
        
        // Извлекаем информацию о модели и токенах
        final model = data['model'] ?? '';
        final usage = data['usage'] as Map<String, dynamic>?;
        
        if (usage != null) {
          final promptTokens = usage['prompt_tokens'] ?? 0;
          final completionTokens = usage['completion_tokens'] ?? 0;
          final totalTokens = usage['total_tokens'] ?? 0;
          
          setState(() {
            _currentModel = model.isNotEmpty ? model : _currentModel;
            _totalTokens += totalTokens as int;
          });
          
          debugPrint('🤖 Модель: $model');
          debugPrint('📊 Токены - Prompt: $promptTokens, Completion: $completionTokens, Total: $totalTokens');
        }
        
        if (content.isNotEmpty) {
          _addMessage(role, content);
          debugPrint('📝 Длина контента: ${content.length} символов');
        }
        if (mounted) {
          setState(() => _isLoading = false);
        }
      });

      _socket!.on('error', (data) {
        debugPrint('❌ WebSocket ошибка: $data');
        _addMessage('error', 'Ошибка: ${data['message']}');
        if (mounted) {
          setState(() => _isLoading = false);
        }
      });
    } catch (e) {
      debugPrint('❌ Ошибка инициализации WebSocket: $e');
      _showError('Ошибка подключения: $e');
    }
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty ||
        !_isConnected ||
        _isLoading ||
        _sessionId == null) {
      return;
    }

    _sendMessage(text);
  }

  void _sendMessage(String text) {
    setState(() {
      _isLoading = true;
      _controller.clear();
    });

    _addMessage('user', text);

    debugPrint('📤 Отправляем сообщение: $text');
    debugPrint('📋 Session ID: $_sessionId');
    debugPrint('🔌 WebSocket подключен: $_isConnected');

    // Создаем данные для отправки с проверками
    final messageData = {
      'sessionId': _sessionId!,
      'text': text,
    };

    debugPrint('📦 Данные для отправки: $messageData');

    // Отправляем с таймаутом
    try {
      _socket!.emit('chat:message', messageData);

      // Устанавливаем таймаут на случай зависания
      Future.delayed(const Duration(seconds: 30), () {
        if (_isLoading) {
          debugPrint('⏰ Таймаут ожидания ответа');
          setState(() => _isLoading = false);
          _addMessage('error', 'Таймаут ожидания ответа от AI');
        }
      });
    } catch (e) {
      debugPrint('❌ Ошибка отправки: $e');
      setState(() => _isLoading = false);
      _addMessage('error', 'Ошибка отправки сообщения: $e');
    }
  }

  // Отправляет сообщение на сервер БЕЗ добавления в UI (для initialMessage)
  void _sendMessageToServer(String text) {
    if (!_isConnected || _sessionId == null) {
      debugPrint('❌ Не можем отправить сообщение: не подключен или нет сессии');
      return;
    }

    setState(() => _isLoading = true);

    debugPrint('📤 Отправляем initialMessage на сервер: $text');
    
    final messageData = {
      'sessionId': _sessionId!,
      'text': text,
    };

    try {
      _socket!.emit('chat:message', messageData);
      
      // Таймаут для initialMessage
      Future.delayed(const Duration(seconds: 30), () {
        if (_isLoading) {
          debugPrint('⏰ Таймаут ожидания ответа на initialMessage');
          setState(() => _isLoading = false);
          _addMessage('error', 'Таймаут ожидания ответа от AI');
        }
      });
    } catch (e) {
      debugPrint('❌ Ошибка отправки initialMessage: $e');
      setState(() => _isLoading = false);
      _addMessage('error', 'Ошибка отправки сообщения: $e');
    }
  }

  void _addMessage(String role, String content) {
    if (mounted) {
      setState(() {
        _messages.add({'role': role, 'content': content});
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _logout() async {
    _socket?.disconnect();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (mounted) {
      context.go('/');
    }
  }

  @override
  void dispose() {
    _socket?.disconnect();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _theme = Theme.of(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Чат с AIc'),
        actions: [
          _StatusPill(isConnected: _isConnected),
          IconButton(
            icon: const Icon(Icons.home_rounded),
            onPressed: () => context.go('/home'),
            tooltip: 'Главная',
          ),
          IconButton(
            icon: const Icon(Icons.favorite_outline),
            onPressed: () => context.go('/motivation'),
            tooltip: 'Мотивация',
          ),
          IconButton(
            icon: const Icon(Icons.spa_rounded),
            onPressed: () {
              // TODO: Добавить навигацию к медитации
            },
            tooltip: 'Медитация',
          ),
          IconButton(
            icon: const Icon(Icons.support_agent_rounded),
            onPressed: () {
              // TODO: Добавить навигацию к поддержке  
            },
            tooltip: 'Поддержка',
          ),
          IconButton(
            icon: Icon(_debugMode ? Icons.bug_report : Icons.bug_report_outlined),
            onPressed: () => setState(() => _debugMode = !_debugMode),
            tooltip: 'Отладка',
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: _logout,
            tooltip: 'Выйти',
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFEEF2FF), Color(0xFFF8FAFC)],
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: kToolbarHeight + 20),
            // Компактная отладочная панель
            if (_debugMode) ...[
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          // Модель
                          Icon(Icons.psychology_outlined, color: Colors.green, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            StringUtils.safeTruncate(
                              _currentModel.split('/').last.replaceAll(':', ''),
                              8,
                              ''
                            ),
                            style: const TextStyle(color: Colors.white, fontSize: 11),
                          ),
                          const SizedBox(width: 12),
                          // Токены  
                          Icon(Icons.analytics_outlined, color: Colors.blue, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '$_totalTokens',
                            style: const TextStyle(color: Colors.white, fontSize: 11),
                          ),
                          const SizedBox(width: 12),
                          // Соединение
                          Icon(
                            _isConnected ? Icons.wifi : Icons.wifi_off,
                            color: _isConnected ? Colors.green : Colors.red,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          // Загрузка
                          if (_isLoading) 
                            const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                              ),
                            )
                          else
                            Icon(Icons.check_circle, color: Colors.green, size: 16),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _debugMode = false),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white54,
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildHeroCard(context),
            ),
            const SizedBox(height: 16),
            // Убрали блок выбора тем - просто показываем чат всегда
            const SizedBox(height: 12),
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 18,
                      offset: const Offset(0, 12),
                    )
                  ],
                ),
                child: _buildMessagesList(),
              ),
            ),
            _buildComposer(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context) {
    final hasTopic = _hasSelectedTopic;
    final topicTitle = hasTopic ? 'Тема для обсуждения' : '';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF312E81).withValues(alpha: 0.25),
            blurRadius: 22,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            hasTopic ? 'Давай разберём тему' : 'AIc рядом',
            style: _theme?.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hasTopic
                ? 'Мы фокусируемся на «$topicTitle». Если захочешь сменить фокус, просто выбери другую тему.'
                : 'Выбери тему, которая откликается прямо сейчас — я помогу разобраться и поддержу.',
            style: _theme?.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.92),
            ),
          ),
          if (hasTopic) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _SelectedTopicChip(
                  label: topicTitle,
                  color: Theme.of(context).colorScheme.primary,
                  onChange: () {}, // Убираем логику
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: const [
              _QuickLinkChip(
                label: 'Медитации',
                icon: Icons.self_improvement,
                route: '/meditation',
              ),
              _QuickLinkChip(
                label: 'Советы',
                icon: Icons.lightbulb_outline,
                route: '/tips',
              ),
              _QuickLinkChip(
                label: 'Поддержка',
                icon: Icons.volunteer_activism,
                route: '/support',
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 12, bottom: 12),
      itemCount: _messages.length + (_isLoading ? 1 : 0),
      itemBuilder: (_, i) {
        if (i == _messages.length && _isLoading) {
          return const Align(
            alignment: Alignment.centerLeft,
            child: _TypingBubble(),
          );
        }

        final m = _messages[i];
        final isUser = m['role'] == 'user';
        final isSystem = m['role'] == 'system';
        final isError = m['role'] == 'error';

        return Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: _ChatBubble(
            message: m['content'] ?? '',
            isUser: isUser,
            isSystem: isSystem,
            isError: isError,
          ),
        );
      },
    );
  }

  Widget _buildComposer() {
    final enabled = _isConnected && !_isLoading;

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                enabled: enabled,
                minLines: 1,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: enabled
                      ? (_isLoading ? 'AIc печатает...' : 'Напиши AIc...')
                      : 'Подключаемся...',
                  border: InputBorder.none,
                ),
                onSubmitted: enabled ? (_) => _send() : null,
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: enabled ? _send : null,
              icon: const Icon(Icons.send_rounded),
              label: const Text('Отправить'),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper widgets
class _SelectedTopicChip extends StatelessWidget {
  const _SelectedTopicChip({
    required this.label,
    required this.color,
    required this.onChange,
  });

  final String label;
  final Color color;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onChange,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.45), width: 1.2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.topic_rounded, color: color, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: Color.lerp(color, Colors.black, 0.2) ?? color,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.edit_outlined, color: color, size: 14),
          ],
        ),
      ),
    );
  }
}

class _QuickLinkChip extends StatelessWidget {
  const _QuickLinkChip({
    required this.label,
    required this.icon,
    required this.route,
  });

  final String label;
  final IconData icon;
  final String route;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go(route),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(18),
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
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({
    required this.message,
    required this.isUser,
    required this.isSystem,
    required this.isError,
  });

  final String message;
  final bool isUser;
  final bool isSystem;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = isUser
        ? theme.colorScheme.primary.withValues(alpha: 0.12)
        : isError
            ? const Color(0xFFFEE2E2)
            : isSystem
                ? const Color(0xFFE0E7FF)
                : const Color(0xFFF1F5F9);

    final textColor = isUser
        ? theme.colorScheme.primary
        : isError
            ? const Color(0xFFB91C1C)
            : Colors.black87;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      constraints: const BoxConstraints(maxWidth: 320),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(isUser ? 18 : 6),
          bottomRight: Radius.circular(isUser ? 6 : 18),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Text(
        message,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: textColor,
          height: 1.35,
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFE5EDFF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          SizedBox(
            height: 16,
            width: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 8),
          Text('AIc печатает...'),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.isConnected});

  final bool isConnected;

  @override
  Widget build(BuildContext context) {
    final color =
        isConnected ? const Color(0xFF22C55E) : const Color(0xFFEF4444);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isConnected ? Icons.wifi_rounded : Icons.wifi_off_rounded,
            color: color,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            isConnected ? 'В сети' : 'Оффлайн',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
