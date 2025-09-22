import 'package:go_router/go_router.dart';
import 'features/auth/auth_page.dart';
import 'features/chat/chat_page.dart';
import 'features/chat/chat_page_fixed.dart';
import 'features/home/home_dashboard_page.dart';
import 'features/motivation/motivation_page.dart';
import 'features/meditation/meditation_page.dart';
import 'features/tips/tips_page.dart';
import 'features/support/support_page.dart';
import 'features/settings/settings_page.dart';
import 'features/profile/profile_page.dart';
import 'features/sos/sos_page.dart';
import 'features/situations/situations_page.dart';
import 'features/situations/category_detail_page.dart';
import 'features/situations/subcategory_detail_page.dart';

final router = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (_, __) => const AuthPage()),
    GoRoute(path: '/home', builder: (_, __) => const HomeDashboardPage()),
    GoRoute(path: '/profile', builder: (_, __) => const ProfilePage()),
    GoRoute(
      path: '/chat', 
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return ChatPageFixed(
          initialMessage: extra?['initialMessage'],
          context: extra?['context'],
        );
      },
    ),
    GoRoute(path: '/chat-old', builder: (_, __) => const ChatPage()),
    GoRoute(path: '/motivation', builder: (_, __) => const MotivationPage()),
    GoRoute(path: '/meditation', builder: (_, __) => const MeditationPage()),
    GoRoute(path: '/tips', builder: (_, __) => const TipsPage()),
    GoRoute(path: '/support', builder: (_, __) => const SupportPage()),
    GoRoute(path: '/settings', builder: (_, __) => const SettingsPage()),
    GoRoute(path: '/sos', builder: (_, __) => const SosPage()),
    GoRoute(path: '/situations', builder: (_, __) => const SituationsPage()),
    GoRoute(
      path: '/situations/:categoryId',
      builder: (context, state) {
        final category = state.extra as SituationCategory;
        return CategoryDetailPage(category: category);
      },
    ),
    GoRoute(
      path: '/situations/:categoryId/:subcategoryId',
      builder: (context, state) {
        final data = state.extra as Map<String, dynamic>;
        final category = data['category'] as SituationCategory;
        final subcategory = data['subcategory'] as SituationSubcategory;
        return SubcategoryDetailPage(
          category: category,
          subcategory: subcategory,
        );
      },
    ),
  ],
);
