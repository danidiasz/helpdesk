import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'ui/login_screen.dart';
import 'ui/scaffold_with_nav_bar.dart';
import 'ui/home_tab.dart';
import 'ui/search_history_tab.dart';
import 'ui/suggestions_tab.dart';
import 'ui/profile_tab.dart';
import 'ui/chat_screen.dart';
import 'ui/category_list_screen.dart';
import 'ui/category_detail_screen.dart';
import 'ui/faq_detail_screen.dart';
import 'ui/profile/account_data_screen.dart';
import 'ui/profile/activity_center_screen.dart';
import 'ui/profile/favorites_screen.dart';
import 'ui/admin/admin_console_screen.dart';
import 'ui/knowledge_base_screen.dart';

// Keys for shell branches
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorHomeKey = GlobalKey<NavigatorState>(debugLabel: 'shellHome');
final _shellNavigatorHistoryKey = GlobalKey<NavigatorState>(debugLabel: 'shellHistory');
final _shellNavigatorSuggestionsKey = GlobalKey<NavigatorState>(debugLabel: 'shellSuggestions');
final _shellNavigatorKnowledgeKey = GlobalKey<NavigatorState>(debugLabel: 'shellKnowledge');
final _shellNavigatorProfileKey = GlobalKey<NavigatorState>(debugLabel: 'shellProfile');

class AppRouter {
  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            navigatorKey: _shellNavigatorHomeKey,
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeTab(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorHistoryKey,
            routes: [
              GoRoute(
                path: '/history',
                builder: (context, state) => const SearchHistoryTab(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorSuggestionsKey,
            routes: [
              GoRoute(
                path: '/suggestions',
                builder: (context, state) => const SuggestionsTab(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorKnowledgeKey,
            routes: [
              GoRoute(
                path: '/knowledge',
                builder: (context, state) => const KnowledgeBaseScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorProfileKey,
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileTab(),
                routes: [
                   GoRoute(
                    path: 'account',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const AccountDataScreen(),
                  ),
                  GoRoute(
                    path: 'activity',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const ActivityCenterScreen(),
                  ),
                  GoRoute(
                    path: 'favorites',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const FavoritesScreen(),
                  ),
                ]
              ),
            ],
          ),
        ],
      ),
      // Top level routes
      GoRoute(
        path: '/chat',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final initialQuery = state.uri.queryParameters['q'];
          final sessionId = state.uri.queryParameters['sessionId'];
          return ChatScreen(initialQuery: initialQuery, sessionId: sessionId);
        },
      ),
      GoRoute(
        path: '/categories',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CategoryListScreen(),
      ),
      GoRoute(
        path: '/category/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return CategoryDetailScreen(categoryId: id);
        },
      ),
      GoRoute(
        path: '/faq/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return FAQDetailScreen(faqId: id);
        },
      ),
      GoRoute(
        path: '/admin/console',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AdminConsoleScreen(),
      ),
    ],
  );
}
