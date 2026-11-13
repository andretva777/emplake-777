import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers.dart';
import '../data/progress_repository.dart';
import '../game/game_controller.dart';
import '../game/tokens.dart';
import '../l10n/app_localizations.dart';
import '../settings/app_theme.dart';
import 'l10n_extensions.dart';
import 'widgets/app_loader.dart';
import 'widgets/page_frame.dart';

typedef _ProgressData = ({UserProgress progress, List<RankEntry> ranking});

/// Pontuação, placas resolvidas e ranking, lidos do Firestore.
class ProgressPage extends ConsumerStatefulWidget {
  const ProgressPage({super.key});

  @override
  ConsumerState<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends ConsumerState<ProgressPage> {
  late Future<_ProgressData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_ProgressData> _load() async {
    final repo = ref.read(progressRepositoryProvider);
    if (repo == null) {
      return (progress: const UserProgress(), ranking: const <RankEntry>[]);
    }
    final (progress, ranking) =
        await (repo.fetchProgress(), repo.fetchRanking()).wait;
    return (progress: progress, ranking: ranking);
  }

  void _reload() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Recarrega quando o jogo grava algo novo ou quando o usuário muda.
    ref.listen(progressVersionProvider, (_, _) => _reload());
    ref.listen(currentUserProvider.select((u) => u?.uid), (_, _) => _reload());

    return PageFrame(
      title: l10n.progressTitle,
      actions: [
        IconButton(
          tooltip: l10n.refresh,
          onPressed: _reload,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      child: FutureBuilder<_ProgressData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const AppLoader();
          }
          final data = snapshot.data;
          if (snapshot.hasError || data == null) {
            return LoadErrorView(onRetry: _reload);
          }
          return _ProgressBody(data: data);
        },
      ),
    );
  }
}

class _ProgressBody extends ConsumerWidget {
  const _ProgressBody({required this.data});

  final _ProgressData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final progress = data.progress;
    final uid = ref.watch(currentUserProvider.select((u) => u?.uid));

    return LayoutBuilder(
      builder: (context, constraints) {
        final pad = PageFrame.gutter(constraints.maxWidth);
        final wide = constraints.maxWidth >= 840;

        final cards = [
          _StatCard(
            icon: Icons.star_rounded,
            label: l10n.scoreLabel,
            value: progress.score,
          ),
          _StatCard(
            icon: Icons.check_circle_rounded,
            label: l10n.solvedLabel,
            value: progress.solved.length,
          ),
          _StatCard(
            icon: Icons.skip_next_rounded,
            label: l10n.skippedLabel,
            value: progress.skipped,
          ),
          _StatCard(
            icon: Icons.explore_rounded,
            label: l10n.statAdventureBest,
            value: progress.adventureBest,
          ),
        ];
        Widget row(List<Widget> items) => IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (i, card) in items.indexed) ...[
                    if (i > 0) const SizedBox(width: 12),
                    Expanded(child: card),
                  ],
                ],
              ),
            );
        // Quatro números lado a lado só quando há espaço; senão, 2 x 2.
        final stats = constraints.maxWidth - 2 * pad >= 560
            ? row(cards)
            : Column(
                children: [
                  row(cards.sublist(0, 2)),
                  const SizedBox(height: 12),
                  row(cards.sublist(2)),
                ],
              );
        final solved = _SolvedCard(solved: progress.solved);
        final ranking = _RankingCard(entries: data.ranking, currentUid: uid);

        return ListView(
          padding: EdgeInsets.fromLTRB(pad, 8, pad, 24),
          children: [
            stats,
            const SizedBox(height: 16),
            if (wide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: solved),
                  const SizedBox(width: 16),
                  Expanded(flex: 2, child: ranking),
                ],
              )
            else ...[
              solved,
              const SizedBox(height: 16),
              ranking,
            ],
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      label: '$label: $value',
      excludeSemantics: true,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
          child: Column(
            children: [
              Icon(icon, color: scheme.primary),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '$value',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Cor associada a cada nível (derivada do tema).
Color _levelColor(ColorScheme scheme, Level level) => switch (level) {
      Level.easy => scheme.secondary,
      Level.intermediate => scheme.primary,
      Level.advanced => scheme.tertiary,
      Level.hard => scheme.error,
    };

class _SolvedCard extends StatelessWidget {
  const _SolvedCard({required this.solved});

  final Map<String, Level> solved;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final plates = solved.keys.toList()..sort();

    return SectionCard(
      title: l10n.solvedPlatesTitle,
      icon: Icons.directions_car_rounded,
      child: plates.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                l10n.noSolvedYet,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Legenda: cor -> nível.
                Wrap(
                  spacing: 14,
                  runSpacing: 6,
                  children: [
                    for (final level in Level.values)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: _levelColor(scheme, level),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            l10n.levelName(level),
                            style: theme.textTheme.labelMedium,
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final plate in plates)
                      _MiniPlate(plate: plate, level: solved[plate]!),
                  ],
                ),
              ],
            ),
    );
  }
}

class _MiniPlate extends StatelessWidget {
  const _MiniPlate({required this.plate, required this.level});

  final String plate;
  final Level level;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final color = _levelColor(scheme, level);
    return Tooltip(
      message: l10n.levelName(level),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border(
            top: BorderSide(color: color, width: 5),
            left: BorderSide(color: scheme.outlineVariant),
            right: BorderSide(color: scheme.outlineVariant),
            bottom: BorderSide(color: scheme.outlineVariant),
          ),
        ),
        child: Text(
          plate,
          semanticsLabel: '${plate.split('').join(' ')}, ${l10n.levelName(level)}',
          style: mathStyle(context, size: 16, color: scheme.onSurface)
              .copyWith(letterSpacing: 2),
        ),
      ),
    );
  }
}

class _RankingCard extends StatelessWidget {
  const _RankingCard({required this.entries, required this.currentUid});

  final List<RankEntry> entries;
  final String? currentUid;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final ranked = entries.where((e) => e.score > 0).toList();

    return SectionCard(
      title: l10n.rankingTitle,
      icon: Icons.leaderboard_rounded,
      child: ranked.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                l10n.rankingEmpty,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            )
          : Column(
              children: [
                for (final (i, entry) in ranked.indexed)
                  _RankRow(
                    position: i + 1,
                    entry: entry,
                    isMe: entry.uid == currentUid,
                  ),
              ],
            ),
    );
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow({
    required this.position,
    required this.entry,
    required this.isMe,
  });

  final int position;
  final RankEntry entry;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final name = (entry.name?.trim().isNotEmpty ?? false)
        ? entry.name!.trim()
        : l10n.anonymousPlayer;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isMe ? scheme.primaryContainer : scheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: position <= 3
                ? Icon(
                    Icons.emoji_events_rounded,
                    semanticLabel: '$position',
                    color: const [
                      Color(0xFFE0A100),
                      Color(0xFF8E9AA6),
                      Color(0xFFB0703C),
                    ][position - 1],
                  )
                : Text(
                    '$position',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isMe ? '$name (${l10n.rankingYou})' : name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: isMe ? FontWeight.w700 : FontWeight.w500,
                color: isMe ? scheme.onPrimaryContainer : scheme.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.star_rounded,
            size: 18,
            color: isMe ? scheme.onPrimaryContainer : scheme.tertiary,
          ),
          const SizedBox(width: 2),
          Text(
            '${entry.score}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: isMe ? scheme.onPrimaryContainer : scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
