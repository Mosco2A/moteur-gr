import '../../../core/models/stage.dart';
import '../../../core/config/trail_config.dart';
import '../../../core/geo/track_point.dart';
import '../../trek/domain/models/stage_accommodation.dart';

/// Interface abstraite pour l'acces aux donnees d'un sentier.
///
/// Decouple la couche domaine de l'implementation Drift.
/// Permet de substituer une source de donnees (mock, API, etc.)
/// sans modifier le code metier.
abstract class TrailDataProvider {
  /// Recupere toutes les etapes d'un sentier, triees par numero
  Future<List<StageModel>> getStages(String trailId);

  /// Recupere les points GPS d'une TRACE (`trail_gpx_tracks.id`).
  ///
  /// Le parametre s appelait `stageId`, et c etait un nom faux : la requete
  /// filtre sur `trail_gpx_points.trackId`, jamais sur une etape. Renomme
  /// (tache 606) — la methode n a aucun appelant dans `lib/`, donc personne ne
  /// se heurtait a la contradiction.
  Future<List<TrackPoint>> getTrackPoints(String trackId);

  /// Recupere les hebergements d'un sentier, optionnellement
  /// filtres par numero d'etape. Source : base seedee par le
  /// seeder generique (jamais de donnees hardcodees).
  Future<List<StageAccommodation>> getAccommodations(
    String trailId, {
    int? stageNumber,
  });

  /// Recupere la configuration du sentier actif
  TrailConfig getTrailConfig();
}
