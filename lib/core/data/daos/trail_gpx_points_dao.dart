import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/trail_gpx_points_table.dart';

part 'trail_gpx_points_dao.g.dart';

/// DAO pour les points GPX d'une trace.
///
/// Operations CRUD sur la table TrailGpxPoints,
/// avec recuperation ordonnee par sequenceIndex.
@DriftAccessor(tables: [TrailGpxPoints])
class TrailGpxPointsDao extends DatabaseAccessor<AppDatabase>
    with _$TrailGpxPointsDaoMixin {
  TrailGpxPointsDao(super.db);

  /// Recupere tous les points
  Future<List<TrailGpxPoint>> getAll() {
    return select(trailGpxPoints).get();
  }

  /// Recupere un point par son id
  Future<TrailGpxPoint?> getById(int id) {
    return (select(trailGpxPoints)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// Recupere les points d'une trace, ordonnes par sequenceIndex
  Future<List<TrailGpxPoint>> getByTrackId(String trackId) {
    return (select(trailGpxPoints)
          ..where((t) => t.trackId.equals(trackId))
          ..orderBy([(t) => OrderingTerm.asc(t.sequenceIndex)]))
        .get();
  }

  /// Insere ou remplace un point
  Future<int> insertOrReplace(TrailGpxPointsCompanion entry) {
    return into(trailGpxPoints).insert(entry);
  }

  /// Supprime un point par son id
  Future<int> deleteById(int id) {
    return (delete(trailGpxPoints)..where((t) => t.id.equals(id))).go();
  }

  /// Supprime tous les points
  Future<int> deleteAll() {
    return delete(trailGpxPoints).go();
  }
}
