import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/waypoints_table.dart';

part 'waypoints_dao.g.dart';

/// DAO des waypoints et commentaires offline-first (F8A-01, Phase 8).
///
/// - Waypoints : cache local des points terrain (lecture offline, filtre type).
/// - Commentaires : ecriture locale immediate (`pending`) puis file de
///   synchronisation differee. Aucune dependance reseau a l'ecriture :
///   l'insertion fonctionne 100 % hors-ligne. visibleComments masque les
///   commentaires 'removed' (DSA art. 16).
@DriftAccessor(tables: [Waypoint, WaypointComment])
class WaypointsDao extends DatabaseAccessor<AppDatabase>
    with _$WaypointsDaoMixin {
  WaypointsDao(super.db);

  // --- Waypoints (cache local) ---

  /// Insere ou met a jour un lot de waypoints (cache local, idempotent).
  Future<void> upsertWaypoints(List<WaypointCompanion> entries) async {
    await batch((b) {
      b.insertAllOnConflictUpdate(waypoint, entries);
    });
  }

  /// Waypoints d'un type donne (lecture cache offline), par titre.
  Future<List<WaypointData>> waypointsByType(String type) {
    return (select(waypoint)
          ..where((t) => t.type.equals(type))
          ..orderBy([(t) => OrderingTerm.asc(t.titre)]))
        .get();
  }

  /// Tous les waypoints d'un sentier (lecture cache offline).
  Future<List<WaypointData>> waypointsForTrail(String trailId) {
    return (select(waypoint)..where((t) => t.trailId.equals(trailId))).get();
  }

  /// Un waypoint par son identifiant (null si absent du cache).
  Future<WaypointData?> waypointById(String waypointId) {
    return (select(waypoint)..where((t) => t.id.equals(waypointId)))
        .getSingleOrNull();
  }

  // --- Commentaires (file de sync) ---

  /// Ajoute un commentaire EN LOCAL (etat 'pending'). Retourne l'id local.
  Future<int> addCommentLocal(WaypointCommentCompanion entry) {
    return into(waypointComment).insert(entry);
  }

  /// Commentaires en attente de synchronisation, du plus ancien au plus recent.
  Future<List<WaypointCommentData>> pendingComments() {
    return (select(waypointComment)
          ..where((t) => t.syncState.equals('pending'))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  /// Commentaires VISIBLES (moderationState != 'removed') d'un waypoint,
  /// recents d'abord. Lecture offline-first.
  Future<List<WaypointCommentData>> visibleComments(String waypointId) {
    return (select(waypointComment)
          ..where((t) =>
              t.waypointId.equals(waypointId) &
              t.moderationState.equals('removed').not())
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  /// Marque un commentaire comme synchronise.
  Future<int> markCommentSynced(int commentId) {
    return (update(waypointComment)..where((t) => t.id.equals(commentId)))
        .write(const WaypointCommentCompanion(syncState: Value('synced')));
  }

  /// Marque un commentaire en echec (stocke l'etat 'failed').
  Future<int> markCommentFailed(int commentId) {
    return (update(waypointComment)..where((t) => t.id.equals(commentId)))
        .write(const WaypointCommentCompanion(syncState: Value('failed')));
  }

  /// Remet un commentaire 'failed' en 'pending' pour re-tenter la sync.
  Future<int> requeueComment(int commentId) {
    return (update(waypointComment)..where((t) => t.id.equals(commentId)))
        .write(const WaypointCommentCompanion(syncState: Value('pending')));
  }

  /// Met a jour l'etat de moderation d'un commentaire en cache (reflet du
  /// statut serveur a la sync). Le client n'est PAS moderateur : cette ecriture
  /// ne fait que refleter une decision serveur (DSA D4).
  Future<int> setCommentModerationState(int commentId, String state) {
    return (update(waypointComment)..where((t) => t.id.equals(commentId)))
        .write(WaypointCommentCompanion(moderationState: Value(state)));
  }
}
