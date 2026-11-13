// Modo de demonstração: roda as páginas internas sem Firebase, com um
// usuário e um repositório falsos. Serve para conferir o layout:
//
//   flutter run -d chrome -t test/demo_main.dart
//
// Parâmetros opcionais na URL (antes do #): plate, pieces, level, check=1,
// lang, theme=dark|light, scale, sound=1, mode=random|specific|adventure,
// start=1 (começa uma aventura).
import 'dart:convert';

import 'package:emplake/app.dart';
import 'package:emplake/core/providers.dart';
import 'package:emplake/data/progress_repository.dart';
import 'package:emplake/game/adventure_controller.dart';
import 'package:emplake/game/game_controller.dart';
import 'package:emplake/game/game_mode.dart';
import 'package:emplake/game/tokens.dart';
import 'package:emplake/routing/app_router.dart';
import 'package:emplake/ui/help_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final query = Uri.base.queryParameters;

  final plate = query['plate'];
  if (plate != null) {
    await prefs.setString(
      'game.demo',
      jsonEncode({
        'level': query['level'] ?? 'easy',
        'plate': plate,
        'pieces': query['pieces'] ??
            '${plate.substring(0, 2)}=${plate.substring(2)}',
        'solved': false,
      }),
    );
  }
  if (query['mode'] != null) {
    await prefs.setString(GameModeController.prefsKey, query['mode']!);
  }
  if (query['lang'] != null) {
    await prefs.setString('settings.language', query['lang']!);
  }
  if (query['theme'] != null) {
    await prefs.setString('settings.themeMode', query['theme']!);
  }
  if (query['scale'] != null) {
    await prefs.setDouble('settings.fontScale', double.parse(query['scale']!));
  }

  final repo = FakeProgressRepository(
    delay: const Duration(milliseconds: 300),
    solved: {
      '0427': Level.easy,
      '1236': Level.hard,
      '2468': Level.intermediate,
      '3319': Level.advanced,
      '5510': Level.easy,
      '9981': Level.intermediate,
    },
    skipped: 3,
    others: const [
      RankEntry(uid: 'a', name: 'Ada', score: 42, solvedCount: 20),
      RankEntry(uid: 'b', name: 'Gauss', score: 17, solvedCount: 9),
      RankEntry(uid: 'c', name: 'Noether', score: 8, solvedCount: 5),
      RankEntry(uid: 'd', name: null, score: 3, solvedCount: 2),
    ],
  );
  final container = ProviderContainer(
    overrides: [
      sharedPrefsProvider.overrideWithValue(prefs),
      authSessionProvider.overrideWithValue(
        AuthSession(const AppUser(uid: 'demo', email: 'demo@example.com')),
      ),
      progressRepositoryProvider.overrideWithValue(repo),
    ],
  );
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const EmplakeApp(),
    ),
  );

  if (query['help'] == '1') {
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    final context = container
        .read(appRouterProvider)
        .routerDelegate
        .navigatorKey
        .currentContext;
    if (context != null && context.mounted) showHelpDialog(context);
  }

  if (query['start'] == '1') {
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    container.read(adventureProvider.notifier).start();
  }

  if (query['check'] == '1') {
    final game = container.read(gameProvider.notifier);
    await game.ensureReady();
    await Future<void>.delayed(const Duration(milliseconds: 800));
    await game.check();
  }
}
