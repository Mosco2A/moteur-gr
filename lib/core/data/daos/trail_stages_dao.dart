import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/trail_stages_table.dart';

part 'trail_stages_dao.g.dart';

/// DAO pour les etapes d'itineraire.
///
/// Operations CRUD sur la table TrailStages,
/// avec filtre par itineraire.
@DriftAccessor(tables: [TrailStages])
class TrailStagesDao extends DatabaseAccessor<AppDatabase>
    with _$TrailStagesDaoMixin {
  TrailStagesDao(super.db);

  /// Recupere toutes les etapes
  Future<List<TrailStage>> getAll() {
    return select(trailStages).get();
  }

  /// Recupere une etape par son id
  Future<TrailStage?> getById(String id) {
    return (select(trailStages)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// Recupere les etapes d'un itineraire, triees par numero
  Future<List<TrailStage>> getByItineraryId(String itineraryId) {
    return (select(trailStages)
          ..where((t) => t.itineraryId.equals(itineraryId))
          ..orderBy([(t) => OrderingTerm.asc(t.stageNumber)]))
        .get();
  }

  /// Insere ou remplace une etape
  Future<void> insertOrReplace(TrailStagesCompanion entry) {
    return into(trailStages).insertOnConflictUpdate(entry);
  }

  /// Supprime une etape par son id
  Future<int> deleteById(String id) {
    return (delete(trailStages)..where((t) => t.id.equals(id))).go();
  }

  /// Supprime toutes les etapes
  Future<int> deleteAll() {
    return delete(trailStages).go();
  }
}
