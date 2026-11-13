import 'dart:convert';

import 'package:emplake/app.dart';
import 'package:emplake/core/providers.dart';
import 'package:emplake/game/game_controller.dart';
import 'package:emplake/game/tokens.dart';
import 'package:emplake/data/progress_repository.dart';
import 'package:emplake/ui/game/equation_line.dart';
import 'package:emplake/ui/game/operator_tray.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

String line(GameState s) => s.pieces
    .map((p) => switch (p) {
          DigitPiece(:final value) => '$value',
          EqualsPiece() => '=',
          OpPiece(:final tok) => tok.code,
        })
    .join();

Future<ProviderContainer> pumpGame(
  WidgetTester tester, {
  String pieces = '81=31',
}) async {
  tester.view.physicalSize = const Size(900, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  GoogleFonts.config.allowRuntimeFetching = false;

  SharedPreferences.setMockInitialValues({
    'game.demo': jsonEncode({
      'level': 'easy',
      'plate': '8131',
      'pieces': pieces,
      'solved': false,
    }),
  });
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      sharedPrefsProvider.overrideWithValue(prefs),
      authSessionProvider.overrideWithValue(
        AuthSession(const AppUser(uid: 'demo', email: 'demo@example.com')),
      ),
      progressRepositoryProvider.overrideWithValue(FakeProgressRepository()),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const EmplakeApp()),
  );
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 500));
  return container;
}

/// Arrasta de [from] até [to] em passos, como um dedo ou mouse.
Future<void> drag(WidgetTester tester, Offset from, Offset to) async {
  final gesture = await tester.startGesture(from);
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

void main() {
  testWidgets('arrastar um operador do teclado para a linha o insere',
      (tester) async {
    final c = await pumpGame(tester);
    final key = find.byKey(OperatorTray.keyFor(Tok.sqrt));
    expect(key, findsOneWidget);

    // Metade esquerda do dígito 8: entra antes dele.
    final eight = tester.getCenter(find.text('8'));
    await drag(tester, tester.getCenter(key), eight - const Offset(14, 0));
    expect(line(c.read(gameProvider)), 'r81=31');
  });

  testWidgets('soltar no lado direito de uma peça insere depois dela',
      (tester) async {
    final c = await pumpGame(tester);
    final key = find.byKey(OperatorTray.keyFor(Tok.plus));
    final eight = tester.getCenter(find.text('8'));
    await drag(tester, tester.getCenter(key), eight + const Offset(14, 0));
    expect(line(c.read(gameProvider)), '8+1=31');
  });

  testWidgets('soltar fora da linha não insere nada', (tester) async {
    final c = await pumpGame(tester);
    final key = find.byKey(OperatorTray.keyFor(Tok.plus));
    await drag(tester, tester.getCenter(key), const Offset(20, 1300));
    expect(line(c.read(gameProvider)), '81=31');
    expect(tester.takeException(), isNull);
  });

  testWidgets('arrastar o = muda a posição dele', (tester) async {
    final c = await pumpGame(tester);
    final equals = find.text('=');
    final last = tester.getCenter(find.text('1').last);
    await drag(tester, tester.getCenter(equals), last + const Offset(14, 0));
    expect(line(c.read(gameProvider)), '8131=');
  });

  testWidgets('arrastar um operador da linha para fora o devolve',
      (tester) async {
    final c = await pumpGame(tester, pieces: '8+1=31');
    final op = find.byKey(
      EquationLine.keyFor(c.read(gameProvider).pieces[1]),
    );
    expect(op, findsOneWidget);
    await drag(tester, tester.getCenter(op), const Offset(20, 1300));
    expect(line(c.read(gameProvider)), '81=31');
  });

  testWidgets('arrastar um operador dentro da linha o reposiciona',
      (tester) async {
    final c = await pumpGame(tester, pieces: '8+1=31');
    final op = find.byKey(
      EquationLine.keyFor(c.read(gameProvider).pieces[1]),
    );
    final three = tester.getCenter(find.text('3'));
    await drag(tester, tester.getCenter(op), three + const Offset(14, 0));
    expect(line(c.read(gameProvider)), '81=3+1');
  });

  testWidgets('tocar em um operador da linha o devolve ao teclado',
      (tester) async {
    final c = await pumpGame(tester, pieces: '8+1=31');
    final op = find.byKey(
      EquationLine.keyFor(c.read(gameProvider).pieces[1]),
    );
    await tester.tap(op);
    await tester.pump(const Duration(seconds: 1));
    expect(line(c.read(gameProvider)), '81=31');
  });
}
