import 'package:emplake/data/progress_repository.dart';
import 'package:emplake/game/tokens.dart';

/// Repositório em memória, usado nos testes e no modo de demonstração.
class FakeProgressRepository implements ProgressRepository {
  FakeProgressRepository({
    Map<String, Level>? solved,
    this.skipped = 0,
    this.failWrites = false,
    this.delay = Duration.zero,
    this.others = const [],
    this.adventureBest = 0,
    this.writeDelay = Duration.zero,
  }) : solved = {...?solved};

  final Map<String, Level> solved;

  /// Placas enviadas a [markSolved], na ordem. No Firestore cada chamada
  /// soma pontos (`FieldValue.increment`), então uma placa não pode repetir.
  final List<String> markSolvedCalls = [];

  /// Tempo até uma gravação chegar à "nuvem".
  final Duration writeDelay;
  int skipped;
  bool failWrites;
  final Duration delay;
  final List<RankEntry> others;
  int adventureBest;

  int get score => solved.values.fold(0, (sum, l) => sum + l.points);

  @override
  Future<UserProgress> fetchProgress() async {
    await Future<void>.delayed(delay);
    return UserProgress(
      score: score,
      skipped: skipped,
      solved: {...solved},
      adventureBest: adventureBest,
    );
  }

  @override
  Future<void> markSolved(String plate, Level level) async {
    if (failWrites) throw StateError('offline');
    markSolvedCalls.add(plate);
    await Future<void>.delayed(writeDelay);
    solved[plate] = level;
  }

  @override
  Future<void> markSkipped(String plate) async {
    if (failWrites) throw StateError('offline');
    skipped++;
  }

  @override
  Future<void> saveAdventureBest(int best) async {
    if (failWrites) throw StateError('offline');
    adventureBest = best;
  }

  @override
  Future<List<RankEntry>> fetchRanking({int limit = 10}) async {
    await Future<void>.delayed(delay);
    final all = [
      ...others,
      RankEntry(
        uid: 'demo',
        name: 'Demo',
        score: score,
        solvedCount: solved.length,
      ),
    ]..sort((a, b) => b.score.compareTo(a.score));
    return all.take(limit).toList();
  }
}
