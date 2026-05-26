import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/pois_table.dart';

part 'pois_dao.g.dart';

/// DAO pour les operations sur les points d'interet.
///
/// Fournit les methodes CRUD pour la table Pois,
/// filtrees par sentier et/ou etape.
@DriftAccessor(tables: [Pois])
class PoisDao extends DatabaseAccessor<AppDatabase> with _$PoisDaoMixin {
  PoisDao(super.db);

  /// Recupere tous les POI d'un sentier
  Future<List<Poi>> getByTrailId(String trailId) {
    return (select(pois)..where((t) => t.trailId.equals(trailId))).get();
  }

  /// Recupere les POI d'une etape specifique
  Future<List<Poi>> getByStage(String trailId, int stageNumber) {
    return (select(pois)
          ..where(
            (t) =>
                t.trailId.equals(trailId) &
                t.stageNumber.equals(stageNumber),
          ))
        .get();
  }

  /// Insere une liste de POI en batch
  Future<void> insertAll(List<PoisCompanion> entries) async {
    await batch((b) => b.insertAll(pois, entries));
  }

  /// Supprime tous les POI d'un sentier
  Future<int> deleteByTrailId(String trailId) {
    return (delete(pois)..where((t) => t.trailId.equals(trailId))).go();
  }
}
