import 'geo_utils.dart';
import '../models/stage.dart';

/// Evenement de detection d'etape.
///
/// Decrit la relation entre la position de l'utilisateur
/// et les bornes d'une etape.
/// Utilise String pour extensibilite (valeurs inconnues gerees par fallback).
typedef StageDetectionEvent = String;

/// Valeurs connues pour StageDetectionEvent avec fallback generique.
abstract class StageDetectionEventValues {
  /// L'utilisateur est entre dans une etape (proche du point de depart)
  static const String entered = 'entered';

  /// L'utilisateur a termine une etape (proche du point d'arrivee)
  static const String exited = 'exited';

  /// L'utilisateur est entre deux etapes (hors rayon des bornes)
  static const String between = 'between';

  /// Position inconnue ou pas d'etape correspondante
  static const String unknown = 'unknown';

  /// Valeur par defaut pour les evenements inconnus
  static const String fallback = unknown;

  /// Toutes les valeurs connues
  static const List<String> values = [entered, exited, between, unknown];

  /// Convertit une chaine en StageDetectionEvent avec fallback
  static StageDetectionEvent fromString(String value) =>
      values.contains(value) ? value : fallback;
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
      return (stageNumber: 0, event: StageDetectionEventValues.unknown);
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
          event: StageDetectionEventValues.entered,
        );
      }

      // Proche du point d'arrivée de l'étape
      if (distToEnd <= toleranceRadiusM) {
        return (
          stageNumber: stage.stageNumber,
          event: StageDetectionEventValues.exited,
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
        event: StageDetectionEventValues.between,
      );
    }

    return (stageNumber: 0, event: StageDetectionEventValues.unknown);
  }
}
