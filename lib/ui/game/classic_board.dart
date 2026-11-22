import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../game/game_controller.dart';
import '../../game/game_mode.dart';
import '../../game/line_editing.dart';
import '../../game/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../settings/app_theme.dart';
import '../l10n_extensions.dart';
import '../widgets/app_loader.dart';
import '../widgets/license_plate.dart';
import '../widgets/page_frame.dart';
import 'board_parts.dart';
import 'operator_tray.dart';

/// Modos aleatório e específico: carrega da nuvem as placas já resolvidas e
/// mostra o tabuleiro (ou, no modo específico, a escolha da placa).
class ClassicView extends ConsumerStatefulWidget {
  const ClassicView({super.key});

  @override
  ConsumerState<ClassicView> createState() => _ClassicViewState();
}

class _ClassicViewState extends ConsumerState<ClassicView> {
  late Future<void> _ready;

  @override
  void initState() {
    super.initState();
    // Depois do quadro atual: o carregamento pode alterar o estado do jogo,
    // o que não é permitido durante a construção da tela.
    _ready = Future.microtask(_load);
  }

  Future<void> _load() => ref.read(gameProvider.notifier).ensureReady();

  void _retry() => setState(() => _ready = _load());

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Outro usuário entrou: recarrega o progresso dele.
    ref.listen(currentUserProvider.select((u) => u?.uid), (_, _) => _retry());
    return FutureBuilder<void>(
      future: _ready,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return AppLoader(label: l10n.loadingPlate);
        }
        if (snapshot.hasError) return LoadErrorView(onRetry: _retry);
        return const _ClassicBoard();
      },
    );
  }
}

class _ClassicBoard extends ConsumerStatefulWidget {
  const _ClassicBoard();

  @override
  ConsumerState<_ClassicBoard> createState() => _ClassicBoardState();
}

class _ClassicBoardState extends ConsumerState<_ClassicBoard>
    with BoardInteractions {
  final FocusNode _focus = FocusNode(debugLabel: 'classic-board');

  GameController get _game => ref.read(gameProvider.notifier);

  @override
  LineEditor get editor => _game;

  @override
  List<Piece> get currentPieces => ref.read(gameProvider).pieces;

  @override
  int get currentCaret => ref.read(gameProvider).caret;

  bool get _specific => ref.read(gameModeProvider) == GameMode.specific;

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  void _clear() {
    flyAllHome();
    _game.clear();
  }

  void _next() {
    flyAllHome();
    _game.next();
  }

  Future<void> _skip() async {
    final plate = ref.read(gameProvider).plate;
    if (plate == null) return;
    final solution = _game.currentSolution();
    flyAllHome();
    _game.skip();
    if (solution != null && mounted) {
      await showDialog<void>(
        context: context,
        builder: (_) => SkippedDialog(plate: plate, solution: solution),
      );
    }
    _focus.requestFocus();
  }

  void _changePlate() {
    flyAllHome();
    _game.changePlate();
  }

  void _setLevel(Level level) {
    if (level == ref.read(gameProvider).level) return;
    flyAllHome();
    _game.setLevel(level);
  }

  /// Enter verifica a equação (ou avança, depois de acertar); as demais
  /// teclas editam a linha.
  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    final state = ref.read(gameProvider);
    if (state.plate == null) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key != LogicalKeyboardKey.enter &&
        key != LogicalKeyboardKey.numpadEnter) {
      return handleEditingKey(event);
    }
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    state.solved ? _next() : _game.check();
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameProvider);
    final specific = ref.watch(gameModeProvider) == GameMode.specific;
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final levelPicker = LevelPicker(level: state.level, onChanged: _setLevel);
    final plate = state.plate;

    if (plate == null) {
      return LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: PageFrame.gutter(constraints.maxWidth),
            vertical: 8,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                children: [
                  levelPicker,
                  const SizedBox(height: 24),
                  if (specific)
                    _PlateInput(level: state.level)
                  else ...[
                    // Todas as placas com solução neste nível já saíram.
                    Icon(
                      Icons.workspace_premium_rounded,
                      size: 72,
                      color: theme.colorScheme.tertiary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.allSolved,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    }

    final evaluation = state.evaluation;
    final enabled = !state.solved;

    return Focus(
      focusNode: _focus,
      autofocus: true,
      onKeyEvent: _onKey,
      child: BoardLayout(
        top: [levelPicker],
        stage: (width) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PlateHeader(
              plate: plate,
              left: evaluation.left.value,
              right: evaluation.right.value,
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
              errorTick: state.errorTick,
              onDrop: dropPiece,
              onCancel: dropOutside,
              onRemove: removeWithFlight,
              onCaret: _game.setCaret,
            ),
            const SizedBox(height: 10),
            FeedbackBanner(
              feedback: state.feedback,
              hint: state.hasOperators ? null : l10n.editHint,
            ),
          ],
        ),
        controls: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            OperatorTray(
              keys: boardKeys,
              operators: state.level.operators,
              enabled: enabled,
              canClear: state.hasOperators,
              canDelete: state.canDeleteBeforeCaret,
              onInsert: _game.insertAtCaret,
              onDelete: deleteBeforeCaret,
              onClear: _clear,
            ),
            const SizedBox(height: 16),
            BoardActions(
              solved: state.solved,
              secondaryLabel: _specific ? l10n.changePlate : l10n.skip,
              secondaryIcon: _specific
                  ? Icons.edit_rounded
                  : Icons.skip_next_rounded,
              onSecondary: _specific ? _changePlate : _skip,
              onCheck: _game.check,
              onNext: _next,
            ),
          ],
        ),
      ),
    );
  }
}

/// Modo específico: o jogador digita os quatro dígitos da placa.
class _PlateInput extends ConsumerStatefulWidget {
  const _PlateInput({required this.level});

  final Level level;

  @override
  ConsumerState<_PlateInput> createState() => _PlateInputState();
}

class _PlateInputState extends ConsumerState<_PlateInput> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() => _error = null));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _play() {
    final l10n = AppLocalizations.of(context);
    final result =
        ref.read(gameProvider.notifier).choosePlate(_controller.text);
    setState(() {
      _error = switch (result) {
        PlateChoice.ok => null,
        PlateChoice.invalid => l10n.specificInvalid,
        PlateChoice.unsolvable =>
          l10n.specificUnsolvable(l10n.levelName(widget.level)),
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final text = _controller.text;
    final repeated = isPlate(text) &&
        ref.read(gameProvider.notifier).wasSolved(text);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.specificTitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            Text(
              l10n.specificPrompt,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            // A placa vai sendo preenchida enquanto o jogador digita.
            Center(
              child: ExcludeSemantics(
                child: LicensePlate(
                  text: text.padRight(4, '·'),
                  country: l10n.plateCountry,
                  height: 64,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: SizedBox(
                width: 220,
                child: TextField(
                  controller: _controller,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.go,
                  textAlign: TextAlign.center,
                  maxLength: 4,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: mathStyle(context, size: 28)
                      .copyWith(letterSpacing: 10),
                  decoration: InputDecoration(
                    labelText: l10n.specificField,
                    border: const OutlineInputBorder(),
                    counterText: '',
                    errorText: _error,
                    errorMaxLines: 3,
                  ),
                  onSubmitted: (_) => _play(),
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              child: repeated
                  ? Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l10n.specificAlreadySolved,
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            ),
            const SizedBox(height: 16),
            Center(
              child: FilledButton.icon(
                onPressed: text.length == 4 ? _play : null,
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(l10n.specificPlay),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(180, 52),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
