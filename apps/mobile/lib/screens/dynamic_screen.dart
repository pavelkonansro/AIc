import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/block_renderer.dart';
import '../components/navigation/navigation.dart';

class DynamicScreen extends ConsumerWidget {
  final String screenName;

  const DynamicScreen({
    super.key,
    required this.screenName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenDataAsync = ref.watch(screenDataProvider(screenName));

    return screenDataAsync.when(
      data: (screenData) => _buildScreen(context, screenData),
      loading: () => AicMainScaffold(
        title: 'Загрузка...',
        body: const Center(child: CircularProgressIndicator()),
        currentRoute: '/$screenName',
      ),
      error: (error, stack) => AicMainScaffold(
        title: 'Ошибка',
        body: Center(
          child: Text('Ошибка загрузки экрана: $error'),
        ),
        currentRoute: '/$screenName',
      ),
    );
  }

  Widget _buildScreen(BuildContext context, Map<String, dynamic> screenData) {
    final blocks = screenData['blocks'] as List<dynamic>;
    final title = screenData['title'] as String? ?? screenName;

    return AicMainScaffold(
      title: title,
      currentRoute: '/$screenName',
      body: CustomScrollView(
        slivers: [
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final blockData = blocks[index] as Map<String, dynamic>;
                return BlockRenderer(blockData: blockData);
              },
              childCount: blocks.length,
            ),
          ),
        ],
      ),
    );
  }
}