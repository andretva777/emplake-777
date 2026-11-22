import 'package:flutter/material.dart';

import '../../game/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../settings/app_theme.dart';
import '../l10n_extensions.dart';
import 'board_keys.dart';
import 'drag_payload.dart';

/// Teclado de operadores. Tocar numa tecla insere o operador na posição do
/// cursor; a tecla também pode ser arrastada até a linha da equação. O
/// teclado nunca se esgota (dá para usar o mesmo operador mais de uma vez).
/// No modo aventura, algumas teclas ficam bloqueadas até serem compradas.
class OperatorTray extends StatelessWidget {
  const OperatorTray({
    super.key,
    required this.operators,
    required this.keys,
    required this.enabled,
    required this.canClear,
    required this.canDelete,
    required this.onInsert,
    required this.onDelete,
    required this.onClear,
    this.locked = const {},
    this.onLockedTap,
  });

  final List<Tok> operators;

  /// Chaves das teclas (destino da animação de retorno).
  final BoardKeys keys;

  /// Operadores bloqueados e o preço de cada um.
  final Map<Tok, int> locked;
  final ValueChanged<Tok>? onLockedTap;
  final bool enabled;
  final bool canClear;

  /// Há um operador logo à esquerda do cursor para a tecla ⌫ apagar.
  final bool canDelete;

  /// Toque numa tecla: insere o operador no cursor.
  final ValueChanged<Tok> onInsert;

  /// Tecla ⌫: apaga o operador à esquerda do cursor.
  final VoidCallback onDelete;
  final VoidCallback onClear;

  /// Chave local da tecla de um operador (para localizá-la nos testes).
  static Key valueKeyFor(Tok tok) => ValueKey('op-${tok.name}');

  /// Chave da tecla ⌫.
  static const deleteKey = ValueKey('op-delete');

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
                  key: valueKeyFor(tok),
                  globalKey: keys.operator(tok),
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
                  key: valueKeyFor(tok),
                  globalKey: keys.operator(tok),
                  tok: tok,
                  name: l10n.operatorName(tok) ?? tok.symbol,
                  enabled: enabled,
                  onInsert: () => onInsert(tok),
                ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          children: [
            TextButton.icon(
              key: deleteKey,
              onPressed: enabled && canDelete ? onDelete : null,
              icon: const Icon(Icons.backspace_outlined),
              label: Text(l10n.deleteOperator),
            ),
            TextButton.icon(
              onPressed: enabled && canClear ? onClear : null,
              icon: const Icon(Icons.replay_rounded),
              label: Text(l10n.clear),
            ),
          ],
        ),
      ],
    );
  }
}

class _OperatorKey extends StatelessWidget {
  const _OperatorKey({
    super.key,
    required this.globalKey,
    required this.tok,
    required this.name,
    required this.enabled,
    required this.onInsert,
  });

  final GlobalKey globalKey;
  final Tok tok;
  final String name;
  final bool enabled;
  final VoidCallback onInsert;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Widget face({double opacity = 1, VoidCallback? onTap}) => Opacity(
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
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            // O teclado do computador é tratado pelo tabuleiro.
            canRequestFocus: false,
            child: Center(
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
          ),
        ),
      ),
    );

    // Toque insere no cursor; arrastar solta onde o jogador quiser.
    final Widget key = enabled
        ? MouseRegion(
            cursor: SystemMouseCursors.click,
            child: DragPointerKind(
              child: Draggable<DragPayload>(
                data: DragPayload.fromKeypad(tok),
                maxSimultaneousDrags: 1,
                dragAnchorStrategy: dragAnchor,
                feedback: DragFeedback(payload: DragPayload.fromKeypad(tok)),
                childWhenDragging: face(opacity: 0.35),
                child: face(onTap: onInsert),
              ),
            ),
          )
        : face(opacity: 0.4);

    return Tooltip(
      key: globalKey,
      message: name,
      child: Semantics(
        button: true,
        label: name,
        enabled: enabled,
        excludeSemantics: true,
        onTap: enabled ? onInsert : null,
        child: key,
      ),
    );
  }
}

/// Tecla bloqueada (modo aventura): mostra o preço; o toque abre a compra.
class _LockedKey extends StatelessWidget {
  const _LockedKey({
    super.key,
    required this.globalKey,
    required this.tok,
    required this.price,
    required this.label,
    required this.onTap,
  });

  final GlobalKey globalKey;
  final Tok tok;
  final int price;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Tooltip(
      key: globalKey,
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
