import 'package:flutter/material.dart';

import '../../game/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../settings/app_theme.dart';
import '../l10n_extensions.dart';

/// Teclado de operadores do nível atual, mais os controles de edição.
class Keypad extends StatelessWidget {
  const Keypad({
    super.key,
    required this.level,
    required this.enabled,
    required this.canClear,
    required this.onInsert,
    required this.onMoveEquals,
    required this.onMoveCursor,
    required this.onBackspace,
    required this.onClear,
  });

  final Level level;
  final bool enabled;
  final bool canClear;
  final ValueChanged<Tok> onInsert;
  final VoidCallback onMoveEquals;
  final ValueChanged<int> onMoveCursor;
  final VoidCallback onBackspace;
  final VoidCallback onClear;

  /// Chave global do botão de um operador (destino da animação de retorno).
  static GlobalKey keyFor(Tok tok) => GlobalObjectKey(tok);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final tok in level.operators)
              _Key(
                key: keyFor(tok),
                label: tok.symbol,
                tooltip: l10n.operatorName(tok),
                background: scheme.secondaryContainer,
                foreground: scheme.onSecondaryContainer,
                onPressed: enabled ? () => onInsert(tok) : null,
              ),
            _Key(
              label: '=',
              tooltip: l10n.moveEquals,
              background: scheme.primaryContainer,
              foreground: scheme.onPrimaryContainer,
              onPressed: enabled ? onMoveEquals : null,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            IconButton.filledTonal(
              tooltip: l10n.moveLeft,
              onPressed: enabled ? () => onMoveCursor(-1) : null,
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            IconButton.filledTonal(
              tooltip: l10n.moveRight,
              onPressed: enabled ? () => onMoveCursor(1) : null,
              icon: const Icon(Icons.chevron_right_rounded),
            ),
            IconButton.filledTonal(
              tooltip: l10n.backspace,
              onPressed: enabled ? onBackspace : null,
              icon: const Icon(Icons.backspace_outlined),
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

class _Key extends StatelessWidget {
  const _Key({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
    required this.onPressed,
    this.tooltip,
  });

  final String label;
  final String? tooltip;
  final Color background;
  final Color foreground;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final button = Semantics(
      button: true,
      enabled: enabled,
      label: tooltip == null ? label : '$label, $tooltip',
      excludeSemantics: true,
      child: Material(
        color: enabled ? background : background.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox(
            width: 56,
            height: 52,
            child: Center(
              child: Text(
                label,
                textScaler: TextScaler.noScaling,
                style: mathStyle(
                  context,
                  size: 22,
                  color: enabled
                      ? foreground
                      : foreground.withValues(alpha: 0.4),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    final message = tooltip;
    return message == null ? button : Tooltip(message: message, child: button);
  }
}
