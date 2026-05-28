import 'models/stage.dart';
import 'models/track_point.dart';

/// Configuration du sentier depuis la base de donnees.
///
/// Sous-ensemble de TrailConfig charge dynamiquement.
/// Utilise par les providers qui ont besoin des metadata du sentier
/// sans dependre d'un fichier de configuration statique.
class TrailConfigData {
  const TrailConfigData({
    required this.id,
    required this.name,
    required this.totalStages,
    required this.totalDistanceKm,
    required this.totalElevationGain,
  });

  /// Identifiant unique du sentier (ex: 'gr20', 'tmb')
  final String id;

  /// Nom du sentier (ex: 'GR20')
  final String name;

  /// Nombre total d'etapes
  final int totalStages;

  /// Distance totale en kilometres
  final double totalDistanceKm;

  /// Denivele positif total en metres
  final int totalElevationGain;
}

/// Interface abstraite pour l'acces aux donnees d'un sentier.
///
/// Contrat unique que le moteur GR utilise pour charger les etapes,
/// les points GPS et la configuration d'un sentier. L'implementation
/// concrete (Drift, API, fichier JSON) est injectee via Riverpod.
///
/// Voir [DriftTrailDataProvider] pour l'implementation Drift.
abstract class TrailDataProvider {
  /// Charge toutes les etapes du sentier, triees par orderIndex.
  Future<List<Stage>> getStages();

  /// Charge les points GPS d'une etape donnee.
  ///
  /// [stageId] correspond au champ [Stage.id].
  /// Retourne une liste vide si l'etape n'existe pas
  /// ou n'a pas de trace GPS associe.
  Future<List<TrackPoint>> getTrackPoints(String stageId);

  /// Charge la configuration du sentier.
  ///
  /// Retourne null si aucune configuration n'est trouvee.
  Future<TrailConfigData?> getTrailConfig();
}
