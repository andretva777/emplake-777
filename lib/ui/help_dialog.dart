import 'package:flutter/material.dart';

import '../game/tokens.dart';
import '../l10n/app_localizations.dart';
import '../settings/app_theme.dart';
import 'l10n_extensions.dart';

/// Abre a ajuda do jogo (botão "Ajuda" da barra de navegação).
Future<void> showHelpDialog(BuildContext context) => showDialog<void>(
      context: context,
      builder: (context) => const _HelpDialog(),
    );

class _HelpDialog extends StatelessWidget {
  const _HelpDialog();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return AlertDialog(
      icon: const Icon(Icons.help_rounded),
      title: Text(l10n.helpTitle),
      scrollable: true,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _HelpItem(Icons.flag_rounded, l10n.helpGoalTitle, l10n.helpGoal),
            _HelpItem(Icons.sports_esports_rounded, l10n.helpModesTitle,
                l10n.helpModes),
            _HelpItem(
                Icons.touch_app_rounded, l10n.helpHowTitle, l10n.helpHow),
            _HelpItem(
                Icons.balance_rounded, l10n.helpScaleTitle, l10n.helpScale),
            _HelpItem(Icons.rule_rounded, l10n.helpRulesTitle, l10n.helpRules),
            _HelpItem(Icons.format_list_numbered_rounded, l10n.helpOrderTitle,
                l10n.helpOrder),
            _HelpItem(
                Icons.skip_next_rounded, l10n.helpSkipTitle, l10n.helpSkip),
            _HelpItem(Icons.keyboard_rounded, l10n.helpKeyboardTitle,
                l10n.helpKeyboard),
            const SizedBox(height: 4),
            Text(
              l10n.helpLevelsTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            for (final level in Level.values) _LevelHelp(level),
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.close),
        ),
      ],
    );
  }
}

class _HelpItem extends StatelessWidget {
  const _HelpItem(this.icon, this.title, this.body);

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(body, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Nome do nível, pontuação e os operadores liberados nele.
class _LevelHelp extends StatelessWidget {
  const _LevelHelp(this.level);

  final Level level;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: l10n.levelName(level),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                TextSpan(
                  text: '  ·  ${l10n.levelPoints(level.points)}',
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final tok in level.operators)
                Tooltip(
                  message: l10n.operatorName(tok) ?? tok.symbol,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 30),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                    decoration: BoxDecoration(
                      color: scheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      tok.symbol,
                      textAlign: TextAlign.center,
                      semanticsLabel: l10n.operatorName(tok),
                      style: mathStyle(
                        context,
                        size: 15,
                        color: scheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
