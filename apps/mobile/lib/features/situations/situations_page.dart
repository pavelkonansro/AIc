import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:go_router/go_router.dart';
import '../../services/logger.dart';

class SituationsPage extends StatefulWidget {
  const SituationsPage({super.key});

  @override
  State<SituationsPage> createState() => _SituationsPageState();
}

class _SituationsPageState extends State<SituationsPage> {
  List<SituationCategory> _categories = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSituations();
  }

  Future<void> _loadSituations() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/data/situations.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      
      setState(() {
        _categories = (jsonData['categories'] as List)
            .map((category) => SituationCategory.fromJson(category))
            .toList();
        _isLoading = false;
      });
      
      AppLogger.d('Загружено ${_categories.length} категорий ситуаций');
    } catch (e) {
      AppLogger.e('Ошибка загрузки ситуаций: $e');
      setState(() {
        _error = 'Не удалось загрузить контент';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Жизненные ситуации'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _error = null;
                });
                _loadSituations();
              },
              child: const Text('Попробовать снова'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Выбери то, что тебя волнует',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Айк поможет разобраться с любой жизненной ситуацией',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 24),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.1,
            ),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final category = _categories[index];
              return _CategoryCard(
                category: category,
                onTap: () => _navigateToCategory(category),
              );
            },
          ),
        ],
      ),
    );
  }

  void _navigateToCategory(SituationCategory category) {
    context.push('/situations/${category.id}', extra: category);
  }
}

class _CategoryCard extends StatelessWidget {
  final SituationCategory category;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.category,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(int.parse(category.color.replaceFirst('#', '0xFF'))),
                Color(int.parse(category.color.replaceFirst('#', '0xFF'))).withValues(alpha: 0.8),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                _getIconData(category.icon),
                size: 32,
                color: Colors.white,
              ),
              const Spacer(),
              Text(
                category.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '${category.subcategories.length} тем',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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

class SituationCategory {
  final String id;
  final String title;
  final String icon;
  final String color;
  final String description;
  final List<SituationSubcategory> subcategories;

  SituationCategory({
    required this.id,
    required this.title,
    required this.icon,
    required this.color,
    required this.description,
    required this.subcategories,
  });

  factory SituationCategory.fromJson(Map<String, dynamic> json) {
    return SituationCategory(
      id: json['id'],
      title: json['title'],
      icon: json['icon'],
      color: json['color'],
      description: json['description'],
      subcategories: (json['subcategories'] as List)
          .map((sub) => SituationSubcategory.fromJson(sub))
          .toList(),
    );
  }
}

class SituationSubcategory {
  final String id;
  final String title;
  final String description;
  final String article;
  final List<String> chatPrompts;

  SituationSubcategory({
    required this.id,
    required this.title,
    required this.description,
    required this.article,
    required this.chatPrompts,
  });

  factory SituationSubcategory.fromJson(Map<String, dynamic> json) {
    return SituationSubcategory(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      article: json['article'],
      chatPrompts: List<String>.from(json['chat_prompts']),
    );
  }
}