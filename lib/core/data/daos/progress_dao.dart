/// Une seule ligne par sentier : l'etape ou en est le marcheur et son
/// achevement, tenues a jour par upsert.
library;

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
    return (select(
      userProgressEntries,
    )..where((t) => t.trailId.equals(trailId))).getSingleOrNull();
  }

  /// TOUTES les progressions connues, un sentier par ligne (tache 635).
  ///
  /// POURQUOI ELLE MANQUAIT, ET POURQUOI IL LA FAUT. La montee en base doit
  /// pousser la progression de CHAQUE sentier commence, pas seulement celui qui
  /// est affiche : un randonneur qui a prepare deux sentiers et regarde le
  /// second ne doit pas voir le premier disparaitre du serveur. Il n existait
  /// aucun moyen de demander « quels sentiers ce telephone connait-il ? » — on
  /// ne savait interroger qu un sentier dont on avait deja le nom.
  Future<List<UserProgressEntry>> getAll() {
    return select(userProgressEntries).get();
  }

  /// Cree ou met a jour la progression d'un sentier
  Future<void> upsert(UserProgressEntriesCompanion entry) async {
    final trailId = entry.trailId.value;
    final existing = await getByTrailId(trailId);
    if (existing != null) {
      await (update(
        userProgressEntries,
      )..where((t) => t.trailId.equals(trailId))).write(entry);
    } else {
      await into(userProgressEntries).insert(entry);
    }
  }

  /// Met a jour l'etape courante
  Future<void> updateCurrentStage(String trailId, int stageNumber) async {
    final existing = await getByTrailId(trailId);
    if (existing != null) {
      await (update(
        userProgressEntries,
      )..where((t) => t.trailId.equals(trailId))).write(
        UserProgressEntriesCompanion(currentStage: Value(stageNumber)),
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
      await (update(
        userProgressEntries,
      )..where((t) => t.trailId.equals(trailId))).write(
        UserProgressEntriesCompanion(
          isCompleted: const Value(true),
          completedAt: Value(DateTime.now()),
        ),
      );
    }
  }
}
