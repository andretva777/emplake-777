import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../game/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../settings/app_theme.dart';
import '../l10n_extensions.dart';
import 'drag_payload.dart';

/// Teclado de operadores. Cada tecla é arrastada até a linha da equação; o
/// teclado nunca se esgota (dá para usar o mesmo operador mais de uma vez).
/// No modo aventura, algumas teclas ficam bloqueadas até serem compradas.
class OperatorTray extends StatelessWidget {
  const OperatorTray({
    super.key,
    required this.operators,
    required this.enabled,
    required this.canClear,
    required this.onAddToEnd,
    required this.onClear,
    this.locked = const {},
    this.onLockedTap,
  });

  final List<Tok> operators;

  /// Operadores bloqueados e o preço de cada um.
  final Map<Tok, int> locked;
  final ValueChanged<Tok>? onLockedTap;
  final bool enabled;
  final bool canClear;

  /// Alternativa ao arrasto para leitores de tela: acrescenta o operador ao
  /// fim da equação.
  final ValueChanged<Tok> onAddToEnd;
  final VoidCallback onClear;

  /// Chave global da tecla de um operador (destino da animação de retorno).
  static GlobalKey keyFor(Tok tok) => GlobalObjectKey(tok);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.operatorsLabel.toUpperCase(),
          textAlign: TextAlign.center,
          style: theme.textTheme.labelSmall?.copyWith(
            color: scheme.onSurfaceVariant,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final tok in operators)
              if (locked[tok] case final price?)
                _LockedKey(
                  key: keyFor(tok),
                  tok: tok,
                  price: price,
                  label: l10n.adventureLocked(
                    l10n.operatorName(tok) ?? tok.symbol,
                    price,
                  ),
                  onTap: enabled && onLockedTap != null
                      ? () => onLockedTap!(tok)
                      : null,
                )
              else
                _OperatorKey(
                  key: keyFor(tok),
                  tok: tok,
                  name: l10n.operatorName(tok) ?? tok.symbol,
                  addToEndLabel: l10n.addToEnd,
                  enabled: enabled,
                  onAddToEnd: () => onAddToEnd(tok),
                ),
          ],
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton.icon(
            onPressed: enabled && canClear ? onClear : null,
            icon: const Icon(Icons.replay_rounded),
            label: Text(l10n.clear),
          ),
        ),
      ],
    );
  }
}

class _OperatorKey extends StatelessWidget {
  const _OperatorKey({
    super.key,
    required this.tok,
    required this.name,
    required this.addToEndLabel,
    required this.enabled,
    required this.onAddToEnd,
  });

  final Tok tok;
  final String name;
  final String addToEndLabel;
  final bool enabled;
  final VoidCallback onAddToEnd;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Widget face({double opacity = 1}) => Opacity(
      opacity: opacity,
      child: Container(
        width: kDragFeedbackSize.width,
        height: kDragFeedbackSize.height,
        decoration: BoxDecoration(
          color: scheme.secondaryContainer,
          borderRadius: BorderRadius.circular(14),
          boxShadow: enabled
              ? const [
                  BoxShadow(
                    color: Color(0x26000000),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          tok.symbol,
          textScaler: TextScaler.noScaling,
          style: mathStyle(
            context,
            size: 22,
            color: scheme.onSecondaryContainer,
          ),
        ),
      ),
    );

    final Widget key = enabled
        ? MouseRegion(
            cursor: SystemMouseCursors.grab,
            child: Draggable<DragPayload>(
              data: DragPayload.fromKeypad(tok),
              maxSimultaneousDrags: 1,
              dragAnchorStrategy: (_, _, _) => kDragAnchor,
              feedback: DragFeedback(payload: DragPayload.fromKeypad(tok)),
              childWhenDragging: face(opacity: 0.35),
              child: face(),
            ),
          )
        : face(opacity: 0.4);

    return Tooltip(
      message: name,
      child: Semantics(
        label: name,
        enabled: enabled,
        excludeSemantics: true,
        customSemanticsActions: enabled
            ? {CustomSemanticsAction(label: addToEndLabel): onAddToEnd}
            : null,
        child: key,
      ),
    );
  }
}

/// Tecla bloqueada (modo aventura): mostra o preço; o toque abre a compra.
class _LockedKey extends StatelessWidget {
  const _LockedKey({
    super.key,
    required this.tok,
    required this.price,
    required this.label,
    required this.onTap,
  });

  final Tok tok;
  final int price;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        enabled: onTap != null,
        label: label,
        excludeSemantics: true,
        child: Material(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: SizedBox.fromSize(
              size: kDragFeedbackSize,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    tok.symbol,
                    textScaler: TextScaler.noScaling,
                    style: mathStyle(
                      context,
                      size: 20,
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.45),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      color: scheme.tertiaryContainer,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 2,
                        vertical: 1,
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.lock_rounded,
                              size: 11,
                              color: scheme.onTertiaryContainer,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '$price',
                              textScaler: TextScaler.noScaling,
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: scheme.onTertiaryContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
