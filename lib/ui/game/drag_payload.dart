import 'package:flutter/material.dart';

import '../../game/tokens.dart';
import '../../settings/app_theme.dart';

/// O que está sendo arrastado: um operador novo, vindo do teclado, ou uma
/// peça que já está na linha (um operador ou o sinal de igual).
@immutable
class DragPayload {
  const DragPayload.fromKeypad(Tok this.tok) : pieceId = null;
  const DragPayload.fromLine(int this.pieceId, {this.tok});

  /// `null` quando a peça arrastada é o sinal de igual.
  final Tok? tok;

  /// Identificador da peça na linha; `null` se veio do teclado.
  final int? pieceId;

  bool get fromKeypad => pieceId == null;
  String get label => tok?.symbol ?? '=';
}

/// Tamanho da peça que acompanha o dedo/mouse.
const Size kDragFeedbackSize = Size(56, 52);

/// O ponto da peça que fica sob o ponteiro: o centro dela. Assim a posição do
/// ponteiro é `details.offset + kDragAnchor`.
const Offset kDragAnchor = Offset(28, 26);

Offset pointerOf(Offset feedbackOffset) => feedbackOffset + kDragAnchor;

/// Peça que acompanha o ponteiro durante o arrasto.
class DragFeedback extends StatelessWidget {
  const DragFeedback({super.key, required this.payload});

  final DragPayload payload;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isEquals = payload.tok == null;
    final foreground =
        isEquals ? scheme.primary : scheme.onSecondaryContainer;
    return Material(
      type: MaterialType.transparency,
      child: SizedBox.fromSize(
        size: kDragFeedbackSize,
        child: Transform.scale(
          scale: 1.12,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: isEquals ? scheme.surface : scheme.secondaryContainer,
              borderRadius: BorderRadius.circular(isEquals ? 26 : 14),
              border: isEquals
                  ? Border.all(color: foreground, width: 2.5)
                  : null,
              boxShadow: const [
                BoxShadow(
                  color: Color(0x55000000),
                  blurRadius: 14,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: Text(
                payload.label,
                textScaler: TextScaler.noScaling,
                style: mathStyle(context, size: 26, color: foreground),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
