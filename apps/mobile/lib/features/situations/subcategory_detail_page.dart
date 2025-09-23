import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'situations_page.dart';
import '../../services/logger.dart';
import '../../components/navigation/navigation.dart';

class SubcategoryDetailPage extends StatelessWidget {
  final SituationCategory category;
  final SituationSubcategory subcategory;

  const SubcategoryDetailPage({
    super.key,
    required this.category,
    required this.subcategory,
  });

  @override
  Widget build(BuildContext context) {
    final categoryColor = Color(int.parse(category.color.replaceFirst('#', '0xFF')));

    return AicScaffold(
      title: subcategory.title,
      appBarBackgroundColor: categoryColor,
      showBottomNavigation: false,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок и описание
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: categoryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: categoryColor.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: categoryColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _getIconData(category.icon),
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              category.title,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: categoryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              subcategory.title,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    subcategory.description,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Статья
            Text(
              'Что важно знать',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Text(
              subcategory.article,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                height: 1.6,
                letterSpacing: 0.2,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Кнопки чата
            Text(
              'Поговори с Айком',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Выбери вопрос, который тебя больше всего волнует',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 16),
            
            ...subcategory.chatPrompts.map((prompt) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ChatPromptButton(
                prompt: prompt,
                categoryColor: categoryColor,
                onTap: () => _startChatWithPrompt(context, prompt),
              ),
            )),
            
            const SizedBox(height: 24),
            
            // Общая кнопка чата
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _startGeneralChat(context),
                icon: const Icon(Icons.chat_outlined),
                label: const Text('Начать свободный разговор'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: categoryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _startChatWithPrompt(BuildContext context, String prompt) {
    AppLogger.i('Начало чата с промптом: $prompt');
    // TODO: Создать новую сессию чата с контекстом и промптом
    context.push('/chat', extra: {
      'initialMessage': prompt,
      'context': {
        'category': category.title,
        'subcategory': subcategory.title,
        'topic': subcategory.description,
      },
    });
  }

  void _startGeneralChat(BuildContext context) {
    AppLogger.i('Начало общего чата по теме: ${subcategory.title}');
    // TODO: Создать новую сессию чата с общим контекстом
    context.push('/chat', extra: {
      'context': {
        'category': category.title,
        'subcategory': subcategory.title,
        'topic': subcategory.description,
      },
    });
  }

  IconData _getIconData(String iconName) {
    final Map<String, IconData> icons = {
      'favorite_border': Icons.favorite_border,
      'home_outlined': Icons.home_outlined,
      'people_outline': Icons.people_outline,
      'psychology_outlined': Icons.psychology_outlined,
      'school_outlined': Icons.school_outlined,
      'gaming_outlined': Icons.games_outlined,
    };
    return icons[iconName] ?? Icons.help_outline;
  }
}

class _ChatPromptButton extends StatelessWidget {
  final String prompt;
  final Color categoryColor;
  final VoidCallback onTap;

  const _ChatPromptButton({
    required this.prompt,
    required this.categoryColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: categoryColor.withValues(alpha: 0.5)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.chat_bubble_outline,
              color: categoryColor,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                prompt,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: categoryColor,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.left,
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: categoryColor.withValues(alpha: 0.7),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}