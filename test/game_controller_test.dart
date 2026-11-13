import 'dart:convert';

import 'package:emplake/core/providers.dart';
import 'package:emplake/data/progress_repository.dart';
import 'package:emplake/game/game_controller.dart';
import 'package:emplake/game/game_mode.dart';
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

  test('edição: soltar, mover, tirar e limpar', () async {
    final (c, _) = await setUpGame(
      prefs: {'game.demo': savedGame('8131', '81=31')},
    );
    final game = c.read(gameProvider.notifier);
    await game.ensureReady();
    expect(c.read(gameProvider).plate, '8131');

    // √(8+1) = 3**1, soltando um operador por vez.
    game.insertAt(0, Tok.sqrt);
    game.insertAt(1, Tok.lparen);
    game.insertAt(3, Tok.plus);
    game.insertAt(5, Tok.rparen);
    game.insertAt(8, Tok.pow);
    expect(line(c.read(gameProvider)), 'r(8+1)=3^1');
    expect(c.read(gameProvider).latex, r'\sqrt{8 + 1} = {3}^{1}');

    // Só operadores saem da linha; dígitos e '=' ficam.
    final pieces = c.read(gameProvider).pieces;
    game.removePiece(pieces[8].id); // ^
    expect(line(c.read(gameProvider)), 'r(8+1)=31');
    game.removePiece(pieces[7].id); // dígito 3
    game.removePiece(pieces[6].id); // =
    expect(line(c.read(gameProvider)), 'r(8+1)=31');

    // Arrasta o '=' para o fim e de volta; soltar ao lado não muda nada.
    final equals = c.read(gameProvider).pieces[6].id;
    game.movePiece(equals, 9);
    expect(line(c.read(gameProvider)), 'r(8+1)31=');
    game.movePiece(equals, 9);
    game.movePiece(equals, 8);
    expect(line(c.read(gameProvider)), 'r(8+1)31=');
    game.movePiece(equals, 6);
    expect(line(c.read(gameProvider)), 'r(8+1)=31');

    // Dígitos não se movem; operadores podem trocar de lugar.
    game.movePiece(c.read(gameProvider).pieces[2].id, 0);
    expect(line(c.read(gameProvider)), 'r(8+1)=31');
    game.movePiece(c.read(gameProvider).pieces[0].id, 3); // r -> depois do 8
    expect(line(c.read(gameProvider)), '(8r+1)=31');

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

    game.insertAt(1, Tok.plus); // 8+1 = 3?1
    game.insertAt(5, Tok.plus); // 8+1 = 3+1
    await game.check();
    final notEqual = c.read(gameProvider).feedback as FeedbackNotEqual;
    expect((notEqual.left, notEqual.right), (9, 4));

    game.removePiece(c.read(gameProvider).pieces[5].id);
    game.insertAt(5, Tok.pow); // 8+1 = 3**1  -> 9 ≠ 3
    game.insertAt(0, Tok.sqrt);
    game.insertAt(1, Tok.lparen);
    game.insertAt(5, Tok.rparen);
    expect(line(c.read(gameProvider)), 'r(8+1)=3^1');
    await game.check();

    final s = c.read(gameProvider);
    expect(s.solved, isTrue);
    expect(s.feedback, isA<FeedbackCorrect>());
    expect(s.score, 1);
    expect(repo.solved, {'8131': Level.easy});

    // Placa resolvida fica travada até pedir a próxima.
    game.insertAt(0, Tok.plus);
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
    game.insertAt(1, Tok.plus);
    final prefs = c.read(sharedPrefsProvider);
    final saved = jsonDecode(prefs.getString('game.demo')!) as Map;
    expect(saved['pieces'], '8+1=31');
  });

  test('modo específico: escolher, validar e não repontuar', () async {
    final (c, repo) = await setUpGame(
      prefs: {'game.mode': 'specific'},
      repo: FakeProgressRepository(solved: {'2222': Level.easy}),
    );
    final game = c.read(gameProvider.notifier);
    await game.ensureReady();
    // Nada é sorteado: o jogador escolhe.
    expect(c.read(gameProvider).plate, isNull);

    expect(game.choosePlate('12a4'), PlateChoice.invalid);
    expect(game.choosePlate('123'), PlateChoice.invalid);
    game.setLevel(Level.hard);
    expect(game.choosePlate('8131'), PlateChoice.unsolvable);
    expect(c.read(gameProvider).plate, isNull);

    // Placa já resolvida: pode jogar, mas não ganha pontos de novo.
    expect(game.wasSolved('2222'), isTrue);
    expect(game.choosePlate('2222'), PlateChoice.ok);
    final pieces = c.read(gameProvider).pieces;
    game.insertAt(1, Tok.plus);
    game.insertAt(5, Tok.times);
    expect(line(c.read(gameProvider)), '2+2=2*2');
    expect(pieces.length, 5);
    await game.check();
    final s = c.read(gameProvider);
    expect(s.solved, isTrue);
    expect((s.feedback as FeedbackCorrect).repeated, isTrue);
    expect(s.score, 1);
    expect(repo.solved, {'2222': Level.easy});

    // Próxima: volta para a escolha.
    game.next();
    expect(c.read(gameProvider).plate, isNull);
  });

  test('cada modo guarda a sua partida', () async {
    final (c, _) = await setUpGame(
      prefs: {'game.demo': savedGame('8131', '81=31')},
    );
    final game = c.read(gameProvider.notifier);
    await game.ensureReady();
    expect(c.read(gameProvider).plate, '8131');

    c.read(gameModeProvider.notifier).select(GameMode.specific);
    await c.read(gameProvider.notifier).ensureReady();
    expect(c.read(gameProvider).plate, isNull);
    c.read(gameProvider.notifier).choosePlate('4444');

    c.read(gameModeProvider.notifier).select(GameMode.random);
    await c.read(gameProvider.notifier).ensureReady();
    expect(c.read(gameProvider).plate, '8131');
    c.read(gameModeProvider.notifier).select(GameMode.specific);
    expect(c.read(gameProvider).plate, '4444');
  });
}
