import '../../../core/config/trail_config.dart';
import '../../../core/data/daos/stages_dao.dart';
import '../../../core/data/daos/trail_gpx_points_dao.dart';
import '../../../core/data/database.dart';
import '../../../core/geo/geo_utils.dart';
import '../../../core/geo/track_point.dart';
import '../../../core/models/stage.dart';
import '../domain/trail_data_provider.dart';

/// Implementation Drift de TrailDataProvider.
///
/// Wrappe les DAO existants (StagesDao, TrailGpxPointsDao)
/// pour fournir l'acces aux donnees via l'interface abstraite.
class DriftTrailDataProvider implements TrailDataProvider {
  DriftTrailDataProvider({
    required AppDatabase db,
    required TrailConfig trailConfig,
  })  : _db = db,
        _trailConfig = trailConfig;

  final AppDatabase _db;
  final TrailConfig _trailConfig;

  @override
  Future<List<StageModel>> getStages(String trailId) async {
    final dao = StagesDao(_db);
    final rows = await dao.getByTrailId(trailId);
    return rows.map(StageModel.fromDb).toList();
  }

  @override
  Future<List<TrackPoint>> getTrackPoints(String stageId) async {
    final dao = TrailGpxPointsDao(_db);
    final rows = await dao.getByTrackId(stageId);

    final points = <TrackPoint>[];
    var cumulativeDistance = 0.0;

    for (final row in rows) {
      if (points.isNotEmpty) {
        final prev = points.last;
        cumulativeDistance += GeoUtils.haversineDistance(
          prev.lat, prev.lng, row.lat, row.lng,
        );
      }

      points.add(TrackPoint(
        lat: row.lat,
        lng: row.lng,
        altitude: row.elevation,
        distanceFromStart: cumulativeDistance,
      ));
    }

    return points;
  }

  @override
  TrailConfig getTrailConfig() => _trailConfig;
}
