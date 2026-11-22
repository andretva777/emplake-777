import 'package:emplake/game/game_controller.dart';
import 'package:emplake/game/tokens.dart';
import 'package:emplake/ui/game/drag_payload.dart';
import 'package:emplake/ui/game/equation_line.dart';
import 'package:emplake/ui/game/operator_tray.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    final key = find.byKey(OperatorTray.valueKeyFor(Tok.sqrt));
    expect(key, findsOneWidget);

    // Metade esquerda do dígito 8: entra antes dele.
    final eight = tester.getCenter(find.text('8'));
    await drag(tester, tester.getCenter(key), eight - const Offset(14, 0));
    expect(line(c.read(gameProvider)), 'r81=31');
  });

  testWidgets('soltar no lado direito de uma peça insere depois dela',
      (tester) async {
    final c = await pumpGame(tester);
    final key = find.byKey(OperatorTray.valueKeyFor(Tok.plus));
    final eight = tester.getCenter(find.text('8'));
    await drag(tester, tester.getCenter(key), eight + const Offset(14, 0));
    expect(line(c.read(gameProvider)), '8+1=31');
  });

  testWidgets('soltar fora da linha não insere nada', (tester) async {
    final c = await pumpGame(tester);
    final key = find.byKey(OperatorTray.valueKeyFor(Tok.plus));
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
      EquationLine.valueKeyFor(c.read(gameProvider).pieces[1]),
    );
    expect(op, findsOneWidget);
    await drag(tester, tester.getCenter(op), const Offset(20, 1300));
    expect(line(c.read(gameProvider)), '81=31');
  });

  testWidgets('arrastar um operador dentro da linha o reposiciona',
      (tester) async {
    final c = await pumpGame(tester, pieces: '8+1=31');
    final op = find.byKey(
      EquationLine.valueKeyFor(c.read(gameProvider).pieces[1]),
    );
    final three = tester.getCenter(find.text('3'));
    await drag(tester, tester.getCenter(op), three + const Offset(14, 0));
    expect(line(c.read(gameProvider)), '81=3+1');
  });

  testWidgets('tocar em um operador da linha põe o cursor, sem apagá-lo',
      (tester) async {
    final c = await pumpGame(tester, pieces: '8+1=31');
    final op = find.byKey(
      EquationLine.valueKeyFor(c.read(gameProvider).pieces[1]),
    );
    await tester.tapAt(tester.getCenter(op) + const Offset(10, 0));
    await tester.pump(const Duration(seconds: 1));
    expect(line(c.read(gameProvider)), '8+1=31');
    expect(c.read(gameProvider).caret, 2);
    await tester.tapAt(tester.getCenter(op) - const Offset(10, 0));
    await tester.pump();
    expect(c.read(gameProvider).caret, 1);
  });

  testWidgets('tocar numa tecla insere o operador no cursor', (tester) async {
    final c = await pumpGame(tester);
    // O cursor aparece na linha, no começo.
    expect(find.byKey(const ValueKey('caret')), findsOneWidget);
    expect(c.read(gameProvider).caret, 0);

    // Lado direito do 8: o cursor vai para entre o 8 e o 1.
    await tester.tapAt(tester.getCenter(find.text('8')) + const Offset(12, 0));
    await tester.pump();
    expect(c.read(gameProvider).caret, 1);

    await tester.tap(find.byKey(OperatorTray.valueKeyFor(Tok.plus)));
    await tester.pump(const Duration(milliseconds: 300));
    expect(line(c.read(gameProvider)), '8+1=31');
    // O cursor avança: o próximo operador entra depois do +.
    await tester.tap(find.byKey(OperatorTray.valueKeyFor(Tok.sqrt)));
    await tester.pump(const Duration(milliseconds: 300));
    expect(line(c.read(gameProvider)), '8+r1=31');
    expect(c.read(gameProvider).caret, 3);
  });

  testWidgets('a tecla apagar tira o operador à esquerda do cursor',
      (tester) async {
    final c = await pumpGame(tester, pieces: '8+1=31');
    final delete = find.byKey(OperatorTray.deleteKey);
    // Cursor no começo: não há o que apagar.
    expect(tester.widget<TextButton>(delete).onPressed, isNull);

    final op = find.byKey(
      EquationLine.valueKeyFor(c.read(gameProvider).pieces[1]),
    );
    await tester.tapAt(tester.getCenter(op) + const Offset(10, 0));
    await tester.pump();
    await tester.tap(delete);
    await tester.pump(const Duration(seconds: 1));
    expect(line(c.read(gameProvider)), '81=31');
    expect(c.read(gameProvider).caret, 1);
    // À esquerda do cursor agora está o 8: dígitos não são apagados.
    expect(tester.widget<TextButton>(delete).onPressed, isNull);
  });

  testWidgets('o teclado do computador edita a linha', (tester) async {
    final c = await pumpGame(tester);
    Future<void> type(LogicalKeyboardKey key, [String? character]) async {
      await tester.sendKeyDownEvent(key, character: character);
      await tester.sendKeyUpEvent(key);
      await tester.pump();
    }

    await type(LogicalKeyboardKey.arrowRight);
    expect(c.read(gameProvider).caret, 1);
    await type(LogicalKeyboardKey.numpadAdd, '+');
    expect(line(c.read(gameProvider)), '8+1=31');
    await type(LogicalKeyboardKey.keyR, 'r');
    expect(line(c.read(gameProvider)), '8+r1=31');
    await type(LogicalKeyboardKey.backspace);
    expect(line(c.read(gameProvider)), '8+1=31');
    await type(LogicalKeyboardKey.end);
    expect(c.read(gameProvider).caret, 6);
    await type(LogicalKeyboardKey.keyX, 'x');
    expect(line(c.read(gameProvider)), '8+1=31*');
    // Letras que não são operadores são ignoradas.
    await type(LogicalKeyboardKey.keyQ, 'q');
    expect(line(c.read(gameProvider)), '8+1=31*');
  });

  for (final kind in [PointerDeviceKind.touch, PointerDeviceKind.mouse]) {
    testWidgets('posição da peça arrastada com ${kind.name}', (tester) async {
      await pumpGame(tester);
      final from =
          tester.getCenter(find.byKey(OperatorTray.valueKeyFor(Tok.plus)));
      final pointer = from - const Offset(0, 200);
      final gesture = await tester.startGesture(from, kind: kind);
      await tester.pump(const Duration(milliseconds: 50));
      await gesture.moveTo(from - const Offset(0, 20));
      await tester.pump();
      await gesture.moveTo(pointer);
      await tester.pump();
      final rect = tester.getRect(find.byType(DragFeedback));
      expect(rect.center.dx, closeTo(pointer.dx, 0.5));
      if (kind == PointerDeviceKind.touch) {
        // Inteira acima do dedo, com folga.
        expect(rect.bottom, lessThan(pointer.dy - 24));
      } else {
        expect(rect.center.dy, closeTo(pointer.dy, 0.5));
      }
      await gesture.up();
      await tester.pump(const Duration(seconds: 1));
    });
  }

  testWidgets('arrastar com o mouse também funciona', (tester) async {
    final c = await pumpGame(tester);
    final key = find.byKey(OperatorTray.valueKeyFor(Tok.plus));
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
