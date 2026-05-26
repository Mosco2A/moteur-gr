import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/sync_queue_table.dart';

part 'sync_queue_dao.g.dart';

/// DAO pour la file de synchronisation du telechargement avec reprise.
///
/// Gere le suivi des actions de telechargement par table
/// pour permettre la reprise apres coupure reseau.
@DriftAccessor(tables: [SyncQueue])
class SyncQueueDao extends DatabaseAccessor<AppDatabase>
    with _$SyncQueueDaoMixin {
  SyncQueueDao(super.db);

  /// Recupere toutes les actions en attente, triees par date de creation
  Future<List<SyncQueueData>> getPending() {
    return (select(syncQueue)
          ..where((t) => t.status.equals('pending'))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  /// Recupere toutes les actions d'un sentier, triees par date
  Future<List<SyncQueueData>> getByTrailId(String trailId) {
    return (select(syncQueue)
          ..where((t) => t.trailId.equals(trailId))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  /// Insere ou remplace une action dans la file
  Future<int> insertOrReplace(SyncQueueCompanion entry) {
    return into(syncQueue).insert(
      entry,
      mode: InsertMode.insertOrReplace,
    );
  }

  /// Marque une action comme terminee
  Future<int> markCompleted(int actionId) {
    return (update(syncQueue)..where((t) => t.id.equals(actionId)))
        .write(SyncQueueCompanion(
      status: const Value('completed'),
      completedAt: Value(DateTime.now().toIso8601String()),
    ));
  }

  /// Marque une action comme echouee
  Future<int> markFailed(int actionId, String error) {
    return (update(syncQueue)..where((t) => t.id.equals(actionId)))
        .write(SyncQueueCompanion(
      status: const Value('failed'),
      payload: Value(error),
    ));
  }

  /// Incremente le compteur de tentatives d'une action
  Future<void> incrementRetry(int actionId) async {
    final entry = await (select(syncQueue)
          ..where((t) => t.id.equals(actionId)))
        .getSingleOrNull();
    if (entry == null) return;

    await (update(syncQueue)..where((t) => t.id.equals(actionId)))
        .write(SyncQueueCompanion(
      retryCount: Value(entry.retryCount + 1),
    ));
  }

  /// Supprime les actions completees plus anciennes que N jours
  Future<int> cleanOldCompleted(int olderThanDays) {
    final cutoff = DateTime.now()
        .subtract(Duration(days: olderThanDays))
        .toIso8601String();
    return (delete(syncQueue)
          ..where((t) =>
              t.status.equals('completed') &
              t.completedAt.isSmallerOrEqualValue(cutoff)))
        .go();
  }

  /// Supprime toutes les actions d'un sentier
  Future<int> deleteByTrailId(String trailId) {
    return (delete(syncQueue)
          ..where((t) => t.trailId.equals(trailId)))
        .go();
  }
}
