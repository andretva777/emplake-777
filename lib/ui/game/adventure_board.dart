import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../game/adventure_controller.dart';
import '../../game/line_editing.dart';
import '../../game/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/app_loader.dart';
import '../widgets/page_frame.dart';
import 'board_parts.dart';
import 'operator_tray.dart';

/// Modo aventura: carrega o recorde da nuvem e mostra a fase atual.
class AdventureView extends ConsumerStatefulWidget {
  const AdventureView({super.key});

  @override
  ConsumerState<AdventureView> createState() => _AdventureViewState();
}

class _AdventureViewState extends ConsumerState<AdventureView> {
  late Future<void> _ready;

  @override
  void initState() {
    super.initState();
    // Depois do quadro atual: o carregamento pode alterar o estado do jogo,
    // o que não é permitido durante a construção da tela.
    _ready = Future.microtask(_load);
  }

  Future<void> _load() => ref.read(adventureProvider.notifier).ensureReady();

  void _retry() => setState(() => _ready = _load());

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    ref.listen(currentUserProvider.select((u) => u?.uid), (_, _) => _retry());
    return FutureBuilder<void>(
      future: _ready,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return AppLoader(label: l10n.loadingPlate);
        }
        if (snapshot.hasError) return LoadErrorView(onRetry: _retry);
        final phase = ref.watch(adventureProvider.select((s) => s.phase));
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          layoutBuilder: topAlignedSwitcherLayout,
          child: switch (phase) {
            AdventurePhase.playing => const _AdventureBoard(),
            AdventurePhase.intro => const _AdventureCard(over: false),
            AdventurePhase.over => const _AdventureCard(over: true),
          },
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Início e fim
// ---------------------------------------------------------------------------

/// Regras da aventura (antes de começar) ou o resultado (depois de acabar).
class _AdventureCard extends ConsumerWidget {
  const _AdventureCard({required this.over});

  final bool over;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final state = ref.watch(adventureProvider);

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: PageFrame.gutter(constraints.maxWidth),
          vertical: 16,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                child: Column(
                  children: [
                    Icon(
                      over
                          ? (state.newRecord
                              ? Icons.emoji_events_rounded
                              : Icons.flag_rounded)
                          : Icons.explore_rounded,
                      size: 64,
                      color: scheme.tertiary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      over ? l10n.adventureOverTitle : l10n.adventureIntroTitle,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    if (over) ...[
                      Text(
                        l10n.adventureOverBody(state.solvedCount),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium,
                      ),
                      if (state.newRecord) ...[
                        const SizedBox(height: 12),
                        Chip(
                          avatar: const Icon(Icons.star_rounded),
                          label: Text(l10n.adventureNewRecord),
                          backgroundColor: scheme.tertiaryContainer,
                        ),
                      ],
                    ] else
                      Text(
                        l10n.adventureIntro(
                          AdventureEconomy.startMoney,
                          AdventureEconomy.wrongPenalty,
                          AdventureEconomy.skipCost,
                        ),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge,
                      ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.adventureBest(state.best),
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      autofocus: true,
                      onPressed: ref.read(adventureProvider.notifier).start,
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: Text(
                        over ? l10n.adventureRestart : l10n.adventureStart,
                      ),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(220, 52),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Partida
// ---------------------------------------------------------------------------

class _AdventureBoard extends ConsumerStatefulWidget {
  const _AdventureBoard();

  @override
  ConsumerState<_AdventureBoard> createState() => _AdventureBoardState();
}

class _AdventureBoardState extends ConsumerState<_AdventureBoard>
    with BoardInteractions {
  final FocusNode _focus = FocusNode(debugLabel: 'adventure-board');
  late final AppLifecycleListener _lifecycle;

  /// A página está na tela (a barra de navegação mantém as outras abas
  /// montadas, mas sem animações).
  bool _visible = true;
  bool _appShown = true;

  AdventureController get _adventure => ref.read(adventureProvider.notifier);

  @override
  LineEditor get editor => _adventure;

  @override
  List<Piece> get currentPieces => ref.read(adventureProvider).pieces;

  @override
  int get currentCaret => ref.read(adventureProvider).caret;

  @override
  void initState() {
    super.initState();
    // O relógio para quando a aba do navegador ou o app ficam escondidos.
    _lifecycle = AppLifecycleListener(
      onShow: () => _setAppShown(true),
      onHide: () => _setAppShown(false),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _visible = TickerMode.valuesOf(context).enabled;
    _syncClock();
  }

  void _setAppShown(bool shown) {
    _appShown = shown;
    _syncClock();
  }

  void _syncClock() {
    if (_visible && _appShown) {
      _adventure.resumeClock();
    } else {
      _adventure.pauseClock();
    }
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _focus.dispose();
    super.dispose();
  }

  // Saindo da tela (troca de modo ou de usuário): o relógio para. `ref` não
  // pode ser usado em `dispose`, por isso a pausa acontece aqui.
  @override
  void deactivate() {
    _adventure.pauseClock();
    super.deactivate();
  }

  void _clear() {
    flyAllHome();
    _adventure.clear();
  }

  void _next() {
    flyAllHome();
    _adventure.next();
  }

  Future<void> _skip() async {
    final state = ref.read(adventureProvider);
    final plate = state.plate;
    if (plate == null || !state.canSkip) return;
    final solution = _adventure.currentSolution();
    flyAllHome();
    _adventure.skip();
    if (solution != null && mounted) {
      await showDialog<void>(
        context: context,
        builder: (_) => SkippedDialog(plate: plate, solution: solution),
      );
    }
    _focus.requestFocus();
  }

  Future<void> _buy(Tok tok) async {
    final upgrade = Upgrade.of(tok);
    if (upgrade == null) return;
    final l10n = AppLocalizations.of(context);
    final money = ref.read(adventureProvider).money;
    final missing = upgrade.price - money;
    final symbols = upgrade.toks.map((t) => t.symbol).join(' ');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.lock_open_rounded),
        title: Text(l10n.adventureBuyTitle(symbols)),
        content: Text(
          missing > 0
              ? l10n.adventureCantAfford(missing)
              : l10n.adventureBuyBody(upgrade.price, money),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed:
                missing > 0 ? null : () => Navigator.of(context).pop(true),
            child: Text(l10n.adventureBuy),
          ),
        ],
      ),
    );
    if (confirmed ?? false) _adventure.buy(upgrade);
    _focus.requestFocus();
  }

  Future<void> _giveUp() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.flag_rounded),
        title: Text(l10n.adventureGiveUpTitle),
        content: Text(l10n.adventureGiveUpBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.adventureGiveUp),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      flyAllHome();
      _adventure.giveUp();
    }
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    final key = event.logicalKey;
    if (key != LogicalKeyboardKey.enter &&
        key != LogicalKeyboardKey.numpadEnter) {
      return handleEditingKey(event);
    }
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    ref.read(adventureProvider).solved ? _next() : _adventure.check();
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(adventureProvider);
    // Nova placa: o relógio volta a contar.
    ref.listen(adventureProvider.select((s) => (s.plate, s.solved)), (_, _) {
      _syncClock();
    });

    final plate = state.plate;
    if (plate == null) return const SizedBox.shrink();
    final evaluation = state.evaluation;
    final enabled = !state.solved;

    return Focus(
      focusNode: _focus,
      autofocus: true,
      onKeyEvent: _onKey,
      child: BoardLayout(
        top: [_Hud(state: state, onGiveUp: _giveUp)],
        stage: (width, compact) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PlateHeader(
              plate: plate,
              left: evaluation.left.value,
              right: evaluation.right.value,
              compact: compact,
            ),
            const SizedBox(height: 12),
            EquationCard(
              pieces: state.pieces,
              caret: state.caret,
              keys: boardKeys,
              latex: state.latex,
              locked: !enabled,
              solved: state.solved,
              unit: BoardLayout.unitFor(width),
              compact: compact,
              errorTick: state.errorTick,
              onDrop: dropPiece,
              onCancel: dropOutside,
              onRemove: removeWithFlight,
              onCaret: _adventure.setCaret,
            ),
            const SizedBox(height: 10),
            // Dica inicial; o resultado da verificação fica no rodapé.
            FeedbackBanner(
              feedback: null,
              hint: state.hasOperators ? null : l10n.editHint,
            ),
          ],
        ),
        controls: OperatorTray(
          keys: boardKeys,
          operators: AdventureRules.all,
          locked: {
            for (final tok in AdventureRules.all)
              if (!state.rules.allows(tok)) tok: Upgrade.of(tok)!.price,
          },
          onLockedTap: _buy,
          enabled: enabled,
          canClear: state.hasOperators,
          canDelete: state.canDeleteBeforeCaret,
          onInsert: _adventure.insertAtCaret,
          onDelete: deleteBeforeCaret,
          onClear: _clear,
        ),
        compactTrailing: PlateHeader.compactBalance(
          left: evaluation.left.value,
          right: evaluation.right.value,
        ),
        footer: BoardFooter(
          feedback: state.feedback,
          actions: BoardActions(
            solved: state.solved,
            secondaryLabel: l10n.adventureSkip(AdventureEconomy.skipCost),
            secondaryIcon: Icons.skip_next_rounded,
            onSecondary: state.canSkip ? _skip : null,
            onCheck: _adventure.check,
            onNext: _next,
          ),
        ),
      ),
    );
  }
}

/// Painel da aventura: moedas, placas resolvidas, prêmio da placa atual e o
/// botão de desistir.
class _Hud extends StatelessWidget {
  const _Hud({required this.state, required this.onGiveUp});

  final AdventureState state;
  final VoidCallback onGiveUp;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final low = state.money <= AdventureEconomy.wrongPenalty;
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        _HudChip(
          icon: Icons.paid_rounded,
          label: l10n.moneyLabel,
          value: state.money,
          background: low ? scheme.errorContainer : scheme.primaryContainer,
          foreground: low ? scheme.onErrorContainer : scheme.onPrimaryContainer,
        ),
        _HudChip(
          icon: Icons.directions_car_rounded,
          label: l10n.adventureSolvedLabel,
          value: state.solvedCount,
          background: scheme.secondaryContainer,
          foreground: scheme.onSecondaryContainer,
        ),
        _HudChip(
          icon: Icons.timer_outlined,
          label: l10n.adventurePotLabel,
          value: state.solved ? 0 : state.reward,
          // Muda a cada segundo: sem animação, para não piscar.
          animate: false,
          background: scheme.tertiaryContainer,
          foreground: scheme.onTertiaryContainer,
        ),
        IconButton(
          tooltip: l10n.adventureGiveUp,
          onPressed: onGiveUp,
          icon: const Icon(Icons.flag_outlined),
        ),
      ],
    );
  }
}

class _HudChip extends StatelessWidget {
  const _HudChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.background,
    required this.foreground,
    this.animate = true,
  });

  final IconData icon;
  final bool animate;
  final String label;
  final int value;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: '$label: $value',
      excludeSemantics: true,
      child: Tooltip(
        message: label,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: foreground),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(color: foreground),
              ),
              const SizedBox(width: 6),
              AnimatedSwitcher(
                duration: animate
                    ? const Duration(milliseconds: 250)
                    : Duration.zero,
                transitionBuilder: (child, animation) =>
                    ScaleTransition(scale: animation, child: child),
                child: Text(
                  '$value',
                  key: ValueKey(value),
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w800,
                    fontFeatures: const [FontFeature.tabularFigures()],
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
