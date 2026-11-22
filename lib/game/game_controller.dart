import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../audio/sound_service.dart';
import '../core/providers.dart';
import '../data/progress_repository.dart';
import 'expression.dart';
import 'game_mode.dart';
import 'line_editing.dart';
import 'solver.dart';
import 'tokens.dart';

/// Mensagem mostrada ao jogador depois de uma verificação.
sealed class GameFeedback {
  const GameFeedback();
}

class FeedbackError extends GameFeedback {
  const FeedbackError(this.error, {this.penalty = 0});
  final ExprError error;

  /// Moedas perdidas pelo erro (modo aventura).
  final int penalty;
}

class FeedbackNotEqual extends GameFeedback {
  const FeedbackNotEqual(this.left, this.right, {this.penalty = 0});
  final double left;
  final double right;

  /// Moedas perdidas pelo erro (modo aventura).
  final int penalty;
}

class FeedbackCorrect extends GameFeedback {
  const FeedbackCorrect(
    this.points, {
    this.saveFailed = false,
    this.repeated = false,
  });
  final int points;

  /// Placa que o jogador já tinha resolvido (modo específico): não pontua.
  final bool repeated;

  /// A resposta está certa, mas não foi possível gravar na nuvem.
  final bool saveFailed;
}

/// Acerto no modo aventura: rende moedas em vez de pontos.
class FeedbackReward extends GameFeedback {
  const FeedbackReward(this.coins);
  final int coins;
}

/// Resultado da escolha de uma placa no modo específico.
enum PlateChoice { ok, invalid, unsolvable }

@immutable
class GameState {
  const GameState({
    this.level = Level.easy,
    this.plate,
    this.pieces = const [],
    this.caret = 0,
    this.solved = false,
    this.exhausted = false,
    this.feedback,
    this.errorTick = 0,
    this.score = 0,
  });

  final Level level;

  /// Placa atual ("0427"), ou `null` enquanto nenhuma foi sorteada.
  final String? plate;

  /// Linha da equação: dígitos, operadores e o sinal de igual.
  final List<Piece> pieces;

  /// Posição do cursor na linha (0 a `pieces.length`).
  final int caret;

  /// A placa atual já foi resolvida (aguardando "Próxima placa").
  final bool solved;

  /// Não há mais placas inéditas com solução neste nível.
  final bool exhausted;

  final GameFeedback? feedback;

  /// Incrementado a cada verificação errada (dispara a animação de tremor).
  final int errorTick;

  /// Pontuação total do jogador (carregada da nuvem).
  final int score;

  /// Avaliação ao vivo dos dois lados (alimenta a balança).
  EquationResult get evaluation => evaluateEquation(pieces, level);

  String get latex => equationToLatex(pieces);

  bool get hasOperators => pieces.any((p) => p is OpPiece);

  /// A tecla ⌫ tem o que apagar.
  bool get canDeleteBeforeCaret => canDeleteBefore(pieces, caret);

  GameState copyWith({
    Level? level,
    String? Function()? plate,
    List<Piece>? pieces,
    int? caret,
    bool? solved,
    bool? exhausted,
    GameFeedback? Function()? feedback,
    int? errorTick,
    int? score,
  }) {
    final line = pieces ?? this.pieces;
    return GameState(
      level: level ?? this.level,
      plate: plate != null ? plate() : this.plate,
      pieces: line,
      // Linha nova sem cursor informado: o cursor volta ao início.
      caret: clampCaret(caret ?? (pieces == null ? this.caret : 0), line),
      solved: solved ?? this.solved,
      exhausted: exhausted ?? this.exhausted,
      feedback: feedback != null ? feedback() : this.feedback,
      errorTick: errorTick ?? this.errorTick,
      score: score ?? this.score,
    );
  }
}

/// Regras e estado do jogo. O estado é salvo em SharedPreferences (por
/// usuário) para que a partida continue de onde parou ao reabrir o app.
class GameController extends Notifier<GameState> implements LineEditor {
  final math.Random _random = math.Random();
  int _nextId = 0;

  /// Placas já resolvidas pelo usuário (carregadas da nuvem).
  Set<String>? _solvedPlates;

  /// Placas resolvidas nesta sessão, em qualquer modo. Valem mesmo antes de
  /// o cache acima carregar e mesmo se a gravação ainda não chegou à nuvem,
  /// para que nenhuma placa seja gravada (e pontuada) duas vezes.
  final Set<String> _solvedHere = {};

  /// Placas puladas nesta sessão, para não repetir logo em seguida.
  final Set<String> _skippedPlates = {};

  /// Usuário dono do cache acima e pontuação dele. O cache sobrevive à troca
  /// de modo, para não buscar tudo na nuvem de novo.
  String? _cacheUid;
  int _score = 0;

  /// Modo específico: o jogador escolhe a placa.
  bool _specific = false;

  /// Cada modo guarda a sua partida.
  String get _prefsKey =>
      'game.${ref.read(currentUserProvider)?.uid ?? 'anon'}'
      '${_specific ? '.specific' : ''}';

  @override
  GameState build() {
    // Reconstrói quando o usuário ou o modo mudam.
    final uid = ref.watch(currentUserProvider.select((u) => u?.uid));
    _specific = ref.watch(gameModeProvider) == GameMode.specific;
    if (uid != _cacheUid) {
      _cacheUid = uid;
      _solvedPlates = null;
      _solvedHere.clear();
      _skippedPlates.clear();
      _score = 0;
    }
    _nextId = 0;
    return (_restore() ?? const GameState()).copyWith(score: _score);
  }

  // ------------------------------------------------------------- persistência

  GameState? _restore() {
    final raw = ref.read(sharedPrefsProvider).getString(_prefsKey);
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final level = Level.fromName(map['level'] as String?);
      final plate = map['plate'] as String?;
      if (plate == null || !isPlate(plate)) return GameState(level: level);
      final pieces = decodeLine(map['pieces'] as String? ?? '', level, _id);
      final valid = lineMatchesPlate(pieces, plate);
      final line = valid ? pieces : initialLine(plate, _id);
      return GameState(
        level: level,
        plate: plate,
        pieces: line,
        solved: valid && map['solved'] == true,
      );
    } catch (_) {
      return null;
    }
  }

  void _save() {
    final s = state;
    ref.read(sharedPrefsProvider).setString(
          _prefsKey,
          jsonEncode({
            'level': s.level.name,
            'plate': s.plate,
            'pieces': encodeLine(s.pieces),
            'solved': s.solved,
          }),
        );
  }

  int _id() => _nextId++;

  void _update(GameState next) {
    state = next;
    _save();
  }

  // ------------------------------------------------------------------ sorteio

  /// Carrega da nuvem as placas já resolvidas e garante que exista uma placa
  /// inédita em jogo. Lança exceção se a nuvem estiver inacessível.
  Future<void> ensureReady() async {
    if (_solvedPlates == null) {
      final repo = ref.read(progressRepositoryProvider);
      final progress =
          repo == null ? const UserProgress() : await repo.fetchProgress();
      _solvedPlates = {...progress.solved.keys, ..._solvedHere};
      _score = progress.score;
    }
    state = state.copyWith(score: _score);
    // No modo específico a placa só existe quando o jogador a escolhe.
    if (_specific) return;
    final plate = state.plate;
    final stale = plate == null ||
        (!state.solved && _solvedPlates!.contains(plate));
    if (stale) _drawPlate();
  }

  /// Sorteia uma placa que o usuário ainda não resolveu e que tenha solução
  /// no nível atual.
  void _drawPlate() {
    final solver = Solver(state.level);
    String? chosen;
    for (var attempt = 0; attempt < 400 && chosen == null; attempt++) {
      final candidate = _random.nextInt(10000).toString().padLeft(4, '0');
      if (candidate == state.plate) continue;
      if (wasSolved(candidate)) continue;
      // Depois de muitas tentativas, placas puladas voltam a valer.
      if (attempt < 200 && _skippedPlates.contains(candidate)) continue;
      if (!solver.isSolvable(digitsOf(candidate))) continue;
      chosen = candidate;
    }
    if (chosen == null) {
      _update(state.copyWith(
        plate: () => null,
        pieces: const [],
        solved: false,
        exhausted: true,
        feedback: () => null,
      ));
      return;
    }
    _update(state.copyWith(
      plate: () => chosen,
      pieces: initialLine(chosen, _id),
      solved: false,
      exhausted: false,
      feedback: () => null,
    ));
  }

  // ------------------------------------------------------------------- edição

  bool get _locked => state.solved || state.plate == null;

  /// Solta um operador novo na posição [gap] da linha (0 a `pieces.length`).
  @override
  void insertAt(int gap, Tok tok) {
    if (_locked || !state.level.allows(tok)) return;
    final at = gap.clamp(0, state.pieces.length);
    final pieces = insertInLine(state.pieces, at, OpPiece(_id(), tok));
    _update(state.copyWith(
      pieces: pieces,
      caret: at + 1,
      feedback: () => null,
    ));
    ref.read(soundServiceProvider).play(SoundEffect.tap);
  }

  @override
  void insertAtCaret(Tok tok) => insertAt(state.caret, tok);

  /// Move um operador ou o sinal de igual que já está na linha para a posição
  /// [gap], contada na linha antes da remoção. Os dígitos nunca se movem.
  @override
  void movePiece(int id, int gap) {
    if (_locked) return;
    final pieces = moveInLine(state.pieces, id, gap);
    if (pieces == null) return;
    _update(state.copyWith(
      pieces: pieces,
      caret: caretAfter(pieces, id),
      feedback: () => null,
    ));
    ref.read(soundServiceProvider).play(SoundEffect.tap);
  }

  /// Tira um operador da linha (devolvendo-o ao teclado). Dígitos e o `=`
  /// não podem ser removidos.
  @override
  void removePiece(int id) {
    if (_locked) return;
    final index = state.pieces.indexWhere((p) => p.id == id);
    final pieces = removeFromLine(state.pieces, id);
    if (pieces == null) return;
    _update(state.copyWith(
      pieces: pieces,
      caret: caretAfterRemoval(state.caret, index),
      feedback: () => null,
    ));
  }

  @override
  void setCaret(int gap) {
    if (_locked) return;
    final caret = clampCaret(gap, state.pieces);
    if (caret == state.caret) return;
    state = state.copyWith(caret: caret);
  }

  @override
  void deleteBeforeCaret() {
    if (_locked || !state.canDeleteBeforeCaret) return;
    removePiece(state.pieces[state.caret - 1].id);
  }

  /// Devolve todos os operadores, mantendo a placa.
  void clear() {
    final plate = state.plate;
    if (_locked || plate == null) return;
    _update(state.copyWith(
      pieces: initialLine(plate, _id),
      feedback: () => null,
    ));
  }

  // --------------------------------------------------------------- verificação

  Future<void> check() async {
    final plate = state.plate;
    if (_locked || plate == null) return;
    final sounds = ref.read(soundServiceProvider);
    final result = state.evaluation;
    final error = result.error;
    if (error != null) {
      sounds.play(SoundEffect.error);
      _update(state.copyWith(
        feedback: () => FeedbackError(error),
        errorTick: state.errorTick + 1,
      ));
      return;
    }
    if (!result.isCorrect) {
      sounds.play(SoundEffect.error);
      _update(state.copyWith(
        feedback: () =>
            FeedbackNotEqual(result.left.value!, result.right.value!),
        errorTick: state.errorTick + 1,
      ));
      return;
    }

    final level = state.level;
    sounds.play(SoundEffect.success);
    if (wasSolved(plate)) {
      // Só acontece no modo específico: acertar de novo não pontua.
      _update(state.copyWith(
        solved: true,
        feedback: () => const FeedbackCorrect(0, repeated: true),
      ));
      return;
    }
    _solvedPlates?.add(plate);
    _solvedHere.add(plate);
    _score += level.points;
    _update(state.copyWith(
      solved: true,
      score: _score,
      feedback: () => FeedbackCorrect(level.points),
    ));
    try {
      await ref.read(progressRepositoryProvider)?.markSolved(plate, level);
      ref.read(progressVersionProvider.notifier).bump();
    } catch (_) {
      if (state.plate == plate && state.solved) {
        _update(state.copyWith(
          feedback: () => FeedbackCorrect(level.points, saveFailed: true),
        ));
      }
    }
  }

  /// Solução mais simples da placa atual (mostrada ao pular).
  Solution? currentSolution() {
    final plate = state.plate;
    if (plate == null) return null;
    return Solver(state.level).solve(digitsOf(plate));
  }

  /// Pula a placa atual e sorteia outra.
  void skip() {
    final plate = state.plate;
    if (plate == null || state.solved) return;
    _skippedPlates.add(plate);
    // O contador de puladas é só estatística; falhas são ignoradas.
    ref.read(progressRepositoryProvider)?.markSkipped(plate).ignore();
    _drawPlate();
  }

  /// Avança para a próxima placa depois de resolver a atual.
  void next() => _specific ? changePlate() : _drawPlate();

  /// O jogador já resolveu esta placa (antes ou nesta sessão, em qualquer
  /// modo).
  bool wasSolved(String plate) =>
      _solvedHere.contains(plate) || (_solvedPlates?.contains(plate) ?? false);

  /// Placa resolvida e gravada pelo modo aventura. Entra no cache para não
  /// ser sorteada nem gravada de novo.
  void addSolved(String plate, int points) {
    _solvedHere.add(plate);
    final solved = _solvedPlates;
    // Sem cache carregado, a pontuação virá da nuvem ao carregar.
    if (solved == null || !solved.add(plate)) return;
    _score += points;
    state = state.copyWith(score: _score);
  }

  /// Modo específico: começa a jogar com a placa digitada.
  PlateChoice choosePlate(String plate) {
    if (!isPlate(plate)) return PlateChoice.invalid;
    if (!Solver(state.level).isSolvable(digitsOf(plate))) {
      return PlateChoice.unsolvable;
    }
    _update(state.copyWith(
      plate: () => plate,
      pieces: initialLine(plate, _id),
      solved: false,
      exhausted: false,
      feedback: () => null,
    ));
    return PlateChoice.ok;
  }

  /// Modo específico: volta para a escolha de placa.
  void changePlate() {
    _update(state.copyWith(
      plate: () => null,
      pieces: const [],
      solved: false,
      exhausted: false,
      feedback: () => null,
    ));
  }

  void setLevel(Level level) {
    if (level == state.level) return;
    final plate = state.plate;
    final keep = plate != null &&
        !state.solved &&
        Solver(level).isSolvable(digitsOf(plate));
    if (keep) {
      // A placa continua valendo; só saem os operadores não permitidos.
      bool keep(Piece p) => p is! OpPiece || level.allows(p.tok);
      _update(state.copyWith(
        level: level,
        pieces: state.pieces.where(keep).toList(),
        caret: caretAfterFilter(state.pieces, state.caret, keep),
        feedback: () => null,
      ));
    } else if (_specific) {
      // A placa escolhida não vale no novo nível: volta para a escolha.
      state = state.copyWith(level: level);
      changePlate();
    } else {
      state = state.copyWith(level: level);
      _drawPlate();
    }
  }
}

final gameProvider = NotifierProvider<GameController, GameState>(
  GameController.new,
);

/// Contador incrementado sempre que o progresso na nuvem muda; a página de
/// progresso o observa para recarregar os dados.
class ProgressVersion extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

final progressVersionProvider = NotifierProvider<ProgressVersion, int>(
  ProgressVersion.new,
);
