import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../audio/sound_service.dart';
import '../core/providers.dart';
import '../data/progress_repository.dart';
import 'expression.dart';
import 'solver.dart';
import 'tokens.dart';

/// Mensagem mostrada ao jogador depois de uma verificação.
sealed class GameFeedback {
  const GameFeedback();
}

class FeedbackError extends GameFeedback {
  const FeedbackError(this.error);
  final ExprError error;
}

class FeedbackNotEqual extends GameFeedback {
  const FeedbackNotEqual(this.left, this.right);
  final double left;
  final double right;
}

class FeedbackCorrect extends GameFeedback {
  const FeedbackCorrect(this.points, {this.saveFailed = false});
  final int points;

  /// A resposta está certa, mas não foi possível gravar na nuvem.
  final bool saveFailed;
}

@immutable
class GameState {
  const GameState({
    this.level = Level.easy,
    this.plate,
    this.pieces = const [],
    this.cursor = 0,
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

  /// Posição de inserção, de 0 a `pieces.length`.
  final int cursor;

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

  GameState copyWith({
    Level? level,
    String? Function()? plate,
    List<Piece>? pieces,
    int? cursor,
    bool? solved,
    bool? exhausted,
    GameFeedback? Function()? feedback,
    int? errorTick,
    int? score,
  }) =>
      GameState(
        level: level ?? this.level,
        plate: plate != null ? plate() : this.plate,
        pieces: pieces ?? this.pieces,
        cursor: cursor ?? this.cursor,
        solved: solved ?? this.solved,
        exhausted: exhausted ?? this.exhausted,
        feedback: feedback != null ? feedback() : this.feedback,
        errorTick: errorTick ?? this.errorTick,
        score: score ?? this.score,
      );
}

/// Regras e estado do jogo. O estado é salvo em SharedPreferences (por
/// usuário) para que a partida continue de onde parou ao reabrir o app.
class GameController extends Notifier<GameState> {
  final math.Random _random = math.Random();
  int _nextId = 0;

  /// Placas já resolvidas pelo usuário (carregadas da nuvem).
  Set<String>? _solvedPlates;

  /// Placas puladas nesta sessão, para não repetir logo em seguida.
  final Set<String> _skippedPlates = {};

  String get _prefsKey =>
      'game.${ref.read(currentUserProvider)?.uid ?? 'anon'}';

  @override
  GameState build() {
    // Reconstrói (e recarrega) quando o usuário muda.
    ref.watch(currentUserProvider.select((u) => u?.uid));
    _solvedPlates = null;
    _skippedPlates.clear();
    _nextId = 0;
    return _restore() ?? const GameState();
  }

  // ------------------------------------------------------------- persistência

  GameState? _restore() {
    final raw = ref.read(sharedPrefsProvider).getString(_prefsKey);
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final level = Level.fromName(map['level'] as String?);
      final plate = map['plate'] as String?;
      if (plate == null || !RegExp(r'^\d{4}$').hasMatch(plate)) {
        return GameState(level: level);
      }
      final pieces = _decode(map['pieces'] as String? ?? '', level);
      final digits = pieces.whereType<DigitPiece>().map((d) => d.value).join();
      final valid = digits == plate &&
          pieces.whereType<EqualsPiece>().length == 1;
      final line = valid ? pieces : _initialPieces(plate);
      return GameState(
        level: level,
        plate: plate,
        pieces: line,
        cursor: ((map['cursor'] as num?)?.toInt() ?? 0).clamp(0, line.length),
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
            'pieces': _encode(s.pieces),
            'cursor': s.cursor,
            'solved': s.solved,
          }),
        );
  }

  String _encode(List<Piece> pieces) => pieces
      .map((p) => switch (p) {
            DigitPiece(:final value) => '$value',
            EqualsPiece() => '=',
            OpPiece(:final tok) => tok.code,
          })
      .join();

  List<Piece> _decode(String s, Level level) {
    final out = <Piece>[];
    for (final ch in s.split('')) {
      final digit = int.tryParse(ch);
      if (digit != null) {
        out.add(DigitPiece(_nextId++, digit));
      } else if (ch == '=') {
        out.add(EqualsPiece(_nextId++));
      } else {
        final tok = Tok.fromCode(ch);
        if (tok != null && level.allows(tok)) out.add(OpPiece(_nextId++, tok));
      }
    }
    return out;
  }

  /// Linha inicial: os quatro dígitos com o `=` já no meio.
  List<Piece> _initialPieces(String plate) => [
        DigitPiece(_nextId++, int.parse(plate[0])),
        DigitPiece(_nextId++, int.parse(plate[1])),
        EqualsPiece(_nextId++),
        DigitPiece(_nextId++, int.parse(plate[2])),
        DigitPiece(_nextId++, int.parse(plate[3])),
      ];

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
      _solvedPlates = {...progress.solved.keys};
      state = state.copyWith(score: progress.score);
    }
    final plate = state.plate;
    final stale = plate == null ||
        (!state.solved && _solvedPlates!.contains(plate));
    if (stale) _drawPlate();
  }

  static List<int> _digitsOf(String plate) =>
      plate.split('').map(int.parse).toList();

  /// Sorteia uma placa que o usuário ainda não resolveu e que tenha solução
  /// no nível atual.
  void _drawPlate() {
    final solved = _solvedPlates ?? const <String>{};
    final solver = Solver(state.level);
    String? chosen;
    for (var attempt = 0; attempt < 400 && chosen == null; attempt++) {
      final candidate = _random.nextInt(10000).toString().padLeft(4, '0');
      if (candidate == state.plate) continue;
      if (solved.contains(candidate)) continue;
      // Depois de muitas tentativas, placas puladas voltam a valer.
      if (attempt < 200 && _skippedPlates.contains(candidate)) continue;
      if (!solver.isSolvable(_digitsOf(candidate))) continue;
      chosen = candidate;
    }
    if (chosen == null) {
      _update(state.copyWith(
        plate: () => null,
        pieces: const [],
        cursor: 0,
        solved: false,
        exhausted: true,
        feedback: () => null,
      ));
      return;
    }
    _update(state.copyWith(
      plate: () => chosen,
      pieces: _initialPieces(chosen),
      cursor: 1,
      solved: false,
      exhausted: false,
      feedback: () => null,
    ));
  }

  // ------------------------------------------------------------------- edição

  bool get _locked => state.solved || state.plate == null;

  void insert(Tok tok) {
    if (_locked || !state.level.allows(tok)) return;
    final pieces = [...state.pieces]
      ..insert(state.cursor, OpPiece(_nextId++, tok));
    _update(state.copyWith(
      pieces: pieces,
      cursor: state.cursor + 1,
      feedback: () => null,
    ));
    ref.read(soundServiceProvider).play(SoundEffect.tap);
  }

  /// Apaga o operador antes do cursor. Dígitos e o `=` não são apagados: o
  /// cursor apenas passa por eles.
  void backspace() {
    if (_locked || state.cursor == 0) return;
    final index = state.cursor - 1;
    final pieces = [...state.pieces];
    if (pieces[index] is OpPiece) pieces.removeAt(index);
    _update(state.copyWith(
      pieces: pieces,
      cursor: index,
      feedback: () => null,
    ));
  }

  /// Remove um operador específico (toque longo / clique duplo na peça).
  void removePiece(int id) {
    if (_locked) return;
    final index = state.pieces.indexWhere((p) => p.id == id);
    if (index < 0 || state.pieces[index] is! OpPiece) return;
    final pieces = [...state.pieces]..removeAt(index);
    _update(state.copyWith(
      pieces: pieces,
      cursor: state.cursor > index ? state.cursor - 1 : state.cursor,
      feedback: () => null,
    ));
  }

  void setCursor(int position) {
    if (_locked) return;
    _update(state.copyWith(cursor: position.clamp(0, state.pieces.length)));
  }

  void moveCursor(int delta) => setCursor(state.cursor + delta);

  /// Traz o sinal de igual para a posição do cursor.
  void moveEquals() {
    if (_locked) return;
    final pieces = [...state.pieces];
    final from = pieces.indexWhere((p) => p is EqualsPiece);
    if (from < 0) return;
    final equals = pieces.removeAt(from);
    var target = state.cursor;
    if (target > from) target--;
    pieces.insert(target, equals);
    _update(state.copyWith(
      pieces: pieces,
      cursor: target + 1,
      feedback: () => null,
    ));
    ref.read(soundServiceProvider).play(SoundEffect.tap);
  }

  /// Devolve todos os operadores, mantendo a placa.
  void clear() {
    final plate = state.plate;
    if (_locked || plate == null) return;
    _update(state.copyWith(
      pieces: _initialPieces(plate),
      cursor: 1,
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
    _solvedPlates?.add(plate);
    _update(state.copyWith(
      solved: true,
      score: state.score + level.points,
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
    return Solver(state.level).solve(_digitsOf(plate));
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
  void next() => _drawPlate();

  void setLevel(Level level) {
    if (level == state.level) return;
    final plate = state.plate;
    final keep = plate != null &&
        !state.solved &&
        Solver(level).isSolvable(_digitsOf(plate));
    if (keep) {
      // A placa continua valendo; só saem os operadores não permitidos.
      final pieces = [
        for (final p in state.pieces)
          if (p is! OpPiece || level.allows(p.tok)) p,
      ];
      _update(state.copyWith(
        level: level,
        pieces: pieces,
        cursor: state.cursor.clamp(0, pieces.length),
        feedback: () => null,
      ));
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
