/// L'implantation en base de l'acces aux donnees d'un sentier, derriere
/// l'interface abstraite du domaine.
library;

import '../../../core/config/trail_config.dart';
import '../../../core/data/daos/stages_dao.dart';
import '../../../core/data/daos/trail_accommodations_dao.dart';
import '../../../core/data/daos/trail_itineraries_dao.dart';
import '../../../core/data/daos/trail_stages_dao.dart';
import '../../../core/data/database.dart';
import '../../../core/geo/trail_track.dart';
import '../../../core/geo/trace_point.dart';
import '../../../core/models/stage_row.dart';
import '../../../domain/stage_accommodation.dart';
import '../domain/trail_data_provider.dart';

/// Implementation Drift de TrailDataProvider.
///
/// Wrappe les DAO existants (StagesDao, TrailGpxPointsDao)
/// pour fournir l'acces aux donnees via l'interface abstraite.
class DriftTrailDataProvider implements TrailDataProvider {
  DriftTrailDataProvider({
    required AppDatabase db,
    required TrailConfig trailConfig,
  }) : _db = db,
       _trailConfig = trailConfig;

  final AppDatabase _db;
  final TrailConfig _trailConfig;

  @override
  Future<List<StageModel>> getStages(String trailId) async {
    final dao = StagesDao(_db);
    final rows = await dao.getByTrailId(trailId);
    return rows.map(StageModel.fromDb).toList();
  }

  /// Points de la trace [trackId], via le CHEMIN UNIQUE de lecture de trace.
  ///
  /// Cette methode portait sa propre conversion « lignes de la base ->
  /// [TrackPoint] », accumulation de la distance comprise : une SECONDE
  /// definition du meme calcul que celui de la carte, et elle n avait aucun
  /// appelant dans `lib/` — donc rien ne l aurait signalee si elle avait derive.
  /// Elle delegue desormais a [LecteurDeTrace], comme `gpxTrackProvider`
  /// (tache 606).
  @override
  Future<List<TrackPoint>> getTrackPoints(String trackId) {
    return LecteurDeTrace(db: _db).pointsDeLaTrace([trackId]);
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
      final itineraryStages = await stagesDao.getByItineraryId(itinerary.id);
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
      result.addAll(
        rows.map(
          (row) => StageAccommodation(
            id: row.id,
            stageId: row.stageId,
            stageNumber: stage.stageNumber,
            nameFr: row.nameFr,
            nameEn: row.nameEn,
            // Type String libre (#81752) : la valeur DB est preservee
            // telle quelle, y compris un type inconnu du moteur.
            type: row.type,
            lat: row.lat,
            lng: row.lng,
            phone: row.phone,
            email: row.email,
            website: row.website,
            capacity: row.capacity,
            priceRange: row.priceRange,
            bookingUrl: row.bookingUrl,
            // L ADRESSE POSTALE (tache 641, bug 15) : elle vient de la base,
            // comme tout le reste de la fiche.
            address: row.address,
          ),
        ),
      );
    }
    return result;
  }

  @override
  TrailConfig getTrailConfig() => _trailConfig;
}
