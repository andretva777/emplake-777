import 'package:flutter/gestures.dart';
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

/// Com o mouse, o ponteiro fica no centro da peça arrastada.
const Offset _mouseAnchor = Offset(28, 26);

/// No toque, a peça fica um pouco acima do dedo, para que nem ela nem a
/// marca de onde ela vai entrar fiquem escondidas sob ele.
const Offset _touchAnchor = Offset(28, 52 + 36);

/// Tipo do último ponteiro que tocou numa peça arrastável.
PointerDeviceKind _lastKind = PointerDeviceKind.mouse;

/// Ponto da peça arrastada que fica sob o ponteiro (no arrasto atual).
Offset _activeAnchor = _mouseAnchor;

/// Estratégia de âncora dos arrastos: escolhe a âncora pelo tipo do ponteiro.
Offset dragAnchor(Draggable<Object> draggable, BuildContext context, Offset _) =>
    _activeAnchor = switch (_lastKind) {
      PointerDeviceKind.mouse || PointerDeviceKind.trackpad => _mouseAnchor,
      _ => _touchAnchor,
    };

/// Posição do ponteiro a partir da posição da peça arrastada.
Offset pointerOf(Offset feedbackOffset) => feedbackOffset + _activeAnchor;

/// Centro da peça arrastada quando o ponteiro está em [pointer].
Offset feedbackCenterOf(Offset pointer) =>
    pointer - _activeAnchor + kDragFeedbackSize.center(Offset.zero);

/// Anota o tipo do ponteiro que toca em [child] (antes de o arrasto começar).
class DragPointerKind extends StatelessWidget {
  const DragPointerKind({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Listener(
        onPointerDown: (event) => _lastKind = event.kind,
        child: child,
      );
}

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
