import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'situations_page.dart';
import '../../components/navigation/navigation.dart';

class CategoryDetailPage extends StatelessWidget {
  final SituationCategory category;

  const CategoryDetailPage({
    super.key,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    return AicScaffold(
      title: category.title,
      appBarBackgroundColor: Color(int.parse(category.color.replaceFirst('#', '0xFF'))),
      showBottomNavigation: false,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              height: 200,
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
              child: Center(
                child: Icon(
                  _getIconData(category.icon),
                  size: 80,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.description,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Выбери подходящую тему',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                        ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final subcategory = category.subcategories[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: _SubcategoryCard(
                    subcategory: subcategory,
                    categoryColor: Color(int.parse(category.color.replaceFirst('#', '0xFF'))),
                    onTap: () => _navigateToSubcategory(context, subcategory),
                  ),
                );
              },
              childCount: category.subcategories.length,
            ),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 16),
          ),
        ],
      ),
    );
  }

  void _navigateToSubcategory(BuildContext context, SituationSubcategory subcategory) {
    context.push('/situations/${category.id}/${subcategory.id}', extra: {
      'category': category,
      'subcategory': subcategory,
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

class _SubcategoryCard extends StatelessWidget {
  final SituationSubcategory subcategory;
  final Color categoryColor;
  final VoidCallback onTap;

  const _SubcategoryCard({
    required this.subcategory,
    required this.categoryColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 60,
                decoration: BoxDecoration(
                  color: categoryColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subcategory.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: categoryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subcategory.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}