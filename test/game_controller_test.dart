import 'dart:convert';

import 'package:emplake/core/providers.dart';
import 'package:emplake/data/progress_repository.dart';
import 'package:emplake/game/game_controller.dart';
import 'package:emplake/game/solver.dart';
import 'package:emplake/game/tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

Future<(ProviderContainer, FakeProgressRepository)> setUpGame({
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

String savedGame(String plate, String pieces, {Level level = Level.easy}) =>
    jsonEncode({
      'level': level.name,
      'plate': plate,
      'pieces': pieces,
      'cursor': 0,
      'solved': false,
    });

String line(GameState s) => s.pieces
    .map((p) => switch (p) {
          DigitPiece(:final value) => '$value',
          EqualsPiece() => '=',
          OpPiece(:final tok) => tok.code,
        })
    .join();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('sorteia uma placa inédita e com solução', () async {
    final (c, _) = await setUpGame(
      repo: FakeProgressRepository(solved: {'1234': Level.easy}),
    );
    final game = c.read(gameProvider.notifier);
    await game.ensureReady();
    final s = c.read(gameProvider);
    expect(s.plate, isNotNull);
    expect(s.plate, isNot('1234'));
    expect(s.score, 1);
    expect(line(s), '${s.plate!.substring(0, 2)}=${s.plate!.substring(2)}');
    expect(
      Solver(s.level).isSolvable(s.plate!.split('').map(int.parse).toList()),
      isTrue,
    );
  });

  test('edição: inserir, mover =, apagar e limpar', () async {
    final (c, _) = await setUpGame(
      prefs: {'game.demo': savedGame('8131', '81=31')},
    );
    final game = c.read(gameProvider.notifier);
    await game.ensureReady();
    expect(c.read(gameProvider).plate, '8131');

    // √(8+1) = 3**1
    game.setCursor(0);
    game.insert(Tok.sqrt);
    game.insert(Tok.lparen);
    game.moveCursor(1);
    game.insert(Tok.plus);
    game.moveCursor(1);
    game.insert(Tok.rparen);
    game.moveCursor(2);
    game.insert(Tok.pow);
    expect(line(c.read(gameProvider)), 'r(8+1)=3^1');
    expect(c.read(gameProvider).latex, r'\sqrt{8 + 1} = {3}^{1}');

    // Backspace passa por dígitos sem apagar e remove operadores.
    game.backspace();
    expect(line(c.read(gameProvider)), 'r(8+1)=31');
    game.backspace();
    expect(line(c.read(gameProvider)), 'r(8+1)=31');

    // Move o '=' para depois do último dígito e de volta.
    game.setCursor(c.read(gameProvider).pieces.length);
    game.moveEquals();
    expect(line(c.read(gameProvider)), 'r(8+1)31=');
    game.setCursor(6);
    game.moveEquals();
    expect(line(c.read(gameProvider)), 'r(8+1)=31');

    game.clear();
    expect(line(c.read(gameProvider)), '81=31');
  });

  test('verificação: erro, lados diferentes e acerto gravado', () async {
    final (c, repo) = await setUpGame(
      prefs: {'game.demo': savedGame('8131', '81=31')},
    );
    final game = c.read(gameProvider.notifier);
    await game.ensureReady();

    await game.check();
    expect(c.read(gameProvider).feedback, isA<FeedbackError>());
    expect(c.read(gameProvider).errorTick, 1);

    game.setCursor(1);
    game.insert(Tok.plus); // 8+1 = 3?1
    game.setCursor(5);
    game.insert(Tok.plus); // 8+1 = 3+1
    await game.check();
    final notEqual = c.read(gameProvider).feedback as FeedbackNotEqual;
    expect((notEqual.left, notEqual.right), (9, 4));

    game.backspace();
    game.insert(Tok.pow); // 8+1 = 3**1  -> 9 ≠ 3
    game.setCursor(0);
    game.insert(Tok.sqrt);
    game.insert(Tok.lparen);
    game.setCursor(5);
    game.insert(Tok.rparen);
    expect(line(c.read(gameProvider)), 'r(8+1)=3^1');
    await game.check();

    final s = c.read(gameProvider);
    expect(s.solved, isTrue);
    expect(s.feedback, isA<FeedbackCorrect>());
    expect(s.score, 1);
    expect(repo.solved, {'8131': Level.easy});

    // Placa resolvida fica travada até pedir a próxima.
    game.insert(Tok.plus);
    expect(line(c.read(gameProvider)), 'r(8+1)=3^1');
    game.next();
    final after = c.read(gameProvider);
    expect(after.solved, isFalse);
    expect(after.plate, isNot('8131'));
  });

  test('acerto com falha ao gravar avisa o jogador', () async {
    final (c, repo) = await setUpGame(
      prefs: {'game.demo': savedGame('2222', '2+2=2*2')},
    );
    final game = c.read(gameProvider.notifier);
    await game.ensureReady();
    repo.failWrites = true;
    await game.check();
    final feedback = c.read(gameProvider).feedback as FeedbackCorrect;
    expect(feedback.saveFailed, isTrue);
  });

  test('pular troca a placa e conta a pulada', () async {
    final (c, repo) = await setUpGame(
      prefs: {'game.demo': savedGame('8131', '81=31')},
    );
    final game = c.read(gameProvider.notifier);
    await game.ensureReady();
    expect(game.currentSolution(), isNotNull);
    game.skip();
    await Future<void>.delayed(Duration.zero);
    expect(c.read(gameProvider).plate, isNot('8131'));
    expect(repo.skipped, 1);
  });

  test('placa salva já resolvida na nuvem é trocada', () async {
    final (c, _) = await setUpGame(
      prefs: {'game.demo': savedGame('8131', '81=31')},
      repo: FakeProgressRepository(solved: {'8131': Level.easy}),
    );
    await c.read(gameProvider.notifier).ensureReady();
    expect(c.read(gameProvider).plate, isNot('8131'));
  });

  test('mudar de nível remove operadores proibidos ou troca a placa',
      () async {
    final (c, _) = await setUpGame(
      prefs: {'game.demo': savedGame('2222', 'r2+2=2*2')},
    );
    final game = c.read(gameProvider.notifier);
    await game.ensureReady();
    game.setLevel(Level.hard); // 2222 tem solução no difícil: fica.
    expect(c.read(gameProvider).plate, '2222');
    expect(line(c.read(gameProvider)), '2+2=2*2');

    final (c2, _) = await setUpGame(
      prefs: {'game.demo': savedGame('8131', '81=31')},
    );
    final game2 = c2.read(gameProvider.notifier);
    await game2.ensureReady();
    game2.setLevel(Level.hard); // 8131 não tem solução no difícil: troca.
    expect(c2.read(gameProvider).plate, isNot('8131'));
    expect(c2.read(gameProvider).level, Level.hard);
  });

  test('o estado sobrevive a reabrir o aplicativo', () async {
    final (c, _) = await setUpGame(
      prefs: {'game.demo': savedGame('8131', '81=31')},
    );
    final game = c.read(gameProvider.notifier);
    await game.ensureReady();
    game.setCursor(1);
    game.insert(Tok.plus);
    final prefs = c.read(sharedPrefsProvider);
    final saved = jsonDecode(prefs.getString('game.demo')!) as Map;
    expect(saved['pieces'], '8+1=31');
    expect(saved['cursor'], 2);
  });
}
