import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/providers.dart';
import '../ui/app_shell.dart';
import '../ui/game/game_page.dart';
import '../ui/login_page.dart';
import '../ui/progress_page.dart';
import '../ui/settings_page.dart';

abstract final class AppRoutes {
  static const login = '/login';
  static const game = '/game';
  static const progress = '/progress';
  static const settings = '/settings';

  /// Páginas internas, na ordem dos ramos do shell.
  static const shell = [game, progress, settings];

  /// Chave do SharedPreferences com a última página visitada.
  static const lastRouteKey = 'nav.lastRoute';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final session = ref.watch(authSessionProvider);
  final prefs = ref.watch(sharedPrefsProvider);

  /// Página em que o usuário estava quando fechou o aplicativo.
  String lastRoute() {
    final saved = prefs.getString(AppRoutes.lastRouteKey);
    return AppRoutes.shell.contains(saved) ? saved! : AppRoutes.game;
  }

  final router = GoRouter(
    initialLocation: lastRoute(),
    refreshListenable: session,
    redirect: (context, state) {
      final loggedIn = session.user != null;
      final location = state.matchedLocation;
      if (!loggedIn) {
        return location == AppRoutes.login ? null : AppRoutes.login;
      }
      if (location == AppRoutes.login || location == '/') return lastRoute();
      if (AppRoutes.shell.contains(location)) {
        prefs.setString(AppRoutes.lastRouteKey, location);
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', redirect: (_, _) => lastRoute()),
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: LoginPage()),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.game,
              builder: (context, state) => const GamePage(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.progress,
              builder: (context, state) => const ProgressPage(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.settings,
              builder: (context, state) => const SettingsPage(),
            ),
          ]),
        ],
      ),
    ],
    errorBuilder: (context, state) => const SizedBox.shrink(),
    onException: (context, state, router) => router.go(lastRoute()),
  );
  ref.onDispose(router.dispose);
  return router;
});
