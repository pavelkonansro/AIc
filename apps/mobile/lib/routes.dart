import 'package:go_router/go_router.dart';
import 'features/auth/auth_page.dart';
import 'features/chat/chat_page.dart';
import 'features/profile/profile_page.dart';
import 'features/sos/sos_page.dart';

final router = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (_, __) => const AuthPage()),
    GoRoute(path: '/profile', builder: (_, __) => const ProfilePage()),
    GoRoute(path: '/chat', builder: (_, __) => const ChatPage()),
    GoRoute(path: '/sos', builder: (_, __) => const SosPage()),
  ],
);



