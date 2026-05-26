import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/trail_pois_table.dart';

part 'trail_pois_dao.g.dart';

/// DAO pour les points d'interet par etape.
///
/// Operations CRUD sur la table TrailPois,
/// avec filtres par etape et par type.
@DriftAccessor(tables: [TrailPois])
class TrailPoisDao extends DatabaseAccessor<AppDatabase>
    with _$TrailPoisDaoMixin {
  TrailPoisDao(super.db);

  /// Recupere tous les POI
  Future<List<TrailPoi>> getAll() {
    return select(trailPois).get();
  }

  /// Recupere un POI par son id
  Future<TrailPoi?> getById(String id) {
    return (select(trailPois)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// Recupere les POI d'une etape
  Future<List<TrailPoi>> getByStageId(String stageId) {
    return (select(trailPois)..where((t) => t.stageId.equals(stageId))).get();
  }

  /// Recupere les POI par type
  Future<List<TrailPoi>> getByType(String type) {
    return (select(trailPois)..where((t) => t.type.equals(type))).get();
  }

  /// Insere ou remplace un POI
  Future<void> insertOrReplace(TrailPoisCompanion entry) {
    return into(trailPois).insertOnConflictUpdate(entry);
  }

  /// Supprime un POI par son id
  Future<int> deleteById(String id) {
    return (delete(trailPois)..where((t) => t.id.equals(id))).go();
  }

  /// Supprime tous les POI
  Future<int> deleteAll() {
    return delete(trailPois).go();
  }
}
