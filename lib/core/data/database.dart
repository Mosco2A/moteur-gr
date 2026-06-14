import 'package:drift/drift.dart';

import 'tables/stages_table.dart';
import 'tables/pois_table.dart';
import 'tables/user_progress_table.dart';
import 'tables/checklist_items_table.dart';
import 'tables/journal_entries_table.dart';
import 'tables/weather_cache_table.dart';
import 'tables/feedback_queue_table.dart';
import 'tables/trail_meta_table.dart';
import 'tables/trail_itineraries_table.dart';
import 'tables/trail_stages_table.dart';
import 'tables/trail_accommodations_table.dart';
import 'tables/trail_pois_table.dart';
import 'tables/trail_gpx_tracks_table.dart';
import 'tables/trail_gpx_points_table.dart';
import 'tables/trail_manifests_table.dart';
import 'tables/sync_queue_table.dart';
import 'tables/review_requests_table.dart';
import 'tables/health_info_table.dart';
import 'tables/follow_sessions_table.dart';
import 'tables/follower_slots_table.dart';
import 'tables/session_track_points_table.dart';
import 'tables/report_local_table.dart';
import 'tables/segments_table.dart';
import 'daos/stages_dao.dart';
import 'daos/pois_dao.dart';
import 'daos/progress_dao.dart';
import 'daos/checklist_dao.dart';
import 'daos/journal_dao.dart';
import 'daos/weather_cache_dao.dart';
import 'daos/feedback_queue_dao.dart';
import 'daos/trail_meta_dao.dart';
import 'daos/trail_itineraries_dao.dart';
import 'daos/trail_stages_dao.dart';
import 'daos/trail_accommodations_dao.dart';
import 'daos/trail_pois_dao.dart';
import 'daos/trail_gpx_tracks_dao.dart';
import 'daos/trail_gpx_points_dao.dart';
import 'daos/trail_manifests_dao.dart';
import 'daos/sync_queue_dao.dart';
import 'daos/review_requests_dao.dart';
import 'daos/health_info_dao.dart';
import 'daos/follow_sessions_dao.dart';
import 'daos/follower_slots_dao.dart';
import 'daos/session_track_points_dao.dart';
import 'daos/report_local_dao.dart';
import 'daos/segments_dao.dart';

part 'database.g.dart';

/// Base de donnees locale du Moteur GR.
///
/// 17 tables : 7 existantes (Stages, Pois, UserProgressEntries,
/// ChecklistItems, JournalEntries, WeatherCache, FeedbackQueue)
/// + 7 Phase 4 (TrailMeta, TrailItineraries, TrailStages,
/// TrailAccommodations, TrailPois, TrailGpxTracks, TrailGpxPoints)
/// + 1 Phase 4 E4.3 (TrailManifests)
/// + 1 Phase 4 E4.4 (SyncQueue)
/// + 1 Phase 5 E5.17 (ReviewRequests)
/// + 1 Phase 5 E5.16 (HealthInfoEntries)
/// + 2 Phase 4 E4.10 (FollowSessions, FollowerSlots)
/// + 1 finitions V8 F3 (SessionTrackPoints)
/// + 1 Phase 6 F6C-01 (ReportLocal, signalements offline-first)
/// + 2 Phase 7 F7A-01 (Segments, SegmentEffortLocal, social offline-first).
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
    TrailMeta,
    TrailItineraries,
    TrailStages,
    TrailAccommodations,
    TrailPois,
    TrailGpxTracks,
    TrailGpxPoints,
    TrailManifests,
    SyncQueue,
    ReviewRequests,
    HealthInfoEntries,
    FollowSessions,
    FollowerSlots,
    SessionTrackPoints,
    ReportLocal,
    Segments,
    SegmentEffortLocal,
  ],
  daos: [
    StagesDao,
    PoisDao,
    ProgressDao,
    ChecklistDao,
    JournalDao,
    WeatherCacheDao,
    FeedbackQueueDao,
    TrailMetaDao,
    TrailItinerariesDao,
    TrailStagesDao,
    TrailAccommodationsDao,
    TrailPoisDao,
    TrailGpxTracksDao,
    TrailGpxPointsDao,
    TrailManifestsDao,
    SyncQueueDao,
    ReviewRequestsDao,
    HealthInfoDao,
    FollowSessionsDao,
    FollowerSlotsDao,
    SessionTrackPointsDao,
    ReportLocalDao,
    SegmentsDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 15;

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
          // Migration v2 -> v3 : creation table journal_entries (E3.1)
          if (from < 3) {
            await migrator.createTable(journalEntries);
          }
          // Migration v3 -> v4 : creation table checklist_items (E3.2)
          if (from < 4) {
            await migrator.createTable(checklistItems);
          }
          // Migration v4 -> v5 : creation table weather_cache (E3.5a)
          if (from < 5) {
            await migrator.createTable(weatherCache);
          }
          // Migration v5 -> v6 : creation table feedback_queue (E3.10)
          if (from < 6) {
            await migrator.createTable(feedbackQueue);
          }
          // Migration v6 -> v7 : 7 tables donnees sentier (Phase 4 E4.2)
          if (from < 7) {
            await migrator.createTable(trailMeta);
            await migrator.createTable(trailItineraries);
            await migrator.createTable(trailStages);
            await migrator.createTable(trailAccommodations);
            await migrator.createTable(trailPois);
            await migrator.createTable(trailGpxTracks);
            await migrator.createTable(trailGpxPoints);
          }
          // Migration v7 -> v8 : table manifeste sentier (Phase 4 E4.3)
          if (from < 8) {
            await migrator.createTable(trailManifests);
          }
          // Migration v8 -> v9 : table sync_queue (Phase 4 E4.4)
          if (from < 9) {
            await migrator.createTable(syncQueue);
          }
          // Migration v9 -> v10 : table review_requests (Phase 5 E5.17)
          if (from < 10) {
            await migrator.createTable(reviewRequests);
          }
          // Migration v10 -> v11 : table health_info (Phase 5 E5.16)
          if (from < 11) {
            await migrator.createTable(healthInfoEntries);
          }
          // Migration v11 -> v12 : tables suivi trekkeur (Phase 4 E4.10)
          if (from < 12) {
            await migrator.createTable(followSessions);
            await migrator.createTable(followerSlots);
          }
          // Migration v12 -> v13 : table session_track_points
          // (trace GPS reelle du recap diplome, finitions V8 F3)
          if (from < 13) {
            await migrator.createTable(sessionTrackPoints);
          }
          // Migration v13 -> v14 : table report_local
          // (signalements terrain offline-first, Phase 6 F6C-01)
          if (from < 14) {
            await migrator.createTable(reportLocal);
          }
          // Migration v14 -> v15 : tables segments + efforts (Phase 7 F7A-01)
          // (segments comparables + file d'efforts offline-first)
          if (from < 15) {
            await migrator.createTable(segments);
            await migrator.createTable(segmentEffortLocal);
          }
        },
      );
}
