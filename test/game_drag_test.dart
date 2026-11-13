import 'package:emplake/game/game_controller.dart';
import 'package:emplake/game/tokens.dart';
import 'package:emplake/ui/game/equation_line.dart';
import 'package:emplake/ui/game/operator_tray.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_harness.dart';

String line(GameState s) => lineOf(s.pieces);

Future<ProviderContainer> pumpGame(
  WidgetTester tester, {
  String pieces = '81=31',
}) =>
    pumpApp(tester, prefs: {'game.demo': savedClassic('8131', pieces)});

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

  testWidgets('arrastar com o mouse também funciona', (tester) async {
    final c = await pumpGame(tester);
    final key = find.byKey(OperatorTray.keyFor(Tok.plus));
    final eight = tester.getCenter(find.text('8'));
    await drag(
      tester,
      tester.getCenter(key),
      eight + const Offset(14, 0),
      kind: PointerDeviceKind.mouse,
    );
    expect(line(c.read(gameProvider)), '8+1=31');
  });
}
