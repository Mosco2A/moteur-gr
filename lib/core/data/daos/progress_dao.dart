import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/user_progress_table.dart';

part 'progress_dao.g.dart';

/// DAO pour la progression utilisateur.
///
/// Gere la progression de l'utilisateur sur chaque sentier.
/// Une seule ligne par sentier (upsert).
@DriftAccessor(tables: [UserProgressEntries])
class ProgressDao extends DatabaseAccessor<AppDatabase>
    with _$ProgressDaoMixin {
  ProgressDao(super.db);

  /// Recupere la progression pour un sentier
  Future<UserProgressEntry?> getByTrailId(String trailId) {
    return (select(userProgressEntries)
          ..where((t) => t.trailId.equals(trailId)))
        .getSingleOrNull();
  }

  /// Cree ou met a jour la progression d'un sentier
  Future<void> upsert(UserProgressEntriesCompanion entry) async {
    final trailId = entry.trailId.value;
    final existing = await getByTrailId(trailId);
    if (existing != null) {
      await (update(userProgressEntries)
            ..where((t) => t.trailId.equals(trailId)))
          .write(entry);
    } else {
      await into(userProgressEntries).insert(entry);
    }
  }

  /// Met a jour l'etape courante
  Future<void> updateCurrentStage(String trailId, int stageNumber) async {
    final existing = await getByTrailId(trailId);
    if (existing != null) {
      await (update(userProgressEntries)
            ..where((t) => t.trailId.equals(trailId)))
          .write(
        UserProgressEntriesCompanion(
          currentStage: Value(stageNumber),
        ),
      );
    } else {
      await into(userProgressEntries).insert(
        UserProgressEntriesCompanion.insert(
          trailId: trailId,
          currentStage: Value(stageNumber),
          startedAt: Value(DateTime.now()),
        ),
      );
    }
  }

  /// Marque un sentier comme complete
  Future<void> markCompleted(String trailId) async {
    final existing = await getByTrailId(trailId);
    if (existing != null) {
      await (update(userProgressEntries)
            ..where((t) => t.trailId.equals(trailId)))
          .write(
        UserProgressEntriesCompanion(
          isCompleted: const Value(true),
          completedAt: Value(DateTime.now()),
        ),
      );
    }
  }
}
