import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../game/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../settings/app_theme.dart';
import '../l10n_extensions.dart';
import 'board_keys.dart';
import 'drag_payload.dart';

/// Linha em que a equação é montada: os quatro dígitos fixos, o sinal de
/// igual e os operadores soltos pelo jogador.
///
/// A linha tem um cursor (uma barra entre duas peças): tocar numa peça põe o
/// cursor do lado tocado, e as teclas do teclado inserem o operador ali.
/// Operadores (do teclado ou da própria linha) e o `=` também podem ser
/// arrastados e soltos entre duas peças; uma marca mostra onde a peça vai
/// entrar. Soltar um operador fora da linha o devolve ao teclado.
class EquationLine extends StatefulWidget {
  const EquationLine({
    super.key,
    required this.pieces,
    required this.caret,
    required this.keys,
    required this.locked,
    required this.solved,
    required this.unit,
    required this.onDrop,
    required this.onCancel,
    required this.onRemove,
    required this.onCaret,
  });

  final List<Piece> pieces;

  /// Posição do cursor (0 a `pieces.length`).
  final int caret;

  /// Chaves das peças (origem da animação de retorno).
  final BoardKeys keys;

  /// Sem edição (placa resolvida).
  final bool locked;
  final bool solved;

  /// Fator de escala das peças (1.0 = tamanho padrão).
  final double unit;

  /// Uma peça foi solta na posição [gap] (0 a `pieces.length`).
  final void Function(DragPayload payload, int gap) onDrop;

  /// Um arrasto terminou fora da linha; [pointer] é a posição global.
  final void Function(DragPayload payload, Offset pointer) onCancel;

  /// Remove um operador da linha (ação de acessibilidade).
  final ValueChanged<int> onRemove;

  /// Toque na linha: o cursor vai para a posição indicada.
  final ValueChanged<int> onCaret;

  /// Chave local da peça na linha (para localizá-la nos testes).
  static Key valueKeyFor(Piece piece) => ValueKey(('piece', piece.id));

  @override
  State<EquationLine> createState() => _EquationLineState();
}

class _EquationLineState extends State<EquationLine> {
  /// Posição em que a peça arrastada entraria, e a peça que a calculou.
  int? _hoverGap;
  int? _hoverOwner;

  void _hover(int owner, int gap) {
    if (_hoverGap == gap && _hoverOwner == owner) return;
    setState(() {
      _hoverGap = gap;
      _hoverOwner = owner;
    });
  }

  void _leave(int owner) {
    // Só limpa se a marca ainda é desta peça (a vizinha pode já ter assumido).
    if (_hoverOwner != owner) return;
    setState(() {
      _hoverGap = null;
      _hoverOwner = null;
    });
  }

  void _drop(DragPayload payload, int gap) {
    setState(() {
      _hoverGap = null;
      _hoverOwner = null;
    });
    widget.onDrop(payload, gap);
  }

  @override
  void didUpdateWidget(EquationLine oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.locked) _hoverGap = _hoverOwner = null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pieces = widget.pieces;
    final last = pieces.length - 1;
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: 10 * widget.unit,
      children: [
        for (final (i, piece) in pieces.indexed)
          _Slot(
            key: EquationLine.valueKeyFor(piece),
            piece: piece,
            keys: widget.keys,
            index: i,
            unit: widget.unit,
            solved: widget.solved,
            locked: widget.locked,
            gapBefore: _hoverGap == i,
            gapAfter: i == last && _hoverGap == pieces.length,
            caretBefore: !widget.locked && widget.caret == i,
            caretAfter:
                !widget.locked && i == last && widget.caret == pieces.length,
            isLast: i == last,
            l10n: l10n,
            onHover: (gap) => _hover(i, gap),
            onLeave: () => _leave(i),
            onDrop: _drop,
            onCancel: widget.onCancel,
            onCaret: widget.onCaret,
            onRemove: piece is OpPiece ? () => widget.onRemove(piece.id) : null,
            onShift: piece is DigitPiece
                ? null
                : (delta) => _drop(
                      DragPayload.fromLine(
                        piece.id,
                        tok: piece is OpPiece ? piece.tok : null,
                      ),
                      // `gap` conta posições antes da remoção da peça.
                      delta < 0 ? i - 1 : i + 2,
                    ),
            canShiftLeft: i > 0,
            canShiftRight: i < last,
          ),
      ],
    );
  }
}

/// Uma peça com o espaço de soltura à sua esquerda (e, na última peça, também
/// à direita). Manter a marca junto da peça evita que ela quebre de linha
/// sozinha.
class _Slot extends StatelessWidget {
  const _Slot({
    super.key,
    required this.piece,
    required this.keys,
    required this.index,
    required this.unit,
    required this.solved,
    required this.locked,
    required this.gapBefore,
    required this.gapAfter,
    required this.caretBefore,
    required this.caretAfter,
    required this.isLast,
    required this.l10n,
    required this.onHover,
    required this.onLeave,
    required this.onDrop,
    required this.onCancel,
    required this.onCaret,
    required this.onRemove,
    required this.onShift,
    required this.canShiftLeft,
    required this.canShiftRight,
  });

  final Piece piece;
  final BoardKeys keys;
  final int index;
  final double unit;
  final bool solved;
  final bool locked;
  final bool gapBefore;
  final bool gapAfter;

  /// O cursor está antes desta peça (ou depois, na última).
  final bool caretBefore;
  final bool caretAfter;
  final bool isLast;
  final AppLocalizations l10n;
  final ValueChanged<int> onHover;
  final VoidCallback onLeave;
  final void Function(DragPayload payload, int gap) onDrop;
  final void Function(DragPayload payload, Offset pointer) onCancel;
  final ValueChanged<int> onCaret;
  final VoidCallback? onRemove;
  final ValueChanged<int>? onShift;
  final bool canShiftLeft;
  final bool canShiftRight;

  String get _spoken => switch (piece) {
        DigitPiece(:final value) => '$value',
        EqualsPiece() => '=',
        OpPiece(:final tok) => l10n.operatorName(tok) ?? tok.symbol,
      };

  /// Em qual lado desta peça o ponteiro está, e portanto em que posição da
  /// linha a peça arrastada entraria.
  int _gapFor(BuildContext context, Offset pointer) {
    final box = context.findRenderObject() as RenderBox;
    final local = box.globalToLocal(pointer);
    return local.dx > box.size.width / 2 ? index + 1 : index;
  }

  @override
  Widget build(BuildContext context) {
    final tile = _Tile(
      piece: piece,
      unit: unit,
      solved: solved,
      globalKey: keys.piece(piece),
    );

    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Gap(active: gapBefore, caret: caretBefore, unit: unit),
        _draggable(context, tile),
        if (isLast) _Gap(active: gapAfter, caret: caretAfter, unit: unit),
      ],
    );

    if (!locked) {
      // Tocar põe o cursor do lado tocado da peça.
      content = MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (details) =>
              onCaret(_gapFor(context, details.globalPosition)),
          child: content,
        ),
      );
      final inner = content;
      content = DragTarget<DragPayload>(
        onWillAcceptWithDetails: (details) {
          onHover(_gapFor(context, pointerOf(details.offset)));
          return true;
        },
        onMove: (details) =>
            onHover(_gapFor(context, pointerOf(details.offset))),
        onLeave: (_) => onLeave(),
        onAcceptWithDetails: (details) => onDrop(
          details.data,
          _gapFor(context, pointerOf(details.offset)),
        ),
        builder: (context, _, _) => inner,
      );
    }

    final shift = onShift;
    return Semantics(
      label: _spoken,
      excludeSemantics: true,
      // Ativar a peça põe o cursor logo depois dela.
      onTap: locked ? null : () => onCaret(index + 1),
      customSemanticsActions: locked
          ? null
          : {
              if (shift != null && canShiftLeft)
                CustomSemanticsAction(label: l10n.moveLeft): () => shift(-1),
              if (shift != null && canShiftRight)
                CustomSemanticsAction(label: l10n.moveRight): () => shift(1),
              CustomSemanticsAction(label: l10n.removeOperator): ?onRemove,
            },
      child: content,
    );
  }

  Widget _draggable(BuildContext context, Widget tile) {
    final piece = this.piece;
    if (locked || piece is DigitPiece) return tile;
    final payload = DragPayload.fromLine(
      piece.id,
      tok: piece is OpPiece ? piece.tok : null,
    );
    return MouseRegion(
      cursor: SystemMouseCursors.grab,
      child: Draggable<DragPayload>(
        data: payload,
        maxSimultaneousDrags: 1,
        dragAnchorStrategy: (_, _, _) => kDragAnchor,
        feedback: DragFeedback(payload: payload),
        childWhenDragging: Opacity(
          opacity: 0.25,
          child: _Tile(
            piece: piece,
            unit: unit,
            solved: solved,
            pop: false,
          ),
        ),
        onDragEnd: (details) {
          if (!details.wasAccepted) {
            onCancel(payload, pointerOf(details.offset));
          }
        },
        child: tile,
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.piece,
    required this.unit,
    required this.solved,
    this.globalKey,
    this.pop = true,
  });

  final Piece piece;
  final double unit;
  final bool solved;

  /// Chave global da peça (só uma instância por vez pode usá-la).
  final GlobalKey? globalKey;

  /// Anima a entrada do operador.
  final bool pop;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final piece = this.piece;

    final (String label, Color background, Color foreground, double minWidth,
        double height, double fontSize, double radius) = switch (piece) {
      DigitPiece(:final value) => (
          '$value',
          solved ? scheme.tertiary : scheme.primary,
          solved ? scheme.onTertiary : scheme.onPrimary,
          46.0,
          60.0,
          32.0,
          12.0,
        ),
      EqualsPiece() => (
          '=',
          scheme.surface,
          solved ? scheme.tertiary : scheme.primary,
          40.0,
          48.0,
          30.0,
          24.0,
        ),
      OpPiece(:final tok) => (
          tok.symbol,
          scheme.secondaryContainer,
          scheme.onSecondaryContainer,
          34.0,
          48.0,
          24.0,
          10.0,
        ),
    };

    final tile = AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      constraints: BoxConstraints(minWidth: minWidth * unit),
      height: height * unit,
      padding: EdgeInsets.symmetric(horizontal: 6 * unit),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(radius * unit),
        border: piece is EqualsPiece
            ? Border.all(color: foreground, width: 2.5 * unit)
            : null,
        boxShadow: piece is DigitPiece
            ? const [
                BoxShadow(
                  color: Color(0x30000000),
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Text(
        label,
        textScaler: TextScaler.noScaling,
        style: mathStyle(context, size: fontSize * unit, color: foreground),
      ),
    );

    if (piece is! OpPiece || !pop) return tile;

    // Operadores entram com um pequeno "pop".
    return TweenAnimationBuilder<double>(
      key: globalKey,
      tween: Tween(begin: 0.3, end: 1),
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 260),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: tile,
    );
  }
}

/// Espaço entre peças. Ocupa sempre a mesma largura para que a linha não
/// "pule" durante o arrasto; quando ativo, mostra onde a peça arrastada
/// entraria. Também é onde o cursor aparece.
class _Gap extends StatelessWidget {
  const _Gap({required this.active, required this.caret, required this.unit});

  /// Uma peça arrastada entraria aqui.
  final bool active;

  /// O cursor está aqui.
  final bool caret;
  final double unit;

  /// Chave do cursor (para localizá-lo nos testes).
  static const caretKey = ValueKey('caret');

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final showCaret = caret && !active;
    return SizedBox(
      width: 10 * unit,
      height: 60 * unit,
      child: Center(
        child: AnimatedContainer(
          key: showCaret ? caretKey : null,
          duration: const Duration(milliseconds: 120),
          width: (showCaret ? 3 : 4) * unit,
          height: active || showCaret ? 60 * unit : 0,
          decoration: BoxDecoration(
            color: active ? scheme.tertiary : scheme.primary,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }
}
