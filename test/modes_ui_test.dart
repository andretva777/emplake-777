import 'dart:convert';

import 'package:emplake/game/adventure_controller.dart';
import 'package:emplake/game/game_controller.dart';
import 'package:emplake/game/game_mode.dart';
import 'package:emplake/game/tokens.dart';
import 'package:emplake/ui/game/operator_tray.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_harness.dart';
import 'fakes.dart';

void main() {
  testWidgets('o seletor troca de modo e cada modo mostra a sua tela',
      (tester) async {
    final c = await pumpApp(
      tester,
      prefs: {'game.demo': savedClassic('8131', '81=31')},
    );
    expect(find.text('8131'), findsOneWidget); // a placa sorteada

    await tester.tap(find.text('Específico'));
    await settle(tester);
    expect(c.read(gameModeProvider), GameMode.specific);
    expect(find.text('Escolha a placa'), findsOneWidget);

    await tester.tap(find.text('Aventura'));
    await settle(tester);
    expect(find.text('Começar aventura'), findsOneWidget);

    await tester.tap(find.text('Aleatório'));
    await settle(tester);
    expect(c.read(gameProvider).plate, '8131');
  });

  testWidgets('modo específico: digitar a placa e jogar', (tester) async {
    final c = await pumpApp(
      tester,
      prefs: {'game.mode': 'specific'},
      repo: FakeProgressRepository(solved: {'2222': Level.easy}),
    );
    final field = find.byType(TextField);
    expect(field, findsOneWidget);

    // Só dígitos entram, e no máximo quatro.
    await tester.enterText(field, '9a9');
    await tester.pump();
    expect(find.text('99'), findsOneWidget);

    // Placa já resolvida: avisa que não vale pontos.
    await tester.enterText(field, '2222');
    await tester.pump();
    expect(find.textContaining('não ganha pontos'), findsOneWidget);

    await tester.enterText(field, '8131');
    await tester.pump();
    await tester.tap(find.text('Jogar'));
    await settle(tester);
    expect(c.read(gameProvider).plate, '8131');
    expect(find.text('Trocar placa'), findsOneWidget);

    await tester.tap(find.text('Trocar placa'));
    await settle(tester);
    expect(c.read(gameProvider).plate, isNull);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('modo específico: placa sem solução no nível é recusada',
      (tester) async {
    final c = await pumpApp(
      tester,
      prefs: {
        'game.mode': 'specific',
        'game.demo.specific': jsonEncode({'level': 'hard'}),
      },
    );
    await tester.enterText(find.byType(TextField), '8131');
    await tester.pump();
    await tester.tap(find.text('Jogar'));
    await settle(tester);
    expect(c.read(gameProvider).plate, isNull);
    expect(find.textContaining('não tem solução'), findsOneWidget);
  });

  testWidgets('aventura: começar, comprar um operador e desistir',
      (tester) async {
    final c = await pumpApp(tester, prefs: {'game.mode': 'adventure'});
    await tester.tap(find.text('Começar aventura'));
    await settle(tester);
    expect(c.read(adventureProvider).phase, AdventurePhase.playing);
    expect(find.text('Moedas'), findsOneWidget);
    expect(find.text('2000'), findsOneWidget);

    // A raiz começa bloqueada; tocar nela abre a compra.
    await tester.tap(find.byKey(OperatorTray.valueKeyFor(Tok.sqrt)));
    await settle(tester);
    expect(find.text('Comprar √?'), findsOneWidget);
    await tester.tap(find.text('Comprar'));
    await settle(tester);
    expect(c.read(adventureProvider).money, 1000);
    expect(c.read(adventureProvider).rules.allows(Tok.sqrt), isTrue);

    await tester.tap(find.byTooltip('Desistir'));
    await settle(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Desistir'));
    await settle(tester);
    expect(c.read(adventureProvider).phase, AdventurePhase.over);
    expect(find.text('Fim da aventura'), findsOneWidget);
    expect(find.text('Nova aventura'), findsOneWidget);
  });

  testWidgets('aventura: o prêmio cai enquanto o relógio corre',
      (tester) async {
    final c = await pumpApp(tester, prefs: {'game.mode': 'adventure'});
    await tester.tap(find.text('Começar aventura'));
    await settle(tester);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 100));
    final s = c.read(adventureProvider);
    expect(s.elapsed, greaterThanOrEqualTo(3));
    expect(s.reward, lessThan(AdventureEconomy.potStart));

    // Fora da tela (outra aba), o relógio para.
    await tester.tap(find.byTooltip('Progresso'));
    await settle(tester);
    final paused = c.read(adventureProvider).elapsed;
    await tester.pump(const Duration(seconds: 3));
    expect(c.read(adventureProvider).elapsed, paused);
  });

  testWidgets('trocar de modo com um tabuleiro na tela não quebra',
      (tester) async {
    final c = await pumpApp(
      tester,
      prefs: {'game.demo': savedClassic('8131', '81=31')},
    );
    // Aventura em andamento -> aleatório -> aventura: durante a transição,
    // os dois tabuleiros (cada um com o seu teclado) ficam na tela.
    await tester.tap(find.text('Aventura'));
    await settle(tester);
    await tester.tap(find.text('Começar aventura'));
    await settle(tester);
    expect(c.read(adventureProvider).phase, AdventurePhase.playing);

    await tester.tap(find.text('Aleatório'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await settle(tester);
    expect(c.read(gameModeProvider), GameMode.random);

    await tester.tap(find.text('Aventura'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await settle(tester);
    expect(tester.takeException(), isNull);
  });
}
