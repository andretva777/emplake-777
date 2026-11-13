import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../audio/sound_service.dart';
import '../../game/game_controller.dart';
import '../../game/game_mode.dart';
import '../../l10n/app_localizations.dart';
import '../../settings/settings_controller.dart';
import '../widgets/page_frame.dart';
import 'adventure_board.dart';
import 'board_parts.dart';
import 'classic_board.dart';

/// Página principal do jogo: o seletor de modo e o tabuleiro do modo
/// escolhido. Cada modo carrega os seus dados da nuvem com um FutureBuilder.
class GamePage extends ConsumerWidget {
  const GamePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final mode = ref.watch(gameModeProvider);

    return PageFrame(
      title: l10n.appTitle,
      actions: const [_ScoreChip(), SizedBox(width: 4), _SoundToggle()],
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) => Padding(
              padding: EdgeInsets.fromLTRB(
                PageFrame.gutter(constraints.maxWidth),
                4,
                PageFrame.gutter(constraints.maxWidth),
                8,
              ),
              child: Center(
                child: ModePicker(
                  mode: mode,
                  onChanged: ref.read(gameModeProvider.notifier).select,
                ),
              ),
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              layoutBuilder: topAlignedSwitcherLayout,
              // A chave recria a tela ao trocar de modo, recarregando os dados.
              child: mode == GameMode.adventure
                  ? const AdventureView(key: ValueKey(GameMode.adventure))
                  : ClassicView(key: ValueKey(mode)),
            ),
          ),
        ],
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

