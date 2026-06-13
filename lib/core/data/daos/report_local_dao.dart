import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/report_local_table.dart';

part 'report_local_dao.g.dart';

/// DAO des signalements terrain offline-first (F6C-01).
///
/// Gere l'ecriture locale immediate des signalements et leur file de
/// synchronisation differee (pending -> synced/failed). Aucune dependance
/// reseau : l'insertion fonctionne 100 % hors-ligne.
@DriftAccessor(tables: [ReportLocal])
class ReportLocalDao extends DatabaseAccessor<AppDatabase>
    with _$ReportLocalDaoMixin {
  ReportLocalDao(super.db);

  /// Insere un nouveau signalement (etat 'pending' par defaut). Retourne l'id.
  Future<int> insertReport(ReportLocalCompanion entry) {
    return into(reportLocal).insert(entry);
  }

  /// Signalements en attente de synchronisation, du plus ancien au plus recent.
  Future<List<ReportLocalData>> pendingReports() {
    return (select(reportLocal)
          ..where((t) => t.syncState.equals('pending'))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  /// Lot borne de signalements a synchroniser ([limit] max, FIFO).
  Future<List<ReportLocalData>> dequeueBatch({int limit = 20}) {
    return (select(reportLocal)
          ..where((t) => t.syncState.equals('pending'))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)])
          ..limit(limit))
        .get();
  }

  /// Tous les signalements (cache local pour la lecture), recents d'abord.
  Future<List<ReportLocalData>> allReports() {
    return (select(reportLocal)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  /// Marque un signalement comme synchronise (avec l'id Firestore distant).
  Future<int> markSynced(int reportId, {String? remoteId}) {
    return (update(reportLocal)..where((t) => t.id.equals(reportId))).write(
      ReportLocalCompanion(
        syncState: const Value('synced'),
        remoteId: Value(remoteId),
      ),
    );
  }

  /// Marque un signalement en echec et stocke l'erreur (incremente attempts).
  Future<void> markFailed(int reportId, String error) async {
    final row = await (select(reportLocal)
          ..where((t) => t.id.equals(reportId)))
        .getSingleOrNull();
    if (row == null) return;
    await (update(reportLocal)..where((t) => t.id.equals(reportId))).write(
      ReportLocalCompanion(
        syncState: const Value('failed'),
        attempts: Value(row.attempts + 1),
        lastError: Value(error),
      ),
    );
  }

  /// Remet un signalement 'failed' en 'pending' pour re-tenter la sync.
  Future<int> requeue(int reportId) {
    return (update(reportLocal)..where((t) => t.id.equals(reportId))).write(
      const ReportLocalCompanion(syncState: Value('pending')),
    );
  }

  /// Compte les signalements en attente.
  Future<int> countPending() async {
    final pending = await pendingReports();
    return pending.length;
  }

  /// Supprime les signalements synchronises (nettoyage du cache local).
  Future<int> deleteSynced() {
    return (delete(reportLocal)..where((t) => t.syncState.equals('synced')))
        .go();
  }
}
