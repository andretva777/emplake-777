import 'dart:convert';

import 'package:emplake/core/providers.dart';
import 'package:emplake/data/progress_repository.dart';
import 'package:emplake/game/adventure_controller.dart';
import 'package:emplake/game/game_controller.dart';
import 'package:emplake/game/line_editing.dart';
import 'package:emplake/game/solver.dart';
import 'package:emplake/game/tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

Future<(ProviderContainer, FakeProgressRepository)> setUp({
  Map<String, Object> prefs = const {},
  FakeProgressRepository? repo,
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final sharedPrefs = await SharedPreferences.getInstance();
  final repository = repo ?? FakeProgressRepository();
  final container = ProviderContainer(
    overrides: [
      sharedPrefsProvider.overrideWithValue(sharedPrefs),
      authSessionProvider.overrideWithValue(
        AuthSession(const AppUser(uid: 'demo', email: 'demo@example.com')),
      ),
      progressRepositoryProvider.overrideWithValue(repository),
    ],
  );
  addTearDown(container.dispose);
  return (container, repository);
}

/// Aventura salva no meio de uma placa.
String saved({
  String plate = '2222',
  String pieces = '22=22',
  int money = 2000,
  int count = 0,
  String unlocked = '',
  int elapsed = 0,
}) =>
    jsonEncode({
      'phase': 'playing',
      'money': money,
      'count': count,
      'unlocked': unlocked,
      'plate': plate,
      'pieces': pieces,
      'elapsed': elapsed,
      'solved': false,
      'best': 0,
    });

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('começa com dinheiro, só operadores básicos e placa com solução',
      () async {
    final (c, _) = await setUp();
    final adventure = c.read(adventureProvider.notifier);
    expect(c.read(adventureProvider).phase, AdventurePhase.intro);
    adventure.start();
    final s = c.read(adventureProvider);
    expect(s.phase, AdventurePhase.playing);
    expect(s.money, AdventureEconomy.startMoney);
    expect(s.rules.allows(Tok.plus), isTrue);
    expect(s.rules.allows(Tok.sqrt), isFalse);
    expect(
      Solver(const AdventureRules({})).isSolvable(digitsOf(s.plate!)),
      isTrue,
    );
  });

  test('operadores bloqueados não entram até serem comprados', () async {
    final (c, _) = await setUp(prefs: {'adventure.demo': saved()});
    final adventure = c.read(adventureProvider.notifier);
    adventure.insertAt(0, Tok.sqrt);
    expect(c.read(adventureProvider).hasOperators, isFalse);

    expect(adventure.buy(Upgrade.floor), isTrue);
    final s = c.read(adventureProvider);
    expect(s.money, 1000);
    expect(s.rules.allows(Tok.floorL) && s.rules.allows(Tok.floorR), isTrue);
    expect(adventure.buy(Upgrade.sqrt), isTrue);
    expect(c.read(adventureProvider).money, 0);
    expect(adventure.buy(Upgrade.pow), isFalse);
    adventure.insertAt(0, Tok.sqrt);
    expect(c.read(adventureProvider).hasOperators, isTrue);
  });

  test('acerto rende o prêmio, que cai com o tempo', () async {
    final (c, _) = await setUp(
      prefs: {'adventure.demo': saved(elapsed: 20)},
    );
    final adventure = c.read(adventureProvider.notifier);
    adventure.insertAt(1, Tok.plus);
    adventure.insertAt(5, Tok.times); // 2+2 = 2*2
    adventure.check();
    final s = c.read(adventureProvider);
    final reward = AdventureEconomy.rewardAfter(20);
    expect(reward, lessThan(AdventureEconomy.potStart));
    expect(s.solved, isTrue);
    expect(s.solvedCount, 1);
    expect(s.money, 2000 + reward);
    expect((s.feedback as FeedbackReward).coins, reward);

    adventure.next();
    expect(c.read(adventureProvider).solved, isFalse);
    expect(c.read(adventureProvider).elapsed, 0);
    expect(c.read(adventureProvider).plate, isNot('2222'));
  });

  test('placa resolvida vai para a nuvem e não é sorteada de novo', () async {
    final (c, repo) = await setUp(prefs: {'adventure.demo': saved()});
    final adventure = c.read(adventureProvider.notifier);
    await adventure.ensureReady();
    await c.read(gameProvider.notifier).ensureReady();
    adventure.insertAt(1, Tok.plus);
    adventure.insertAt(5, Tok.times); // 2+2 = 2*2
    adventure.check();
    await Future<void>.delayed(Duration.zero);

    // Só operadores básicos: conta como o nível difícil.
    expect(repo.solved, {'2222': Level.hard});
    final game = c.read(gameProvider.notifier);
    expect(game.wasSolved('2222'), isTrue);
    expect(c.read(gameProvider).score, Level.hard.points);
  });

  test('não sorteia placas que o jogador já resolveu', () async {
    // Só as placas começadas em 1 continuam inéditas.
    final solved = {
      for (var i = 0; i < 10000; i++)
        if (i ~/ 1000 != 1) i.toString().padLeft(4, '0'): Level.easy,
    };
    final (c, _) = await setUp(repo: FakeProgressRepository(solved: solved));
    final adventure = c.read(adventureProvider.notifier);
    await adventure.ensureReady();
    adventure.start();
    for (var i = 0; i < 20; i++) {
      expect(c.read(adventureProvider).plate, startsWith('1'));
      adventure.skip();
    }
  });

  test('errar e pular custam; sem dinheiro a aventura acaba com recorde',
      () async {
    final (c, repo) = await setUp(
      prefs: {'adventure.demo': saved(money: 500, count: 3)},
    );
    final adventure = c.read(adventureProvider.notifier);
    await adventure.ensureReady();

    // "22 = 22" junta dígitos: é um erro e custa.
    adventure.check();
    expect(c.read(adventureProvider).feedback, isA<FeedbackError>());
    expect(c.read(adventureProvider).money, 500 - 150);

    // 350 não paga o pulo (400).
    expect(c.read(adventureProvider).canSkip, isFalse);
    adventure.skip();
    expect(c.read(adventureProvider).plate, '2222');

    adventure.check();
    adventure.check(); // 350 -> 200 -> 50
    expect(c.read(adventureProvider).phase, AdventurePhase.playing);
    adventure.check(); // 50 -> -100: fim
    final s = c.read(adventureProvider);
    expect(s.phase, AdventurePhase.over);
    expect(s.newRecord, isTrue);
    expect(s.best, 3);
    await Future<void>.delayed(Duration.zero);
    expect(repo.adventureBest, 3);
  });

  test('o recorde da nuvem não é sobrescrito por um menor', () async {
    final (c, repo) = await setUp(
      prefs: {'adventure.demo': saved(money: 100, count: 2)},
      repo: FakeProgressRepository(adventureBest: 7),
    );
    final adventure = c.read(adventureProvider.notifier);
    await adventure.ensureReady();
    expect(c.read(adventureProvider).best, 7);
    adventure.check();
    final s = c.read(adventureProvider);
    expect(s.phase, AdventurePhase.over);
    expect(s.newRecord, isFalse);
    expect(repo.adventureBest, 7);
  });

  test('a aventura continua de onde parou', () async {
    final (c, _) = await setUp(
      prefs: {'adventure.demo': saved(pieces: '2+2=22', unlocked: 'r')},
    );
    final s = c.read(adventureProvider);
    expect(s.phase, AdventurePhase.playing);
    expect(encodeLine(s.pieces), '2+2=22');
    expect(s.rules.allows(Tok.sqrt), isTrue);

    c.read(adventureProvider.notifier).insertAt(5, Tok.sqrt);
    final prefs = c.read(sharedPrefsProvider);
    final map = jsonDecode(prefs.getString('adventure.demo')!) as Map;
    expect(map['pieces'], '2+2=2r2');
  });
}
