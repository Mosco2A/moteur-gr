import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/geo/geo_utils.dart';
import '../domain/models/stage.dart';

/// Service de detection d'etape courante basee sur le stream GPS.
///
/// Recoit un Stream<Position> et une liste de Stage,
/// calcule la distance haversine a chaque debut/fin d'etape,
/// et emet le stageId le plus proche.
///
/// Hysteresis configurable (defaut 200m) : le changement d'etape
/// ne se produit que si la nouvelle etape candidate est plus proche
/// d'au moins [hysteresisMeters] metres que l'etape courante.
/// Cela empeche le flip-flop aux frontieres entre etapes.
class StageDetectionService {
  /// Cree un service de detection d'etape.
  ///
  /// [hysteresisMeters] -- marge anti flip-flop en metres (defaut 200m).
  /// Une nouvelle etape n'est emise que si sa distance minimale
  /// est inferieure a (distance etape courante - hysteresis).
  StageDetectionService({
    this.hysteresisMeters = 200.0,
  });

  /// Marge d'hysteresis en metres pour empecher le flip-flop.
  final double hysteresisMeters;

  /// Calcule la distance minimale entre une position GPS et une etape.
  ///
  /// Retourne le minimum entre la distance au point de depart
  /// et la distance au point d'arrivee de l'etape.
  double _distanceToStage(double lat, double lng, Stage stage) {
    final distToStart = GeoUtils.haversineDistance(
      lat,
      lng,
      stage.startLat,
      stage.startLng,
    );
    final distToEnd = GeoUtils.haversineDistance(
      lat,
      lng,
      stage.endLat,
      stage.endLng,
    );
    return distToStart < distToEnd ? distToStart : distToEnd;
  }

  /// Trouve l'etape la plus proche et sa distance minimale.
  ///
  /// Retourne un record (stageId, distance) ou null si la liste est vide.
  ({String stageId, double distance})? _findClosestStage(
    double lat,
    double lng,
    List<Stage> stages,
  ) {
    if (stages.isEmpty) return null;

    String closestId = stages.first.id;
    double closestDist = _distanceToStage(lat, lng, stages.first);

    for (var i = 1; i < stages.length; i++) {
      final dist = _distanceToStage(lat, lng, stages[i]);
      if (dist < closestDist) {
        closestDist = dist;
        closestId = stages[i].id;
      }
    }

    return (stageId: closestId, distance: closestDist);
  }

  /// Emet un Stream<String> du stageId courant a partir d'un stream GPS.
  ///
  /// [positionStream] -- stream de positions GPS (fourni par GpsService)
  /// [stages] -- liste des etapes du sentier (generique, pas de nombre en dur)
  ///
  /// L'hysteresis empeche les changements intempestifs :
  /// une nouvelle etape n'est emise que si elle est significativement
  /// plus proche (delta > hysteresisMeters) que l'etape courante.
  ///
  /// Emet des valeurs distinctes uniquement (pas de doublons consecutifs).
  /// Si la liste de stages est vide, le stream se ferme immediatement.
  Stream<String> currentStageId(
    Stream<Position> positionStream,
    List<Stage> stages,
  ) {
    if (stages.isEmpty) return const Stream.empty();

    String? lastEmittedId;

    return positionStream.map((position) {
      final lat = position.latitude;
      final lng = position.longitude;

      final closest = _findClosestStage(lat, lng, stages);
      if (closest == null) return null;

      // Premier point -- pas d'hysteresis
      if (lastEmittedId == null) {
        lastEmittedId = closest.stageId;
        return closest.stageId;
      }

      // Meme etape -- pas de changement
      if (closest.stageId == lastEmittedId) {
        return closest.stageId;
      }

      // Etape differente -- verifier l'hysteresis
      // On compare la distance a la nouvelle etape candidate
      // avec la distance a l'etape courante.
      // Le changement ne se fait que si la nouvelle est plus proche
      // d'au moins hysteresisMeters.
      final currentStage = stages.where((s) => s.id == lastEmittedId).first;
      final currentDist = _distanceToStage(lat, lng, currentStage);

      if (closest.distance < currentDist - hysteresisMeters) {
        lastEmittedId = closest.stageId;
        return closest.stageId;
      }

      // Hysteresis bloque le changement -- garder l'etape courante
      return lastEmittedId;
    }).where((id) => id != null).cast<String>().distinct();
  }
}

/// Provider Riverpod 3 pour StageDetectionService.
///
/// Fournit une instance avec l'hysteresis par defaut (200m).
/// Overridable dans les tests.
final stageDetectionServiceProvider = Provider<StageDetectionService>((ref) {
  return StageDetectionService();
});
