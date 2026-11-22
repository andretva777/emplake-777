import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../audio/sound_service.dart';
import '../../core/constants.dart';
import '../../game/expression.dart';
import '../../game/game_controller.dart';
import '../../game/game_mode.dart';
import '../../game/line_editing.dart';
import '../../game/solver.dart';
import '../../game/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../l10n_extensions.dart';
import '../widgets/license_plate.dart';
import '../widgets/page_frame.dart';
import 'balance_scale.dart';
import 'board_keys.dart';
import 'drag_payload.dart';
import 'equation_line.dart';
import 'fly_back.dart';

// ---------------------------------------------------------------------------
// Layout
// ---------------------------------------------------------------------------

/// Disposição do tabuleiro, comum a todos os modos: em telas largas, a
/// equação à esquerda e os controles à direita; em telas estreitas, tudo em
/// uma coluna.
class BoardLayout extends StatelessWidget {
  const BoardLayout({
    super.key,
    required this.top,
    required this.stage,
    required this.controls,
  });

  /// Seletores e informações acima do tabuleiro.
  final List<Widget> top;

  /// Placa, balança e equação; recebe a largura disponível.
  final Widget Function(double width) stage;
  final Widget controls;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final pad = PageFrame.gutter(constraints.maxWidth);
        final wide = constraints.maxWidth >= wideLayoutBreakpoint;
        final header = [
          for (final w in top) ...[w, const SizedBox(height: 12)],
        ];

        if (wide) {
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(pad, 8, pad, 24),
            child: Column(
              children: [
                ...header,
                const SizedBox(height: 8),
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
                  ...header,
                  stage(width),
                  const SizedBox(height: 12),
                  controls,
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Fator de escala das peças para a largura do palco.
  static double unitFor(double width) => (width / 420).clamp(0.72, 1.15);
}

/// Placa (que desce ao trocar) e balança.
class PlateHeader extends StatelessWidget {
  const PlateHeader({
    super.key,
    required this.plate,
    required this.left,
    required this.right,
  });

  final String plate;
  final double? left;
  final double? right;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
            key: ValueKey(plate),
            text: plate,
            country: l10n.plateCountry,
            height: 58,
          ),
        ),
        const SizedBox(height: 8),
        BalanceScale(left: left, right: right, height: 150),
      ],
    );
  }
}

/// Cartão com a linha da equação e, logo abaixo, a fórmula em LaTeX. Treme
/// quando [errorTick] muda.
class EquationCard extends StatelessWidget {
  const EquationCard({
    super.key,
    required this.pieces,
    required this.caret,
    required this.keys,
    required this.latex,
    required this.locked,
    required this.solved,
    required this.unit,
    required this.errorTick,
    required this.onDrop,
    required this.onCancel,
    required this.onRemove,
    required this.onCaret,
  });

  final List<Piece> pieces;
  final int caret;
  final BoardKeys keys;
  final String latex;
  final bool locked;
  final bool solved;
  final double unit;
  final int errorTick;
  final void Function(DragPayload payload, int gap) onDrop;
  final void Function(DragPayload payload, Offset pointer) onCancel;
  final ValueChanged<int> onRemove;
  final ValueChanged<int> onCaret;

  @override
  Widget build(BuildContext context) {
    return Shake(
      trigger: errorTick,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 14, 8, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              EquationLine(
                pieces: pieces,
                caret: caret,
                keys: keys,
                locked: locked,
                solved: solved,
                unit: unit,
                onDrop: onDrop,
                onCancel: onCancel,
                onRemove: onRemove,
                onCaret: onCaret,
              ),
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 10),
              FormulaView(latex: latex),
            ],
          ),
        ),
      ),
    );
  }
}

/// Botões de baixo: pular (ou equivalente) e verificar / próxima.
class BoardActions extends StatelessWidget {
  const BoardActions({
    super.key,
    required this.solved,
    required this.secondaryLabel,
    required this.secondaryIcon,
    required this.onSecondary,
    required this.onCheck,
    required this.onNext,
  });

  final bool solved;
  final String secondaryLabel;
  final IconData secondaryIcon;
  final VoidCallback? onSecondary;
  final VoidCallback onCheck;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: OutlinedButton.icon(
            onPressed: solved ? null : onSecondary,
            icon: Icon(secondaryIcon),
            label: Text(
              secondaryLabel,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.fade,
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 5,
          child: solved
              ? FilledButton.icon(
                  key: const ValueKey('next'),
                  onPressed: onNext,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: Text(l10n.nextPlate),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    backgroundColor: scheme.tertiary,
                    foregroundColor: scheme.onTertiary,
                  ),
                )
              : FilledButton.icon(
                  key: const ValueKey('verify'),
                  onPressed: onCheck,
                  icon: const Icon(Icons.check_rounded),
                  label: Text(l10n.verify),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Animação dos operadores voltando ao teclado
// ---------------------------------------------------------------------------

/// Leva operadores de volta às suas teclas, com som.
abstract final class OperatorFlights {
  /// Todos os operadores da linha voltam (antes de limpar ou trocar a
  /// placa, enquanto as peças ainda estão na tela).
  static void allHome(
    BuildContext context,
    BoardKeys keys,
    SoundService sounds,
    Iterable<Piece> pieces,
  ) {
    final flights = <Flight>[];
    for (final piece in pieces.whereType<OpPiece>()) {
      final from = globalRectOf(keys.piece(piece));
      final to = globalRectOf(keys.operator(piece.tok));
      if (from == null || to == null) continue;
      flights.add(Flight(from: from, to: to, label: piece.tok.symbol));
    }
    if (flights.isEmpty) return;
    playFlyBack(context, flights);
    sounds.play(SoundEffect.whoosh);
  }

  /// Um operador solto fora da linha volta do ponto onde foi largado.
  static void fromPointer(
    BuildContext context,
    BoardKeys keys,
    SoundService sounds,
    Tok tok,
    Offset pointer,
  ) {
    final to = globalRectOf(keys.operator(tok));
    if (to == null) return;
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
    sounds.play(SoundEffect.whoosh);
  }
}

// ---------------------------------------------------------------------------
// Seletores
// ---------------------------------------------------------------------------

/// Seletor do modo de jogo.
class ModePicker extends StatelessWidget {
  const ModePicker({super.key, required this.mode, required this.onChanged});

  final GameMode mode;
  final ValueChanged<GameMode> onChanged;

  static IconData iconOf(GameMode mode) => switch (mode) {
        GameMode.random => Icons.shuffle_rounded,
        GameMode.specific => Icons.pin_outlined,
        GameMode.adventure => Icons.explore_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = MediaQuery.textScalerOf(context).scale(1);
        // Ícones só quando há espaço para eles e para os nomes.
        final showIcons = constraints.maxWidth >= 480 * scale;
        return Semantics(
          label: l10n.modeLabel,
          container: true,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 640 * scale),
            child: SegmentedButton<GameMode>(
              expandedInsets: EdgeInsets.zero,
              showSelectedIcon: false,
              segments: [
                for (final m in GameMode.values)
                  ButtonSegment(
                    value: m,
                    icon: showIcons ? Icon(iconOf(m)) : null,
                    label: Text(
                      l10n.modeName(m),
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.fade,
                    ),
                  ),
              ],
              selected: {mode},
              onSelectionChanged: (s) => onChanged(s.first),
            ),
          ),
        );
      },
    );
  }
}

/// Seletor de nível: botões segmentados quando cabem, menu quando não.
class LevelPicker extends StatelessWidget {
  const LevelPicker({super.key, required this.level, required this.onChanged});

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
                style: SegmentedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
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

// ---------------------------------------------------------------------------
// Fórmula e mensagens
// ---------------------------------------------------------------------------

/// Fórmula renderizada em LaTeX, logo abaixo da linha montada pelo jogador.
class FormulaView extends StatelessWidget {
  const FormulaView({super.key, required this.latex});

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
class FeedbackBanner extends StatelessWidget {
  const FeedbackBanner({super.key, required this.feedback, this.hint});

  final GameFeedback? feedback;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final feedback = this.feedback;

    String withPenalty(String text, int penalty) =>
        penalty > 0 ? '$text\n${l10n.penaltyNote(penalty)}' : text;

    final (IconData icon, String text, Color background, Color foreground)? data =
        switch (feedback) {
      FeedbackError(:final error, :final penalty) => (
          Icons.error_outline_rounded,
          withPenalty(l10n.exprError(error), penalty),
          scheme.errorContainer,
          scheme.onErrorContainer,
        ),
      FeedbackNotEqual(:final left, :final right, :final penalty) => (
          Icons.balance_rounded,
          withPenalty(
            l10n.notEqualMessage(formatValue(left), formatValue(right)),
            penalty,
          ),
          scheme.errorContainer,
          scheme.onErrorContainer,
        ),
      FeedbackCorrect(:final points, :final saveFailed, :final repeated) => (
          Icons.celebration_rounded,
          [
            repeated ? l10n.correctRepeated : l10n.correctMessage(points),
            if (saveFailed) l10n.saveError,
          ].join('\n'),
          scheme.tertiaryContainer,
          scheme.onTertiaryContainer,
        ),
      FeedbackReward(:final coins) => (
          Icons.paid_rounded,
          l10n.rewardMessage(coins),
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
class Shake extends StatefulWidget {
  const Shake({super.key, required this.trigger, required this.child});

  final int trigger;
  final Widget child;

  @override
  State<Shake> createState() => _ShakeState();
}

class _ShakeState extends State<Shake> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  @override
  void didUpdateWidget(Shake oldWidget) {
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
class SkippedDialog extends StatelessWidget {
  const SkippedDialog({super.key, required this.plate, required this.solution});

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

// ---------------------------------------------------------------------------
// Interação comum dos tabuleiros
// ---------------------------------------------------------------------------

/// Tratadores de arrasto e devolução de operadores, iguais em todos os modos.
mixin BoardInteractions<W extends ConsumerStatefulWidget> on ConsumerState<W> {
  /// Chaves das teclas e peças deste tabuleiro.
  final BoardKeys boardKeys = BoardKeys();

  /// Controlador do modo atual.
  LineEditor get editor;

  /// Linha atual (lida no momento do gesto).
  List<Piece> get currentPieces;

  /// Posição atual do cursor.
  int get currentCaret;

  SoundService get _sounds => ref.read(soundServiceProvider);

  /// Todos os operadores voltam para o teclado. Deve ser chamado antes de o
  /// estado mudar, enquanto as peças ainda estão na tela.
  void flyAllHome() =>
      OperatorFlights.allHome(context, boardKeys, _sounds, currentPieces);

  /// Uma peça foi solta na linha: operador novo do teclado ou peça movida.
  void dropPiece(DragPayload payload, int gap) {
    final id = payload.pieceId;
    final tok = payload.tok;
    if (id != null) {
      editor.movePiece(id, gap);
    } else if (tok != null) {
      editor.insertAt(gap, tok);
    }
  }

  /// O arrasto terminou fora da linha: o operador volta voando para o teclado
  /// (e, se estava na linha, sai dela). O `=` apenas volta ao lugar.
  void dropOutside(DragPayload payload, Offset pointer) {
    final tok = payload.tok;
    if (tok == null) return;
    OperatorFlights.fromPointer(context, boardKeys, _sounds, tok, pointer);
    final id = payload.pieceId;
    if (id != null) editor.removePiece(id);
  }

  /// Tira um operador da linha: ele volta voando para o teclado.
  void removeWithFlight(int id) {
    final piece = currentPieces.where((p) => p.id == id).firstOrNull;
    if (piece is! OpPiece) return;
    OperatorFlights.allHome(context, boardKeys, _sounds, [piece]);
    editor.removePiece(id);
  }

  /// Tecla ⌫: o operador à esquerda do cursor volta para o teclado.
  void deleteBeforeCaret() {
    final pieces = currentPieces;
    final caret = currentCaret;
    if (!canDeleteBefore(pieces, caret)) return;
    removeWithFlight(pieces[caret - 1].id);
  }

  /// Teclado do computador: os símbolos dos operadores (`+ - * / ( ) ! ^ |`,
  /// `x` para ×, `r` para √, `c` para ∛, `[ ] { }` para base e teto) entram
  /// no cursor; ⌫ apaga; as setas, Home e End movem o cursor.
  KeyEventResult handleEditingKey(KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final keyboard = HardwareKeyboard.instance;
    // Atalhos do navegador (Ctrl+C, Ctrl+R...) não são operadores.
    if (keyboard.isControlPressed ||
        keyboard.isMetaPressed ||
        keyboard.isAltPressed) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    final caret = currentCaret;
    if (key == LogicalKeyboardKey.backspace) {
      deleteBeforeCaret();
    } else if (key == LogicalKeyboardKey.arrowLeft) {
      editor.setCaret(caret - 1);
    } else if (key == LogicalKeyboardKey.arrowRight) {
      editor.setCaret(caret + 1);
    } else if (key == LogicalKeyboardKey.home) {
      editor.setCaret(0);
    } else if (key == LogicalKeyboardKey.end) {
      editor.setCaret(currentPieces.length);
    } else {
      final ch = event.character;
      final tok = ch == null
          ? null
          : Tok.fromCode(ch == 'x' || ch == 'X' ? '*' : ch);
      if (tok == null) return KeyEventResult.ignored;
      editor.insertAtCaret(tok);
    }
    return KeyEventResult.handled;
  }
}

/// Layout para `AnimatedSwitcher` que ocupa todo o espaço e alinha as telas
/// ao topo (o padrão as centraliza na vertical).
Widget topAlignedSwitcherLayout(Widget? current, List<Widget> previous) =>
    Stack(
      fit: StackFit.expand,
      alignment: Alignment.topCenter,
      children: [...previous, ?current],
    );
