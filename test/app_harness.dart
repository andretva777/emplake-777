import 'dart:convert';

import 'package:emplake/app.dart';
import 'package:emplake/core/providers.dart';
import 'package:emplake/data/progress_repository.dart';
import 'package:emplake/game/tokens.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

/// Partida clássica salva (modo aleatório).
String savedClassic(String plate, String pieces, {String level = 'easy'}) =>
    jsonEncode({
      'level': level,
      'plate': plate,
      'pieces': pieces,
      'solved': false,
    });

/// Linha em texto compacto ("8+1=31").
String lineOf(List<Piece> pieces) => pieces
    .map((p) => switch (p) {
          DigitPiece(:final value) => '$value',
          EqualsPiece() => '=',
          OpPiece(:final tok) => tok.code,
        })
    .join();

/// Monta o aplicativo inteiro já logado, com repositório em memória, em
/// português e numa tela de 900 x 1400.
Future<ProviderContainer> pumpApp(
  WidgetTester tester, {
  Map<String, Object> prefs = const {},
  FakeProgressRepository? repo,
}) async {
  tester.view.physicalSize = const Size(900, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  GoogleFonts.config.allowRuntimeFetching = false;

  SharedPreferences.setMockInitialValues({
    'settings.language': 'pt',
    ...prefs,
  });
  final sharedPrefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      sharedPrefsProvider.overrideWithValue(sharedPrefs),
      authSessionProvider.overrideWithValue(
        AuthSession(const AppUser(uid: 'demo', email: 'demo@example.com')),
      ),
      progressRepositoryProvider
          .overrideWithValue(repo ?? FakeProgressRepository()),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const EmplakeApp()),
  );
  await settle(tester);
  return container;
}

/// Avança o relógio o suficiente para carregamentos e animações curtas (sem
/// `pumpAndSettle`, que nunca termina com o indicador de carregamento).
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 150));
  }
}

/// Arrasta de [from] até [to] em passos, como um dedo ou mouse.
Future<void> drag(
  WidgetTester tester,
  Offset from,
  Offset to, {
  PointerDeviceKind kind = PointerDeviceKind.touch,
}) async {
  final gesture = await tester.startGesture(from, kind: kind);
  await tester.pump(const Duration(milliseconds: 50));
  const steps = 8;
  for (var i = 1; i <= steps; i++) {
    await gesture.moveTo(Offset.lerp(from, to, i / steps)!);
    await tester.pump(const Duration(milliseconds: 16));
  }
  await gesture.up();
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(seconds: 1)); // voo de volta, se houver
}
