import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SimpleMotivationPage extends ConsumerStatefulWidget {
  const SimpleMotivationPage({super.key});

  @override
  ConsumerState<SimpleMotivationPage> createState() => _SimpleMotivationPageState();
}

class _SimpleMotivationPageState extends ConsumerState<SimpleMotivationPage> {
  int _currentQuoteIndex = 0;

  final List<Map<String, dynamic>> _motivationalContent = [
    {
      'quote': 'Ты сильнее, чем думаешь! 💪',
      'description': 'Каждый день - новая возможность стать лучше',
      'color': Colors.blue,
    },
    {
      'quote': 'Верь в себя! ✨',
      'description': 'Твои мечты ждут, когда ты их осуществишь',
      'color': Colors.purple,
    },
    {
      'quote': 'Ты не одинок(а) 🤝',
      'description': 'Вокруг тебя много людей, которые поддержат',
      'color': Colors.green,
    },
    {
      'quote': 'Прогресс важнее совершенства 🌱',
      'description': 'Каждый маленький шаг приближает к цели',
      'color': Colors.orange,
    },
    {
      'quote': 'Ты особенный(ая) 🌟',
      'description': 'В мире нет никого точно такого же, как ты',
      'color': Colors.pink,
    },
  ];

  void _nextQuote() {
    setState(() {
      _currentQuoteIndex = (_currentQuoteIndex + 1) % _motivationalContent.length;
    });
  }

  void _previousQuote() {
    setState(() {
      _currentQuoteIndex = (_currentQuoteIndex - 1 + _motivationalContent.length) % _motivationalContent.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentContent = _motivationalContent[_currentQuoteIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Мотивация'),
        backgroundColor: currentContent['color'],
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              currentContent['color'].withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Простая анимация с иконкой вместо Lottie (пока нет файлов)
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: currentContent['color'],
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: currentContent['color'].withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.favorite,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 40),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Column(
                  key: ValueKey(_currentQuoteIndex),
                  children: [
                    Text(
                      currentContent['quote'],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: currentContent['color'],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      currentContent['description'],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 60),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  FloatingActionButton(
                    heroTag: 'previous',
                    onPressed: _previousQuote,
                    backgroundColor: currentContent['color'],
                    child: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  FloatingActionButton.extended(
                    heroTag: 'share',
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Мотивация сохранена! ❤️'),
                          backgroundColor: currentContent['color'],
                        ),
                      );
                    },
                    backgroundColor: currentContent['color'],
                    icon: const Icon(Icons.favorite, color: Colors.white),
                    label: const Text('Сохранить', style: TextStyle(color: Colors.white)),
                  ),
                  FloatingActionButton(
                    heroTag: 'next',
                    onPressed: _nextQuote,
                    backgroundColor: currentContent['color'],
                    child: const Icon(Icons.arrow_forward, color: Colors.white),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // Индикатор страниц
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _motivationalContent.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: index == _currentQuoteIndex ? 12 : 8,
                    height: index == _currentQuoteIndex ? 12 : 8,
                    decoration: BoxDecoration(
                      color: index == _currentQuoteIndex
                          ? currentContent['color']
                          : Colors.grey.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}