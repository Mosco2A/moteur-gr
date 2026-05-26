import 'package:drift/drift.dart';

import 'tables/stages_table.dart';
import 'tables/pois_table.dart';
import 'tables/user_progress_table.dart';
import 'tables/checklist_items_table.dart';
import 'tables/journal_entries_table.dart';
import 'tables/weather_cache_table.dart';
import 'tables/feedback_queue_table.dart';
import 'daos/stages_dao.dart';
import 'daos/pois_dao.dart';
import 'daos/progress_dao.dart';
import 'daos/checklist_dao.dart';
import 'daos/journal_dao.dart';
import 'daos/weather_cache_dao.dart';
import 'daos/feedback_queue_dao.dart';

part 'database.g.dart';

/// Base de données locale du Moteur GR.
///
/// 7 tables : Stages, Pois, UserProgressEntries, ChecklistItems,
/// JournalEntries (journal trek v3), WeatherCache (météo v5),
/// FeedbackQueue (feedback offline v6).
/// Utilise Drift (ex-moor) pour le mapping SQLite.
@DriftDatabase(
  tables: [
    Stages,
    Pois,
    UserProgressEntries,
    ChecklistItems,
    JournalEntries,
    WeatherCache,
    FeedbackQueue,
  ],
  daos: [
    StagesDao,
    PoisDao,
    ProgressDao,
    ChecklistDao,
    JournalDao,
    WeatherCacheDao,
    FeedbackQueueDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 6;

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
          // Migration v2 -> v3 : création table journal_entries (E3.1)
          if (from < 3) {
            await migrator.createTable(journalEntries);
          }
          // Migration v3 -> v4 : création table checklist_items (E3.2)
          if (from < 4) {
            await migrator.createTable(checklistItems);
          }
          // Migration v4 -> v5 : création table weather_cache (E3.5a)
          if (from < 5) {
            await migrator.createTable(weatherCache);
          }
          // Migration v5 -> v6 : création table feedback_queue (E3.10)
          if (from < 6) {
            await migrator.createTable(feedbackQueue);
          }
        },
      );
}
