import 'package:drift/drift.dart';

import 'tables/stages_table.dart';
import 'tables/pois_table.dart';
import 'tables/user_progress_table.dart';
import 'tables/checklist_items_table.dart';
import 'daos/stages_dao.dart';
import 'daos/pois_dao.dart';
import 'daos/progress_dao.dart';
import 'daos/checklist_dao.dart';

part 'database.g.dart';

/// Base de donnees locale du Moteur GR.
///
/// 4 tables : Stages (etapes), Pois (points d'interet),
/// UserProgressEntries (progression utilisateur),
/// ChecklistItems (checklist materiel).
/// Utilise Drift (ex-moor) pour le mapping SQLite.
@DriftDatabase(
  tables: [Stages, Pois, UserProgressEntries, ChecklistItems],
  daos: [StagesDao, PoisDao, ProgressDao, ChecklistDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (migrator, from, to) async {
          // Migration v1 -> v2 : ajout colonne totalTimeMinutes
          if (from < 2) {
            await migrator.addColumn(
              userProgressEntries,
              userProgressEntries.totalTimeMinutes,
            );
          }
          // Migration v2 -> v4 : creation table checklist_items
          // (v3 reservee pour journal_entries, ajoutee en E3.1)
          if (from < 4) {
            await migrator.createTable(checklistItems);
          }
        },
      );
}
