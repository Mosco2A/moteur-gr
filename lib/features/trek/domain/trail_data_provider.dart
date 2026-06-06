import '../../../core/models/stage.dart';
import '../../../core/config/trail_config.dart';
import '../../../core/geo/track_point.dart';
import 'models/stage_accommodation.dart';

/// Interface abstraite pour l'acces aux donnees d'un sentier.
///
/// Decouple la couche domaine de l'implementation Drift.
/// Permet de substituer une source de donnees (mock, API, etc.)
/// sans modifier le code metier.
abstract class TrailDataProvider {
  /// Recupere toutes les etapes d'un sentier, triees par numero
  Future<List<StageModel>> getStages(String trailId);

  /// Recupere les points GPS d'une etape specifique
  Future<List<TrackPoint>> getTrackPoints(String stageId);

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
