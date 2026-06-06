import '../../../core/config/trail_config.dart';
import '../../../core/data/daos/stages_dao.dart';
import '../../../core/data/daos/trail_accommodations_dao.dart';
import '../../../core/data/daos/trail_gpx_points_dao.dart';
import '../../../core/data/daos/trail_itineraries_dao.dart';
import '../../../core/data/daos/trail_stages_dao.dart';
import '../../../core/data/database.dart';
import '../../../core/geo/geo_utils.dart';
import '../../../core/geo/track_point.dart';
import '../../../core/models/stage.dart';
import '../domain/models/stage_accommodation.dart';
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
  Future<List<StageAccommodation>> getAccommodations(
    String trailId, {
    int? stageNumber,
  }) async {
    final itinerariesDao = TrailItinerariesDao(_db);
    final stagesDao = TrailStagesDao(_db);
    final accommodationsDao = TrailAccommodationsDao(_db);

    // 1. Itineraires du sentier
    final itineraries = await itinerariesDao.getByTrailId(trailId);

    // 2. Etapes (optionnellement filtrees par numero)
    final stages = <TrailStage>[];
    for (final itinerary in itineraries) {
      final itineraryStages =
          await stagesDao.getByItineraryId(itinerary.id);
      stages.addAll(
        stageNumber == null
            ? itineraryStages
            : itineraryStages.where((s) => s.stageNumber == stageNumber),
      );
    }

    // 3. Hebergements de chaque etape
    final result = <StageAccommodation>[];
    for (final stage in stages) {
      final rows = await accommodationsDao.getByStageId(stage.id);
      result.addAll(rows.map((row) => StageAccommodation(
            id: row.id,
            stageId: row.stageId,
            stageNumber: stage.stageNumber,
            nameFr: row.nameFr,
            nameEn: row.nameEn,
            type: AccommodationType.fromDb(row.type),
            lat: row.lat,
            lng: row.lng,
            phone: row.phone,
            email: row.email,
            website: row.website,
            capacity: row.capacity,
            priceRange: row.priceRange,
            bookingUrl: row.bookingUrl,
          )));
    }
    return result;
  }

  @override
  TrailConfig getTrailConfig() => _trailConfig;
}
