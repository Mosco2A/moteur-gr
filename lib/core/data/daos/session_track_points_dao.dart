import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/session_track_points_table.dart';

part 'session_track_points_dao.g.dart';

/// DAO du tracé GPS de session — finitions V8 F3.
///
/// Le tracé de la DERNIÈRE session de tracking d'un sentier est
/// conservé : une nouvelle session remplace la précédente
/// ([clearTrail] au start). Les points sont insérés au fil de l'eau
/// pendant l'enregistrement (robuste à un arrêt brutal de l'app).
@DriftAccessor(tables: [SessionTrackPoints])
class SessionTrackPointsDao extends DatabaseAccessor<AppDatabase>
    with _$SessionTrackPointsDaoMixin {
  SessionTrackPointsDao(super.db);

  /// Efface le tracé existant du sentier (début de nouvelle session).
  Future<void> clearTrail(String trailId) async {
    await (delete(sessionTrackPoints)
          ..where((t) => t.trailId.equals(trailId)))
        .go();
  }

  /// Insère un point GPS du tracé en cours d'enregistrement.
  Future<void> insertPoint({
    required String trailId,
    required double lat,
    required double lng,
    required double altitude,
    DateTime? recordedAt,
  }) async {
    await into(sessionTrackPoints).insert(
      SessionTrackPointsCompanion.insert(
        trailId: trailId,
        lat: lat,
        lng: lng,
        altitude: altitude,
        recordedAt: recordedAt ?? DateTime.now(),
      ),
    );
  }

  /// Tracé complet du sentier, dans l'ordre d'enregistrement.
  Future<List<SessionTrackPoint>> getByTrailId(String trailId) async {
    final query = select(sessionTrackPoints)
      ..where((t) => t.trailId.equals(trailId))
      ..orderBy([(t) => OrderingTerm.asc(t.id)]);
    return query.get();
  }
}
