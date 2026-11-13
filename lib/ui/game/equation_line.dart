import 'package:flutter/material.dart';

import '../../game/tokens.dart';
import '../../settings/app_theme.dart';

/// Linha em que a equação é montada: os quatro dígitos fixos, o sinal de
/// igual e os operadores inseridos, com um cursor que indica onde o próximo
/// operador entra.
///
/// Tocar na metade esquerda/direita de uma peça põe o cursor antes/depois
/// dela. Toque longo (ou clique com o botão direito) remove um operador.
class EquationLine extends StatelessWidget {
  const EquationLine({
    super.key,
    required this.pieces,
    required this.cursor,
    required this.locked,
    required this.solved,
    required this.unit,
    required this.onCursor,
    required this.onRemove,
  });

  final List<Piece> pieces;
  final int cursor;

  /// Sem edição (placa resolvida): o cursor some.
  final bool locked;
  final bool solved;

  /// Fator de escala das peças (1.0 = tamanho padrão).
  final double unit;
  final ValueChanged<int> onCursor;
  final ValueChanged<int> onRemove;

  /// Chave global da peça, usada para localizar o operador na tela quando ele
  /// "voa" de volta para o teclado.
  static GlobalKey keyFor(Piece piece) => GlobalObjectKey(piece);

  String get _spoken => pieces
      .map((p) => switch (p) {
            DigitPiece(:final value) => '$value',
            EqualsPiece() => '=',
            OpPiece(:final tok) => tok.symbol,
          })
      .join(' ');

  @override
  Widget build(BuildContext context) {
    final last = pieces.length - 1;
    return Semantics(
      label: _spoken,
      container: true,
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: 10 * unit,
        children: [
          for (final (i, piece) in pieces.indexed)
            _Slot(
              key: ValueKey(piece.id),
              piece: piece,
              unit: unit,
              solved: solved,
              caretBefore: !locked && cursor == i,
              caretAfter: !locked && i == last && cursor == pieces.length,
              isLast: i == last,
              onTapSide: (after) => onCursor(after ? i + 1 : i),
              onRemove: piece is OpPiece ? () => onRemove(piece.id) : null,
            ),
        ],
      ),
    );
  }
}

/// Uma peça com o espaço do cursor à sua esquerda (e, na última peça, também
/// à direita). Manter o cursor junto da peça evita que ele quebre de linha
/// sozinho.
class _Slot extends StatelessWidget {
  const _Slot({
    super.key,
    required this.piece,
    required this.unit,
    required this.solved,
    required this.caretBefore,
    required this.caretAfter,
    required this.isLast,
    required this.onTapSide,
    required this.onRemove,
  });

  final Piece piece;
  final double unit;
  final bool solved;
  final bool caretBefore;
  final bool caretAfter;
  final bool isLast;
  final ValueChanged<bool> onTapSide;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: MouseRegion(
        cursor: SystemMouseCursors.text,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (details) {
            final width = context.size?.width ?? 0;
            onTapSide(details.localPosition.dx > width / 2);
          },
          onLongPress: onRemove,
          onSecondaryTap: onRemove,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Caret(active: caretBefore, unit: unit),
              _Tile(piece: piece, unit: unit, solved: solved),
              if (isLast) _Caret(active: caretAfter, unit: unit),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.piece, required this.unit, required this.solved});

  final Piece piece;
  final double unit;
  final bool solved;

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

    if (piece is! OpPiece) return tile;

    // Operadores entram com um pequeno "pop".
    return TweenAnimationBuilder<double>(
      key: EquationLine.keyFor(piece),
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

/// Espaço do cursor. Ocupa sempre a mesma largura para que a linha não
/// "pule" quando o cursor muda de lugar.
class _Caret extends StatefulWidget {
  const _Caret({required this.active, required this.unit});

  final bool active;
  final double unit;

  @override
  State<_Caret> createState() => _CaretState();
}

class _CaretState extends State<_Caret> with SingleTickerProviderStateMixin {
  late final AnimationController _blink = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 550),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(_Caret oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    final animate = widget.active && !MediaQuery.disableAnimationsOf(context);
    if (animate && !_blink.isAnimating) {
      _blink.repeat(reverse: true);
    } else if (!animate) {
      _blink
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _blink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.tertiary;
    return SizedBox(
      width: 10 * widget.unit,
      height: 60 * widget.unit,
      child: widget.active
          ? Center(
              child: FadeTransition(
                opacity: Tween(begin: 1.0, end: 0.15).animate(_blink),
                child: Container(
                  width: 3.5 * widget.unit,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}
