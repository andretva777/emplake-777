import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../audio/sound_service.dart';
import '../../core/constants.dart';
import '../../core/providers.dart';
import '../../game/expression.dart';
import '../../game/game_controller.dart';
import '../../game/solver.dart';
import '../../game/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../settings/settings_controller.dart';
import '../l10n_extensions.dart';
import '../widgets/app_loader.dart';
import '../widgets/license_plate.dart';
import '../widgets/page_frame.dart';
import 'balance_scale.dart';
import 'drag_payload.dart';
import 'equation_line.dart';
import 'fly_back.dart';
import 'operator_tray.dart';

/// Página principal: carrega o progresso da nuvem e mostra o tabuleiro.
class GamePage extends ConsumerStatefulWidget {
  const GamePage({super.key});

  @override
  ConsumerState<GamePage> createState() => _GamePageState();
}

class _GamePageState extends ConsumerState<GamePage> {
  late Future<void> _ready;

  @override
  void initState() {
    super.initState();
    _ready = _load();
  }

  Future<void> _load() => ref.read(gameProvider.notifier).ensureReady();

  void _retry() => setState(() => _ready = _load());

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Outro usuário entrou: recarrega o progresso dele.
    ref.listen(currentUserProvider.select((u) => u?.uid), (_, _) => _retry());

    return PageFrame(
      title: l10n.appTitle,
      actions: const [_ScoreChip(), SizedBox(width: 4), _SoundToggle()],
      child: FutureBuilder<void>(
        future: _ready,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return AppLoader(label: l10n.loadingPlate);
          }
          if (snapshot.hasError) return LoadErrorView(onRetry: _retry);
          return const _GameBoard();
        },
      ),
    );
  }
}

class _ScoreChip extends ConsumerWidget {
  const _ScoreChip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final score = ref.watch(gameProvider.select((s) => s.score));
    return Semantics(
      label: '${l10n.scoreLabel}: $score',
      excludeSemantics: true,
      child: Tooltip(
        message: l10n.scoreLabel,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: scheme.tertiaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.star_rounded,
                size: 20,
                color: scheme.onTertiaryContainer,
              ),
              const SizedBox(width: 4),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) => ScaleTransition(
                  scale: animation,
                  child: child,
                ),
                child: Text(
                  '$score',
                  key: ValueKey(score),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: scheme.onTertiaryContainer,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Liga/desliga o som (que começa desligado).
class _SoundToggle extends ConsumerWidget {
  const _SoundToggle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final on = ref.watch(settingsProvider.select((s) => s.soundEnabled));
    return IconButton(
      tooltip: on ? l10n.soundOn : l10n.soundOff,
      isSelected: on,
      onPressed: () {
        ref.read(settingsProvider.notifier).setSound(!on);
        if (!on) ref.read(soundServiceProvider).play(SoundEffect.tap);
      },
      icon: const Icon(Icons.volume_off_rounded),
      selectedIcon: const Icon(Icons.volume_up_rounded),
    );
  }
}

// ---------------------------------------------------------------------------
// Tabuleiro
// ---------------------------------------------------------------------------

class _GameBoard extends ConsumerStatefulWidget {
  const _GameBoard();

  @override
  ConsumerState<_GameBoard> createState() => _GameBoardState();
}

class _GameBoardState extends ConsumerState<_GameBoard> {
  final FocusNode _focus = FocusNode(debugLabel: 'game-board');

  GameController get _game => ref.read(gameProvider.notifier);

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  /// Anima os operadores da linha voltando para os seus botões. Deve ser
  /// chamado antes de o estado mudar, enquanto as peças ainda estão na tela.
  void _flyOperatorsBack() {
    final flights = <Flight>[];
    for (final piece in ref.read(gameProvider).pieces.whereType<OpPiece>()) {
      final from = globalRectOf(EquationLine.keyFor(piece));
      final to = globalRectOf(OperatorTray.keyFor(piece.tok));
      if (from == null || to == null) continue;
      flights.add(Flight(from: from, to: to, label: piece.tok.symbol));
    }
    if (flights.isEmpty) return;
    playFlyBack(context, flights);
    ref.read(soundServiceProvider).play(SoundEffect.whoosh);
  }

  void _clear() {
    _flyOperatorsBack();
    _game.clear();
  }

  void _next() {
    _flyOperatorsBack();
    _game.next();
  }

  Future<void> _skip() async {
    final state = ref.read(gameProvider);
    final plate = state.plate;
    if (plate == null) return;
    final solution = _game.currentSolution();
    _flyOperatorsBack();
    _game.skip();
    if (solution != null && mounted) {
      await showDialog<void>(
        context: context,
        builder: (_) => _SkippedDialog(plate: plate, solution: solution),
      );
    }
    _focus.requestFocus();
  }

  void _setLevel(Level level) {
    if (level == ref.read(gameProvider).level) return;
    _flyOperatorsBack();
    _game.setLevel(level);
  }

  /// Uma peça foi solta na linha: operador novo do teclado ou peça movida.
  void _drop(DragPayload payload, int gap) {
    final id = payload.pieceId;
    final tok = payload.tok;
    if (id != null) {
      _game.movePiece(id, gap);
    } else if (tok != null) {
      _game.insertAt(gap, tok);
    }
  }

  /// O arrasto terminou fora da linha: o operador volta voando para o teclado
  /// (e, se estava na linha, sai dela). O `=` apenas volta ao lugar.
  void _dropped(DragPayload payload, Offset pointer) {
    final tok = payload.tok;
    if (tok == null) return;
    final to = globalRectOf(OperatorTray.keyFor(tok));
    if (to != null) {
      playFlyBack(context, [
        Flight(
          from: Rect.fromCenter(
            center: pointer,
            width: kDragFeedbackSize.width,
            height: kDragFeedbackSize.height,
          ),
          to: to,
          label: tok.symbol,
        ),
      ]);
      ref.read(soundServiceProvider).play(SoundEffect.whoosh);
    }
    final id = payload.pieceId;
    if (id != null) _game.removePiece(id);
  }

  /// Toque em um operador da linha: ele volta voando para o teclado.
  void _removePiece(int id) {
    final piece =
        ref.read(gameProvider).pieces.where((p) => p.id == id).firstOrNull;
    if (piece is! OpPiece) return;
    final from = globalRectOf(EquationLine.keyFor(piece));
    final to = globalRectOf(OperatorTray.keyFor(piece.tok));
    if (from != null && to != null) {
      playFlyBack(context, [Flight(from: from, to: to, label: piece.tok.symbol)]);
      ref.read(soundServiceProvider).play(SoundEffect.whoosh);
    }
    _game.removePiece(id);
  }

  /// Enter verifica a equação (ou avança, depois de acertar).
  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      ref.read(gameProvider).solved ? _next() : _game.check();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameProvider);
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final levelPicker = _LevelPicker(level: state.level, onChanged: _setLevel);

    if (state.exhausted || state.plate == null) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(child: levelPicker),
          const SizedBox(height: 48),
          Icon(
            Icons.workspace_premium_rounded,
            size: 72,
            color: theme.colorScheme.tertiary,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.allSolved,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge,
          ),
        ],
      );
    }

    final evaluation = state.evaluation;
    final enabled = !state.solved;

    Widget stage(double width) {
      // As peças encolhem um pouco em telas estreitas.
      final unit = (width / 420).clamp(0.72, 1.15);
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween(
                  begin: const Offset(0, -0.35),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: LicensePlate(
              key: ValueKey(state.plate),
              text: state.plate!,
              country: l10n.plateCountry,
              height: 58,
            ),
          ),
          const SizedBox(height: 8),
          BalanceScale(
            left: evaluation.left.value,
            right: evaluation.right.value,
            height: 150,
          ),
          const SizedBox(height: 12),
          _Shake(
            trigger: state.errorTick,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 14, 8, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    EquationLine(
                      pieces: state.pieces,
                      locked: !enabled,
                      solved: state.solved,
                      unit: unit,
                      onDrop: _drop,
                      onCancel: _dropped,
                      onRemove: _removePiece,
                    ),
                    const SizedBox(height: 10),
                    const Divider(height: 1),
                    const SizedBox(height: 10),
                    _FormulaView(latex: state.latex),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _FeedbackBanner(
            feedback: state.feedback,
            hint: state.hasOperators ? null : l10n.editHint,
          ),
        ],
      );
    }

    final controls = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        OperatorTray(
          level: state.level,
          enabled: enabled,
          canClear: state.hasOperators,
          onAddToEnd: (tok) => _game.insertAt(state.pieces.length, tok),
          onClear: _clear,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              flex: 4,
              child: OutlinedButton.icon(
                onPressed: enabled ? _skip : null,
                icon: const Icon(Icons.skip_next_rounded),
                label: Text(l10n.skip, maxLines: 1, softWrap: false),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 5,
              child: state.solved
                  ? FilledButton.icon(
                      key: const ValueKey('next'),
                      onPressed: _next,
                      icon: const Icon(Icons.arrow_forward_rounded),
                      label: Text(l10n.nextPlate),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        backgroundColor: theme.colorScheme.tertiary,
                        foregroundColor: theme.colorScheme.onTertiary,
                      ),
                    )
                  : FilledButton.icon(
                      key: const ValueKey('verify'),
                      onPressed: _game.check,
                      icon: const Icon(Icons.check_rounded),
                      label: Text(l10n.verify),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                      ),
                    ),
            ),
          ],
        ),
      ],
    );

    return Focus(
      focusNode: _focus,
      autofocus: true,
      onKeyEvent: _onKey,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final pad = PageFrame.gutter(constraints.maxWidth);
          final wide = constraints.maxWidth >= wideLayoutBreakpoint;

          if (wide) {
            // Duas colunas: equação à esquerda, teclado à direita.
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(pad, 8, pad, 24),
              child: Column(
                children: [
                  levelPicker,
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, c) => stage(c.maxWidth),
                        ),
                      ),
                      const SizedBox(width: 32),
                      SizedBox(
                        width: 340,
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: controls,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }

          final width = math.min(constraints.maxWidth - 2 * pad, 620.0);
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(pad, 4, pad, 20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: Column(
                  children: [
                    levelPicker,
                    const SizedBox(height: 12),
                    stage(width),
                    const SizedBox(height: 12),
                    controls,
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Partes do tabuleiro
// ---------------------------------------------------------------------------

/// Seletor de nível: botões segmentados quando cabem, menu quando não.
class _LevelPicker extends StatelessWidget {
  const _LevelPicker({required this.level, required this.onChanged});

  final Level level;
  final ValueChanged<Level> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = MediaQuery.textScalerOf(context).scale(1);
        if (constraints.maxWidth >= 560 * scale) {
          return Semantics(
            label: l10n.levelLabel,
            container: true,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 640 * scale),
              child: SegmentedButton<Level>(
                // Ocupa a largura disponível, com segmentos iguais.
                expandedInsets: EdgeInsets.zero,
                showSelectedIcon: false,
                segments: [
                  for (final l in Level.values)
                    ButtonSegment(
                      value: l,
                      label: Text(
                        l10n.levelName(l),
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.fade,
                      ),
                      tooltip: l10n.levelPoints(l.points),
                    ),
                ],
                selected: {level},
                onSelectionChanged: (s) => onChanged(s.first),
              ),
            ),
          );
        }
        return MenuAnchor(
          menuChildren: [
            for (final l in Level.values)
              MenuItemButton(
                onPressed: () => onChanged(l),
                leadingIcon: Icon(
                  l == level
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                ),
                child: Text(
                  '${l10n.levelName(l)}  ·  ${l10n.levelPoints(l.points)}',
                ),
              ),
          ],
          builder: (context, controller, _) => FilledButton.tonalIcon(
            onPressed: () =>
                controller.isOpen ? controller.close() : controller.open(),
            icon: const Icon(Icons.tune_rounded),
            label: Text('${l10n.levelLabel}: ${l10n.levelName(level)}'),
          ),
        );
      },
    );
  }
}

/// Fórmula renderizada em LaTeX, logo abaixo da linha montada pelo jogador.
class _FormulaView extends StatelessWidget {
  const _FormulaView({required this.latex});

  final String latex;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      label: l10n.formulaLabel,
      container: true,
      child: Column(
        children: [
          ExcludeSemantics(
            child: Text(
              l10n.formulaLabel.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                letterSpacing: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 64,
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Math.tex(
                    latex,
                    mathStyle: MathStyle.display,
                    textScaleFactor: 1,
                    textStyle: TextStyle(fontSize: 26, color: scheme.onSurface),
                    onErrorFallback: (error) => Text(
                      latex,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Resultado da última verificação (ou uma dica inicial).
class _FeedbackBanner extends StatelessWidget {
  const _FeedbackBanner({required this.feedback, this.hint});

  final GameFeedback? feedback;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final feedback = this.feedback;

    final (IconData icon, String text, Color background, Color foreground)? data =
        switch (feedback) {
      FeedbackError(:final error) => (
          Icons.error_outline_rounded,
          l10n.exprError(error),
          scheme.errorContainer,
          scheme.onErrorContainer,
        ),
      FeedbackNotEqual(:final left, :final right) => (
          Icons.balance_rounded,
          l10n.notEqualMessage(formatValue(left), formatValue(right)),
          scheme.errorContainer,
          scheme.onErrorContainer,
        ),
      FeedbackCorrect(:final points, :final saveFailed) => (
          Icons.celebration_rounded,
          saveFailed
              ? '${l10n.correctMessage(points)}\n${l10n.saveError}'
              : l10n.correctMessage(points),
          scheme.tertiaryContainer,
          scheme.onTertiaryContainer,
        ),
      null => hint == null
          ? null
          : (
              Icons.touch_app_rounded,
              hint!,
              scheme.surfaceContainerHighest,
              scheme.onSurfaceVariant,
            ),
    };

    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: data == null
            ? const SizedBox(width: double.infinity)
            : Semantics(
                key: ValueKey(data.$2),
                liveRegion: feedback != null,
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: data.$3,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(data.$1, color: data.$4),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          data.$2,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: data.$4,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

/// Balança o filho de um lado para o outro sempre que [trigger] muda.
class _Shake extends StatefulWidget {
  const _Shake({required this.trigger, required this.child});

  final int trigger;
  final Widget child;

  @override
  State<_Shake> createState() => _ShakeState();
}

class _ShakeState extends State<_Shake> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  @override
  void didUpdateWidget(_Shake oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger != oldWidget.trigger &&
        !MediaQuery.disableAnimationsOf(context)) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        final dx = math.sin(t * math.pi * 6) * 9 * (1 - t);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: widget.child,
    );
  }
}

/// Mostra uma solução possível da placa que acabou de ser pulada.
class _SkippedDialog extends StatelessWidget {
  const _SkippedDialog({required this.plate, required this.solution});

  final String plate;
  final Solution solution;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return AlertDialog(
      icon: const Icon(Icons.skip_next_rounded),
      title: Text(l10n.skipDialogTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LicensePlate(text: plate, country: l10n.plateCountry, height: 48),
          const SizedBox(height: 16),
          Text(l10n.skipSolutionIntro, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Math.tex(
              solution.latex(),
              mathStyle: MathStyle.display,
              textScaleFactor: 1,
              textStyle: TextStyle(
                fontSize: 26,
                color: theme.colorScheme.onSurface,
              ),
              onErrorFallback: (_) => Text(solution.latex()),
            ),
          ),
        ],
      ),
      actions: [
        FilledButton(
          autofocus: true,
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.continueLabel),
        ),
      ],
    );
  }
}
