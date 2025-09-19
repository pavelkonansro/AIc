import 'package:flutter/material.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _controller = TextEditingController();
  final _messages = <Map<String,String>>[
    {'role':'assistant','content':'Привет! Я AIc 🐶 Как у тебя настроение?'},
  ];

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add({'role':'user','content':text});
      _messages.add({'role':'assistant','content':'(Здесь будет ответ ИИ)...'});
      _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Чат с AIc')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (_, i) {
                final m = _messages[i];
                final isUser = m['role']=='user';
                return Align(
                  alignment: isUser? Alignment.centerRight:Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical:6),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isUser? Colors.indigo.shade100:Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(m['content'] ?? ''),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: TextField(controller:_controller, decoration: const InputDecoration(
                    contentPadding: EdgeInsets.all(12),
                    hintText: 'Напиши AIc...',
                  )),
                ),
                IconButton(icon: const Icon(Icons.send), onPressed: _send)
              ],
            ),
          )
        ],
      ),
    );
  }
}
