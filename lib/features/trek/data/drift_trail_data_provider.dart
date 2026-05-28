import '../../../core/config/trail_config.dart';
import '../../../core/data/database.dart';
import '../../../core/data/daos/stages_dao.dart';
import '../domain/models/stage.dart' as trek;
import '../domain/models/track_point.dart' as trek;
import '../domain/trail_data_provider.dart';

/// Implementation Drift de [TrailDataProvider].
///
/// Charge les etapes et la configuration depuis la base SQLite locale
/// via les DAOs Drift existants. Les TrackPoints ne sont pas encore
/// stockes en Drift (ils viennent du parsing GPX) — cette implementation
/// retourne une liste vide en attendant la table dediee.
class DriftTrailDataProvider implements TrailDataProvider {
  DriftTrailDataProvider({
    required AppDatabase db,
    required TrailConfig trailConfig,
  })  : _db = db,
        _trailConfig = trailConfig;

  final AppDatabase _db;
  final TrailConfig _trailConfig;

  @override
  Future<List<trek.Stage>> getStages() async {
    final dao = StagesDao(_db);
    final rows = await dao.getByTrailId(_trailConfig.id);

    return rows
        .map(
          (row) => trek.Stage(
            id: '${_trailConfig.id}-${row.stageNumber}',
            nameFr: row.name,
            nameEn: row.name,
            distance: row.distanceKm,
            elevationGain: row.elevationGainM,
            elevationLoss: row.elevationLossM,
            estimatedDurationMinutes: _estimateDuration(
              row.distanceKm,
              row.elevationGainM,
            ),
            difficulty: row.difficulty,
            orderIndex: row.stageNumber - 1,
            startLat: row.startLat,
            startLng: row.startLng,
            endLat: row.endLat,
            endLng: row.endLng,
            descriptionFr: row.description,
            descriptionEn: row.description,
          ),
        )
        .toList();
  }

  @override
  Future<List<trek.TrackPoint>> getTrackPoints(String stageId) async {
    // Les TrackPoints viendront du parsing GPX ou d'une table dediee.
    // Pour l'instant, retourner une liste vide.
    return [];
  }

  @override
  Future<TrailConfigData?> getTrailConfig() async {
    return TrailConfigData(
      id: _trailConfig.id,
      name: _trailConfig.name,
      totalStages: _trailConfig.totalStages,
      totalDistanceKm: _trailConfig.totalDistanceKm,
      totalElevationGain: _trailConfig.totalElevationGain,
    );
  }

  /// Estime la duree en minutes a partir de la distance et du D+.
  ///
  /// Formule simplifiee : 15 min/km + 10 min/100m D+
  /// (approximation Naismith). Arrondi a l'entier superieur.
  int _estimateDuration(double distanceKm, int elevationGainM) {
    final baseMinutes = distanceKm * 15.0;
    final climbMinutes = elevationGainM / 100.0 * 10.0;
    return (baseMinutes + climbMinutes).ceil();
  }
}
