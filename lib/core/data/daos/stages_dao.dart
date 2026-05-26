import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/stages_table.dart';

part 'stages_dao.g.dart';

/// DAO pour les operations sur les etapes.
///
/// Fournit les methodes CRUD pour la table Stages,
/// filtrees par sentier et/ou numero d'etape.
@DriftAccessor(tables: [Stages])
class StagesDao extends DatabaseAccessor<AppDatabase> with _$StagesDaoMixin {
  StagesDao(super.db);

  /// Recupere toutes les etapes d'un sentier, triees par numero
  Future<List<Stage>> getByTrailId(String trailId) {
    return (select(stages)
          ..where((t) => t.trailId.equals(trailId))
          ..orderBy([(t) => OrderingTerm.asc(t.stageNumber)]))
        .get();
  }

  /// Recupere une etape par sentier et numero
  Future<Stage?> getByStageNumber(String trailId, int stageNumber) {
    return (select(stages)
          ..where(
            (t) =>
                t.trailId.equals(trailId) &
                t.stageNumber.equals(stageNumber),
          ))
        .getSingleOrNull();
  }

  /// Insere une liste d'etapes en batch
  Future<void> insertAll(List<StagesCompanion> entries) async {
    await batch((b) => b.insertAll(stages, entries));
  }

  /// Supprime toutes les etapes d'un sentier
  Future<int> deleteByTrailId(String trailId) {
    return (delete(stages)..where((t) => t.trailId.equals(trailId))).go();
  }
}
