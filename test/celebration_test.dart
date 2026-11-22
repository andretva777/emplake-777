import 'dart:convert';

import 'package:emplake/game/adventure_controller.dart';
import 'package:emplake/game/game_controller.dart';
import 'package:emplake/ui/game/board_parts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_harness.dart';
import 'fakes.dart';

void main() {
  final badge = find.byType(CelebrationBadge);

  /// Deixa a comemoração terminar (o relógio da animação começa no quadro
  /// seguinte ao que a mostrou).
  Future<void> waitBadge(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(CelebrationBadge.duration);
    await tester.pump();
  }

  testWidgets('acerto: comemora sem avançar a placa e o selo some sozinho',
      (tester) async {
    final c = await pumpApp(
      tester,
      prefs: {'game.demo': savedClassic('2222', '2+2=2*2')},
    );
    expect(badge, findsNothing);

    await tester.tap(find.byKey(const ValueKey('verify')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(badge, findsOneWidget);
    expect(
      find.descendant(of: badge, matching: find.text('Correto! +1 ponto')),
      findsOneWidget,
    );
    // A placa continua; o jogador avança quando quiser.
    expect(c.read(gameProvider).plate, '2222');
    expect(c.read(gameProvider).solved, isTrue);
    expect(find.byKey(const ValueKey('next')), findsOneWidget);

    await waitBadge(tester);
    expect(badge, findsNothing);
    expect(c.read(gameProvider).plate, '2222');
  });

  testWidgets('o selo não bloqueia: dá para ir à próxima placa na hora',
      (tester) async {
    final c = await pumpApp(
      tester,
      prefs: {'game.demo': savedClassic('2222', '2+2=2*2')},
    );
    await tester.tap(find.byKey(const ValueKey('verify')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(badge, findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('next')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(c.read(gameProvider).plate, isNot('2222'));
    expect(c.read(gameProvider).solved, isFalse);
    await waitBadge(tester);
  });

  testWidgets('erro não comemora', (tester) async {
    await pumpApp(
      tester,
      prefs: {'game.demo': savedClassic('2222', '2+2=2+2+2')},
    );
    await tester.tap(find.byKey(const ValueKey('verify')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(badge, findsNothing);
  });

  testWidgets('falha ao gravar não repete a comemoração', (tester) async {
    await pumpApp(
      tester,
      prefs: {'game.demo': savedClassic('2222', '2+2=2*2')},
      repo: FakeProgressRepository(failWrites: true),
    );
    final c = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
    );
    await tester.tap(find.byKey(const ValueKey('verify')));
    await tester.pump(const Duration(milliseconds: 300));
    // A gravação falhou e a mensagem de acerto foi trocada pela de falha...
    expect(
      (c.read(gameProvider).feedback as FeedbackCorrect).saveFailed,
      isTrue,
    );
    // ...sem um segundo selo.
    expect(badge, findsOneWidget);
    await waitBadge(tester);
    expect(badge, findsNothing);
  });

  testWidgets('aventura: acerto comemora com as moedas ganhas', (tester) async {
    final c = await pumpApp(tester, prefs: {
      'game.mode': 'adventure',
      'adventure.demo': jsonEncode({
        'phase': 'playing',
        'money': 2000,
        'count': 0,
        'unlocked': '',
        'plate': '2222',
        'pieces': '2+2=2*2',
        'elapsed': 0,
        'solved': false,
        'best': 0,
      }),
    });
    await tester.tap(find.byKey(const ValueKey('verify')));
    await tester.pump(const Duration(milliseconds: 300));
    final coins = (c.read(adventureProvider).feedback as FeedbackReward).coins;
    expect(
      find.descendant(
        of: badge,
        matching: find.text('Correto! +$coins moedas'),
      ),
      findsOneWidget,
    );
    expect(c.read(adventureProvider).plate, '2222');
    await waitBadge(tester);
    expect(badge, findsNothing);
  });
}
