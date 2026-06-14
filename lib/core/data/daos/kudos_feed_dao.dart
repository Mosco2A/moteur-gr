import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/kudos_feed_table.dart';

part 'kudos_feed_dao.g.dart';

/// DAO des kudos et du fil d'activite offline-first (F7B-01).
///
/// - Kudos : ecriture locale immediate (`pending`) puis file de sync differee.
/// - Fil : cache local lu hors-ligne (visibleActivities masque les 'removed').
@DriftAccessor(tables: [KudosLocal, ActivityFeedCache])
class KudosFeedDao extends DatabaseAccessor<AppDatabase>
    with _$KudosFeedDaoMixin {
  KudosFeedDao(super.db);

  // --- Kudos (file de sync) ---

  /// Ajoute un kudo EN LOCAL (etat 'pending'). Retourne l'id local.
  Future<int> addKudoLocal(KudosLocalCompanion entry) {
    return into(kudosLocal).insert(entry);
  }

  /// Kudos en attente de synchronisation, du plus ancien au plus recent.
  Future<List<KudosLocalData>> pendingKudos() {
    return (select(kudosLocal)
          ..where((t) => t.syncState.equals('pending'))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  /// Marque un kudo comme synchronise.
  Future<int> markKudoSynced(int kudoId) {
    return (update(kudosLocal)..where((t) => t.id.equals(kudoId))).write(
      const KudosLocalCompanion(syncState: Value('synced')),
    );
  }

  /// Marque un kudo en echec et stocke l'erreur (incremente attempts).
  Future<void> markKudoFailed(int kudoId, String error) async {
    final row = await (select(kudosLocal)..where((t) => t.id.equals(kudoId)))
        .getSingleOrNull();
    if (row == null) return;
    await (update(kudosLocal)..where((t) => t.id.equals(kudoId))).write(
      KudosLocalCompanion(
        syncState: const Value('failed'),
        attempts: Value(row.attempts + 1),
        lastError: Value(error),
      ),
    );
  }

  /// Remet un kudo 'failed' en 'pending' pour re-tenter la sync.
  Future<int> requeueKudo(int kudoId) {
    return (update(kudosLocal)..where((t) => t.id.equals(kudoId))).write(
      const KudosLocalCompanion(syncState: Value('pending')),
    );
  }

  /// Existe-t-il deja un kudo local de [fromUidHash] sur [targetActivityId] ?
  /// (Garde-fou d'idempotence cote cache, complementaire de la cle distante.)
  Future<bool> hasKudoLocal(String fromUidHash, String targetActivityId) async {
    final row = await (select(kudosLocal)
          ..where((t) =>
              t.fromUidHash.equals(fromUidHash) &
              t.targetActivityId.equals(targetActivityId)))
        .getSingleOrNull();
    return row != null;
  }

  /// Compte les kudos locaux d'une activite (compteur affiche, cache).
  Future<int> kudosCountForActivity(String targetActivityId) async {
    final rows = await (select(kudosLocal)
          ..where((t) => t.targetActivityId.equals(targetActivityId)))
        .get();
    return rows.length;
  }

  // --- Fil d'activite (cache local) ---

  /// Insere ou met a jour un lot d'activites (cache local, idempotent).
  Future<void> upsertActivities(List<ActivityFeedCacheCompanion> entries) async {
    await batch((b) {
      b.insertAllOnConflictUpdate(activityFeedCache, entries);
    });
  }

  /// Activites VISIBLES (moderationState != 'removed'), recentes d'abord.
  /// Lecture offline-first (R2).
  Future<List<ActivityFeedCacheData>> visibleActivities() {
    return (select(activityFeedCache)
          ..where((t) => t.moderationState.equals('removed').not())
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  /// Met a jour l'etat de moderation d'une activite en cache (reflet du
  /// statut serveur a la sync). Le client n'est PAS moderateur : cette ecriture
  /// cache ne fait que refleter une decision serveur (F7B-03).
  Future<int> setModerationState(String activityId, String state) {
    return (update(activityFeedCache)..where((t) => t.id.equals(activityId)))
        .write(ActivityFeedCacheCompanion(moderationState: Value(state)));
  }
}
