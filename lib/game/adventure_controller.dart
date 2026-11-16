import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../audio/sound_service.dart';
import '../core/providers.dart';
import '../data/progress_repository.dart';
import 'expression.dart';
import 'game_controller.dart';
import 'line_editing.dart';
import 'solver.dart';
import 'tokens.dart';

/// Economia do modo aventura.
abstract final class AdventureEconomy {
  static const startMoney = 2000;

  /// Prêmio de uma placa: começa em [potStart] e cai [potDecay] por segundo,
  /// até [potMin]. Resolver rápido vale mais.
  static const potStart = 600;
  static const potDecay = 5;
  static const potMin = 150;

  /// Custo de cada verificação errada.
  static const wrongPenalty = 150;

  /// Custo de pular uma placa (a solução é mostrada).
  static const skipCost = 400;

  static int rewardAfter(int seconds) =>
      math.max(potMin, potStart - potDecay * seconds);
}

/// Operadores à venda na aventura. Base e teto são vendidos em par.
enum Upgrade {
  sqrt([Tok.sqrt]),
  cbrt([Tok.cbrt]),
  fact([Tok.fact]),
  pow([Tok.pow]),
  abs([Tok.abs]),
  floor([Tok.floorL, Tok.floorR]),
  ceil([Tok.ceilL, Tok.ceilR]);

  const Upgrade(this.toks);
  final List<Tok> toks;

  int get price => 1000;

  static Upgrade? of(Tok tok) =>
      values.where((u) => u.toks.contains(tok)).firstOrNull;
}

/// Regras da aventura: os operadores básicos mais os comprados. A divisão
/// precisa ser exata.
@immutable
class AdventureRules implements OperatorRules {
  const AdventureRules(this.unlocked);

  static const free = {
    Tok.plus, Tok.minus, Tok.times, Tok.divide, Tok.lparen, Tok.rparen, //
  };

  /// Todos os operadores, na ordem em que aparecem no teclado.
  static List<Tok> get all => Level.easy.operators;

  final Set<Tok> unlocked;

  @override
  bool allows(Tok t) => free.contains(t) || unlocked.contains(t);

  @override
  bool get allowsFractions => false;
}

enum AdventurePhase {
  /// Antes de começar (mostra as regras).
  intro,
  playing,

  /// O dinheiro acabou.
  over,
}

@immutable
class AdventureState {
  const AdventureState({
    this.phase = AdventurePhase.intro,
    this.money = AdventureEconomy.startMoney,
    this.solvedCount = 0,
    this.unlocked = const {},
    this.plate,
    this.pieces = const [],
    this.elapsed = 0,
    this.solved = false,
    this.feedback,
    this.errorTick = 0,
    this.best = 0,
    this.newRecord = false,
  });

  final AdventurePhase phase;
  final int money;

  /// Placas resolvidas nesta aventura.
  final int solvedCount;
  final Set<Tok> unlocked;
  final String? plate;
  final List<Piece> pieces;

  /// Segundos gastos na placa atual (o prêmio cai com o tempo).
  final int elapsed;

  /// A placa atual foi resolvida (aguardando a próxima).
  final bool solved;
  final GameFeedback? feedback;
  final int errorTick;

  /// Recorde do jogador (carregado da nuvem).
  final int best;

  /// A aventura que acabou de terminar bateu o recorde.
  final bool newRecord;

  AdventureRules get rules => AdventureRules(unlocked);
  EquationResult get evaluation => evaluateEquation(pieces, rules);
  String get latex => equationToLatex(pieces);
  bool get hasOperators => pieces.any((p) => p is OpPiece);
  int get reward => AdventureEconomy.rewardAfter(elapsed);
  bool get canSkip => !solved && money > AdventureEconomy.skipCost;

  AdventureState copyWith({
    AdventurePhase? phase,
    int? money,
    int? solvedCount,
    Set<Tok>? unlocked,
    String? Function()? plate,
    List<Piece>? pieces,
    int? elapsed,
    bool? solved,
    GameFeedback? Function()? feedback,
    int? errorTick,
    int? best,
    bool? newRecord,
  }) =>
      AdventureState(
        phase: phase ?? this.phase,
        money: money ?? this.money,
        solvedCount: solvedCount ?? this.solvedCount,
        unlocked: unlocked ?? this.unlocked,
        plate: plate != null ? plate() : this.plate,
        pieces: pieces ?? this.pieces,
        elapsed: elapsed ?? this.elapsed,
        solved: solved ?? this.solved,
        feedback: feedback != null ? feedback() : this.feedback,
        errorTick: errorTick ?? this.errorTick,
        best: best ?? this.best,
        newRecord: newRecord ?? this.newRecord,
      );
}

/// Modo aventura (sobrevivência): o jogador ganha moedas resolvendo placas,
/// perde moedas errando ou pulando e compra operadores avançados. A aventura
/// termina quando o dinheiro acaba. Fica salva para continuar depois.
class AdventureController extends Notifier<AdventureState>
    implements LineEditor {
  final math.Random _random = math.Random();
  int _nextId = 0;
  Timer? _clock;
  bool _bestLoaded = false;

  /// Placas já vistas nesta aventura, para não repetir.
  final Set<String> _seen = {};

  /// Placas que o jogador já resolveu em qualquer modo (vêm da nuvem).
  final Set<String> _solvedPlates = {};

  String get _prefsKey =>
      'adventure.${ref.read(currentUserProvider)?.uid ?? 'anon'}';

  int _id() => _nextId++;

  @override
  AdventureState build() {
    ref.watch(currentUserProvider.select((u) => u?.uid));
    ref.onDispose(() => _clock?.cancel());
    _clock = null;
    _bestLoaded = false;
    _seen.clear();
    _solvedPlates.clear();
    _nextId = 0;
    return _restore() ?? const AdventureState();
  }

  // ------------------------------------------------------------- persistência

  AdventureState? _restore() {
    final raw = ref.read(sharedPrefsProvider).getString(_prefsKey);
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final phase = AdventurePhase.values
              .where((p) => p.name == map['phase'])
              .firstOrNull ??
          AdventurePhase.intro;
      final unlocked = {
        for (final code in (map['unlocked'] as String? ?? '').split(''))
          ?Tok.fromCode(code),
      };
      final rules = AdventureRules(unlocked);
      final plate = map['plate'] as String?;
      var pieces = const <Piece>[];
      if (isPlate(plate)) {
        pieces = decodeLine(map['pieces'] as String? ?? '', rules, _id);
        if (!lineMatchesPlate(pieces, plate!)) pieces = initialLine(plate, _id);
        _seen.add(plate);
      }
      final state = AdventureState(
        phase: phase,
        money: (map['money'] as num?)?.toInt() ?? AdventureEconomy.startMoney,
        solvedCount: (map['count'] as num?)?.toInt() ?? 0,
        unlocked: unlocked,
        plate: isPlate(plate) ? plate : null,
        pieces: pieces,
        elapsed: (map['elapsed'] as num?)?.toInt() ?? 0,
        solved: map['solved'] == true,
        best: (map['best'] as num?)?.toInt() ?? 0,
      );
      // Partida em andamento sem placa válida: volta ao início.
      if (state.phase == AdventurePhase.playing && state.plate == null) {
        return state.copyWith(phase: AdventurePhase.intro);
      }
      return state;
    } catch (_) {
      return null;
    }
  }

  void _save() {
    final s = state;
    ref.read(sharedPrefsProvider).setString(
          _prefsKey,
          jsonEncode({
            'phase': s.phase.name,
            'money': s.money,
            'count': s.solvedCount,
            'unlocked': s.unlocked.map((t) => t.code).join(),
            'plate': s.plate,
            'pieces': encodeLine(s.pieces),
            'elapsed': s.elapsed,
            'solved': s.solved,
            'best': s.best,
          }),
        );
  }

  void _update(AdventureState next) {
    state = next;
    _save();
  }

  // ------------------------------------------------------------------ partida

  /// Carrega da nuvem o recorde e as placas já resolvidas (uma vez por
  /// sessão).
  Future<void> ensureReady() async {
    if (_bestLoaded) return;
    final repo = ref.read(progressRepositoryProvider);
    final progress =
        repo == null ? const UserProgress() : await repo.fetchProgress();
    _bestLoaded = true;
    _solvedPlates.addAll(progress.solved.keys);
    state = state.copyWith(best: math.max(state.best, progress.adventureBest));
  }

  /// Começa uma aventura nova.
  void start() {
    _seen.clear();
    _update(AdventureState(best: state.best));
    _drawPlate(phase: AdventurePhase.playing);
  }

  /// Desiste da aventura atual (conta como fim de jogo).
  void giveUp() {
    if (state.phase != AdventurePhase.playing) return;
    _gameOver();
  }

  void _drawPlate({AdventurePhase? phase}) {
    // Toda placa tem solução só com os operadores básicos.
    final solver = Solver(const AdventureRules({}));
    String? chosen;
    for (var attempt = 0; attempt < 600 && chosen == null; attempt++) {
      final candidate = _random.nextInt(10000).toString().padLeft(4, '0');
      // Só placas inéditas; depois de muitas tentativas, vale repetir.
      final repeated =
          _seen.contains(candidate) || _solvedPlates.contains(candidate);
      if (attempt < 400 && repeated) continue;
      if (!solver.isSolvable(digitsOf(candidate))) continue;
      chosen = candidate;
    }
    // Com 10 mil placas e ~metade com solução, a busca sempre encontra uma.
    chosen ??= '1111';
    _seen.add(chosen);
    _update(state.copyWith(
      phase: phase,
      plate: () => chosen,
      pieces: initialLine(chosen, _id),
      elapsed: 0,
      solved: false,
      feedback: () => null,
    ));
  }

  void _gameOver() {
    pauseClock();
    final record = state.solvedCount > state.best;
    _update(state.copyWith(
      phase: AdventurePhase.over,
      best: record ? state.solvedCount : state.best,
      newRecord: record,
      feedback: () => null,
    ));
    if (record) {
      ref
          .read(progressRepositoryProvider)
          ?.saveAdventureBest(state.solvedCount)
          .then((_) => ref.read(progressVersionProvider.notifier).bump())
          .ignore();
    }
  }

  // -------------------------------------------------------------------- tempo

  bool get _ticking =>
      state.phase == AdventurePhase.playing && !state.solved;

  /// Liga o relógio da placa (enquanto a tela da aventura estiver aberta).
  void resumeClock() {
    if (_clock != null || !_ticking) return;
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_ticking) return pauseClock();
      _update(state.copyWith(elapsed: state.elapsed + 1));
    });
  }

  void pauseClock() {
    _clock?.cancel();
    _clock = null;
  }

  // ------------------------------------------------------------------- edição

  bool get _locked => state.phase != AdventurePhase.playing || state.solved;

  @override
  void insertAt(int gap, Tok tok) {
    if (_locked || !state.rules.allows(tok)) return;
    _edit(insertInLine(state.pieces, gap, OpPiece(_id(), tok)));
    ref.read(soundServiceProvider).play(SoundEffect.tap);
  }

  @override
  void movePiece(int id, int gap) {
    if (_locked) return;
    final pieces = moveInLine(state.pieces, id, gap);
    if (pieces == null) return;
    _edit(pieces);
    ref.read(soundServiceProvider).play(SoundEffect.tap);
  }

  @override
  void removePiece(int id) {
    if (_locked) return;
    final pieces = removeFromLine(state.pieces, id);
    if (pieces != null) _edit(pieces);
  }

  void clear() {
    final plate = state.plate;
    if (_locked || plate == null) return;
    _edit(initialLine(plate, _id));
  }

  void _edit(List<Piece> pieces) =>
      _update(state.copyWith(pieces: pieces, feedback: () => null));

  /// Compra um operador. Retorna `false` se o dinheiro não for suficiente.
  bool buy(Upgrade upgrade) {
    if (state.phase != AdventurePhase.playing) return false;
    if (upgrade.toks.every(state.unlocked.contains)) return true;
    if (state.money < upgrade.price) return false;
    _update(state.copyWith(
      money: state.money - upgrade.price,
      unlocked: {...state.unlocked, ...upgrade.toks},
    ));
    ref.read(soundServiceProvider).play(SoundEffect.success);
    return true;
  }

  // ---------------------------------------------------------------- verificação

  void check() {
    if (_locked) return;
    final sounds = ref.read(soundServiceProvider);
    final result = state.evaluation;
    if (!result.isCorrect) {
      sounds.play(SoundEffect.error);
      const penalty = AdventureEconomy.wrongPenalty;
      final error = result.error;
      _update(state.copyWith(
        money: state.money - penalty,
        errorTick: state.errorTick + 1,
        feedback: () => error != null
            ? FeedbackError(error, penalty: penalty)
            : FeedbackNotEqual(
                result.left.value!,
                result.right.value!,
                penalty: penalty,
              ),
      ));
      if (state.money <= 0) _gameOver();
      return;
    }
    sounds.play(SoundEffect.success);
    pauseClock();
    final reward = state.reward;
    _update(state.copyWith(
      money: state.money + reward,
      solvedCount: state.solvedCount + 1,
      solved: true,
      feedback: () => FeedbackReward(reward),
    ));
    _recordSolved();
  }

  /// Grava a placa resolvida na nuvem, como nos outros modos, para que ela
  /// não seja sorteada de novo. Vale os pontos do nível mais difícil que
  /// permite os operadores usados.
  void _recordSolved() {
    final plate = state.plate;
    if (plate == null || !_solvedPlates.add(plate)) return;
    final level = Level.hardestAllowing(
      state.pieces.whereType<OpPiece>().map((p) => p.tok),
    );
    ref.read(gameProvider.notifier).addSolved(plate, level.points);
    // Falha ao gravar não interrompe a aventura.
    ref
        .read(progressRepositoryProvider)
        ?.markSolved(plate, level)
        .then((_) => ref.read(progressVersionProvider.notifier).bump())
        .ignore();
  }

  /// Solução mais simples da placa atual com os operadores já liberados.
  Solution? currentSolution() {
    final plate = state.plate;
    if (plate == null) return null;
    return Solver(state.rules).solve(digitsOf(plate));
  }

  /// Paga para pular a placa atual.
  void skip() {
    if (_locked || !state.canSkip) return;
    state = state.copyWith(money: state.money - AdventureEconomy.skipCost);
    _drawPlate();
  }

  /// Próxima placa, depois de acertar.
  void next() {
    if (state.phase != AdventurePhase.playing || !state.solved) return;
    _drawPlate();
  }
}

final adventureProvider =
    NotifierProvider<AdventureController, AdventureState>(
  AdventureController.new,
);
