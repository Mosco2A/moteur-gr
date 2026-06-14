import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/segments_table.dart';

part 'segments_dao.g.dart';

/// DAO des segments et des efforts offline-first (F7A-01).
///
/// - Segments : cache local des segments publies serveur (lecture offline).
/// - Efforts : ecriture locale immediate (`pending`) puis file de
///   synchronisation differee (pending -> synced/failed). Aucune dependance
///   reseau a l'ecriture : l'insertion fonctionne 100 % hors-ligne.
@DriftAccessor(tables: [Segments, SegmentEffortLocal])
class SegmentsDao extends DatabaseAccessor<AppDatabase>
    with _$SegmentsDaoMixin {
  SegmentsDao(super.db);

  // --- Segments (cache local) ---

  /// Insere ou met a jour un lot de segments (cache local, idempotent).
  Future<void> upsertSegments(List<SegmentsCompanion> entries) async {
    await batch((b) {
      b.insertAllOnConflictUpdate(segments, entries);
    });
  }

  /// Tous les segments d'un sentier (lecture cache offline).
  Future<List<Segment>> segmentsForTrail(String trailId) {
    return (select(segments)..where((t) => t.trailId.equals(trailId))).get();
  }

  /// Un segment par son identifiant (null si absent du cache).
  Future<Segment?> segmentById(String segmentId) {
    return (select(segments)..where((t) => t.id.equals(segmentId)))
        .getSingleOrNull();
  }

  // --- Efforts (file de sync) ---

  /// Insere un nouvel effort (etat 'pending' par defaut). Retourne l'id local.
  Future<int> insertEffort(SegmentEffortLocalCompanion entry) {
    return into(segmentEffortLocal).insert(entry);
  }

  /// Efforts en attente de synchronisation, du plus ancien au plus recent.
  Future<List<SegmentEffortLocalData>> pendingEfforts() {
    return (select(segmentEffortLocal)
          ..where((t) => t.syncState.equals('pending'))
          ..orderBy([(t) => OrderingTerm.asc(t.startedAt)]))
        .get();
  }

  /// Lot borne d'efforts a synchroniser ([limit] max, FIFO).
  Future<List<SegmentEffortLocalData>> dequeueBatch({int limit = 20}) {
    return (select(segmentEffortLocal)
          ..where((t) => t.syncState.equals('pending'))
          ..orderBy([(t) => OrderingTerm.asc(t.startedAt)])
          ..limit(limit))
        .get();
  }

  /// Efforts locaux d'un segment (cache local pour l'affichage), recents d'abord.
  Future<List<SegmentEffortLocalData>> effortsForSegment(String segmentId) {
    return (select(segmentEffortLocal)
          ..where((t) => t.segmentId.equals(segmentId))
          ..orderBy([(t) => OrderingTerm.desc(t.startedAt)]))
        .get();
  }

  /// Marque un effort comme synchronise (avec l'id Firestore distant).
  Future<int> markEffortSynced(int effortId, {String? remoteId}) {
    return (update(segmentEffortLocal)..where((t) => t.id.equals(effortId)))
        .write(
      SegmentEffortLocalCompanion(
        syncState: const Value('synced'),
        remoteId: Value(remoteId),
      ),
    );
  }

  /// Marque un effort en echec et stocke l'erreur (incremente attempts).
  Future<void> markEffortFailed(int effortId, String error) async {
    final row = await (select(segmentEffortLocal)
          ..where((t) => t.id.equals(effortId)))
        .getSingleOrNull();
    if (row == null) return;
    await (update(segmentEffortLocal)..where((t) => t.id.equals(effortId)))
        .write(
      SegmentEffortLocalCompanion(
        syncState: const Value('failed'),
        attempts: Value(row.attempts + 1),
        lastError: Value(error),
      ),
    );
  }

  /// Remet un effort 'failed' en 'pending' pour re-tenter la sync.
  Future<int> requeueEffort(int effortId) {
    return (update(segmentEffortLocal)..where((t) => t.id.equals(effortId)))
        .write(
      const SegmentEffortLocalCompanion(syncState: Value('pending')),
    );
  }

  /// Compte les efforts en attente.
  Future<int> countPendingEfforts() async {
    final pending = await pendingEfforts();
    return pending.length;
  }
}
