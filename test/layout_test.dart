import 'package:emplake/game/game_controller.dart';
import 'package:emplake/ui/game/board_parts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_harness.dart';

void main() {
  for (final size in [
    const Size(360, 640),
    const Size(390, 780),
    const Size(1280, 800),
  ]) {
    testWidgets(
        'Verificar e o resultado ficam na tela sem rolar '
        '(${size.width.toInt()}x${size.height.toInt()})', (tester) async {
      final c = await pumpApp(
        tester,
        prefs: {'game.demo': savedClassic('8131', '81=31')},
      );
      tester.view.physicalSize = size;
      await settle(tester);
      final screen = Offset.zero & size;

      final verify = find.byKey(const ValueKey('verify'));
      expect(verify, findsOneWidget);
      expect(screen.contains(tester.getRect(verify).topLeft), isTrue);
      expect(screen.contains(tester.getRect(verify).bottomRight), isTrue);
      // O rodapé tem os botões e fica dentro da tela.
      final footer = find.byKey(BoardLayout.footerKey);
      expect(
        find.descendant(of: footer, matching: verify),
        findsOneWidget,
      );

      // "81=31" não tem operador entre os dígitos: erro.
      await tester.tap(verify);
      await settle(tester);
      expect(c.read(gameProvider).feedback, isA<FeedbackError>());
      final message = find.descendant(
        of: footer,
        matching: find.textContaining('Falta um operador'),
      );
      expect(message, findsOneWidget);
      final r = tester.getRect(message);
      expect(screen.contains(r.topLeft) && screen.contains(r.bottomRight),
          isTrue,
          reason: 'aviso fora da tela: $r');
      // A linha continua como estava.
      expect(lineOf(c.read(gameProvider).pieces), '81=31');
    });
  }
}
