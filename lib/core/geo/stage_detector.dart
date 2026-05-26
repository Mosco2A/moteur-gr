import 'geo_utils.dart';
import '../models/stage.dart';

/// Événement de détection d'étape.
///
/// Décrit la relation entre la position de l'utilisateur
/// et les bornes d'une étape.
enum StageDetectionEvent {
  /// L'utilisateur est entré dans une étape (proche du point de départ)
  entered,

  /// L'utilisateur a terminé une étape (proche du point d'arrivée)
  exited,

  /// L'utilisateur est entre deux étapes (hors rayon des bornes)
  between,

  /// Position inconnue ou pas d'étape correspondante
  unknown,
}

/// Résultat de la détection d'étape.
typedef StageDetection = ({
  int stageNumber,
  StageDetectionEvent event,
});

/// Détecte l'étape courante en comparant la position projetée
/// aux bornes start/end de chaque étape.
///
/// Rayon de tolérance de 200m autour des points start/end.
class StageDetector {
  StageDetector._();

  /// Rayon de tolérance en mètres pour la détection des bornes.
  static const double toleranceRadiusM = 200.0;

  /// Détecte l'étape courante à partir de la position projetée.
  ///
  /// [projectedLat] et [projectedLng] — position projetée sur le tracé.
  /// [stages] — liste des étapes triées par numéro.
  ///
  /// Retourne le numéro d'étape détecté et l'événement associé.
  /// Si aucune étape ne correspond, retourne stageNumber=0 + unknown.
  static StageDetection detect({
    required double projectedLat,
    required double projectedLng,
    required List<StageModel> stages,
  }) {
    if (stages.isEmpty) {
      return (stageNumber: 0, event: StageDetectionEvent.unknown);
    }

    // Vérifier la proximité avec les bornes de chaque étape
    for (final stage in stages) {
      final distToStart = GeoUtils.haversineDistance(
        projectedLat, projectedLng,
        stage.startLat, stage.startLng,
      );

      final distToEnd = GeoUtils.haversineDistance(
        projectedLat, projectedLng,
        stage.endLat, stage.endLng,
      );

      // Proche du point de départ de l'étape
      if (distToStart <= toleranceRadiusM) {
        return (
          stageNumber: stage.stageNumber,
          event: StageDetectionEvent.entered,
        );
      }

      // Proche du point d'arrivée de l'étape
      if (distToEnd <= toleranceRadiusM) {
        return (
          stageNumber: stage.stageNumber,
          event: StageDetectionEvent.exited,
        );
      }
    }

    // Pas proche d'une borne — chercher l'étape la plus probable
    // en trouvant l'étape dont les bornes encadrent le mieux la position
    StageModel? bestStage;
    double bestScore = double.infinity;

    for (final stage in stages) {
      final distToStart = GeoUtils.haversineDistance(
        projectedLat, projectedLng,
        stage.startLat, stage.startLng,
      );

      final distToEnd = GeoUtils.haversineDistance(
        projectedLat, projectedLng,
        stage.endLat, stage.endLng,
      );

      // Score = distance combinée aux deux bornes
      // L'étape la plus probable est celle où on est "entre" les bornes
      final score = distToStart + distToEnd;

      if (score < bestScore) {
        bestScore = score;
        bestStage = stage;
      }
    }

    if (bestStage != null) {
      return (
        stageNumber: bestStage.stageNumber,
        event: StageDetectionEvent.between,
      );
    }

    return (stageNumber: 0, event: StageDetectionEvent.unknown);
  }
}
