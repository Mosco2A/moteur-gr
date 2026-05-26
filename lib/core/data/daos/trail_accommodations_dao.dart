import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/trail_accommodations_table.dart';

part 'trail_accommodations_dao.g.dart';

/// DAO pour les hebergements par etape.
///
/// Operations CRUD sur la table TrailAccommodations,
/// avec filtre par etape.
@DriftAccessor(tables: [TrailAccommodations])
class TrailAccommodationsDao extends DatabaseAccessor<AppDatabase>
    with _$TrailAccommodationsDaoMixin {
  TrailAccommodationsDao(super.db);

  /// Recupere tous les hebergements
  Future<List<TrailAccommodation>> getAll() {
    return select(trailAccommodations).get();
  }

  /// Recupere un hebergement par son id
  Future<TrailAccommodation?> getById(String id) {
    return (select(trailAccommodations)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// Recupere les hebergements d'une etape
  Future<List<TrailAccommodation>> getByStageId(String stageId) {
    return (select(trailAccommodations)
          ..where((t) => t.stageId.equals(stageId)))
        .get();
  }

  /// Insere ou remplace un hebergement
  Future<void> insertOrReplace(TrailAccommodationsCompanion entry) {
    return into(trailAccommodations).insertOnConflictUpdate(entry);
  }

  /// Supprime un hebergement par son id
  Future<int> deleteById(String id) {
    return (delete(trailAccommodations)..where((t) => t.id.equals(id))).go();
  }

  /// Supprime tous les hebergements
  Future<int> deleteAll() {
    return delete(trailAccommodations).go();
  }
}
