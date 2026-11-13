import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers.dart';
import '../game/tokens.dart';

/// Progresso de um jogador guardado na nuvem.
class UserProgress {
  const UserProgress({
    this.score = 0,
    this.skipped = 0,
    this.solved = const {},
    this.adventureBest = 0,
  });

  final int score;
  final int skipped;

  /// Maior número de placas resolvidas numa única aventura.
  final int adventureBest;

  /// Placa resolvida ("0427") -> nível em que foi resolvida.
  final Map<String, Level> solved;
}

class RankEntry {
  const RankEntry({
    required this.uid,
    required this.name,
    required this.score,
    required this.solvedCount,
  });
  final String uid;
  final String? name;
  final int score;
  final int solvedCount;
}

/// Acesso aos dados do jogador. A interface permite trocar o Firestore por
/// uma implementação em memória nos testes.
abstract class ProgressRepository {
  Future<UserProgress> fetchProgress();
  Future<void> markSolved(String plate, Level level);
  Future<void> markSkipped(String plate);

  /// Grava o recorde da aventura (o chamador garante que é maior que o atual).
  Future<void> saveAdventureBest(int best);
  Future<List<RankEntry>> fetchRanking({int limit = 10});
}

/// Implementação com Cloud Firestore.
///
/// Estrutura: `users/{uid}` com os campos `name`, `score`, `skipped`,
/// `solvedCount`, `solved` (mapa placa -> nível) e `adventureBest`.
class FirestoreProgressRepository implements ProgressRepository {
  FirestoreProgressRepository(this._db, this._user);

  final FirebaseFirestore _db;
  final AppUser _user;

  static const _timeout = Duration(seconds: 12);

  DocumentReference<Map<String, dynamic>> get _doc =>
      _db.collection('users').doc(_user.uid);

  String? get _publicName {
    final name = _user.displayName?.trim();
    if (name != null && name.isNotEmpty) return name;
    // Sem nome de exibição, usa só a parte local do e-mail.
    return _user.email?.split('@').first;
  }

  @override
  Future<UserProgress> fetchProgress() async {
    final snap = await _doc.get().timeout(_timeout);
    final data = snap.data();
    if (data == null) return const UserProgress();
    final rawSolved = (data['solved'] as Map?) ?? const {};
    return UserProgress(
      score: (data['score'] as num?)?.toInt() ?? 0,
      skipped: (data['skipped'] as num?)?.toInt() ?? 0,
      adventureBest: (data['adventureBest'] as num?)?.toInt() ?? 0,
      solved: {
        for (final e in rawSolved.entries)
          e.key.toString(): Level.fromName(e.value?.toString()),
      },
    );
  }

  @override
  Future<void> markSolved(String plate, Level level) => _doc.set({
        'name': _publicName,
        'score': FieldValue.increment(level.points),
        'solvedCount': FieldValue.increment(1),
        'solved': {plate: level.name},
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)).timeout(_timeout);

  @override
  Future<void> markSkipped(String plate) => _doc.set({
        'name': _publicName,
        'skipped': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)).timeout(_timeout);

  @override
  Future<void> saveAdventureBest(int best) => _doc.set({
        'name': _publicName,
        'adventureBest': best,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)).timeout(_timeout);

  @override
  Future<List<RankEntry>> fetchRanking({int limit = 10}) async {
    final query = await _db
        .collection('users')
        .orderBy('score', descending: true)
        .limit(limit)
        .get()
        .timeout(_timeout);
    return [
      for (final d in query.docs)
        RankEntry(
          uid: d.id,
          name: d.data()['name'] as String?,
          score: (d.data()['score'] as num?)?.toInt() ?? 0,
          solvedCount: (d.data()['solvedCount'] as num?)?.toInt() ?? 0,
        ),
    ];
  }
}

/// Repositório do usuário autenticado (`null` se não houver login).
final progressRepositoryProvider = Provider<ProgressRepository?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  return FirestoreProgressRepository(FirebaseFirestore.instance, user);
});
