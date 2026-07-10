import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/geo/geo_utils.dart';
import '../domain/models/stage.dart';
import '../domain/trek_completion.dart';

/// Evenement d'arrivee emis quand le randonneur atteint la fin d'une etape
/// ou la fin du sentier complet.
class ArrivalEvent {
  /// Cree un evenement d'arrivee.
  ///
  /// [type] -- 'stageEnd' pour une fin d'etape, 'trailEnd' pour la fin du sentier.
  /// [stageId] -- identifiant de l'etape concernee.
  /// [timestamp] -- horodatage de la detection.
  const ArrivalEvent({
    required this.type,
    required this.stageId,
    required this.timestamp,
  });

  /// Type d'arrivee : 'stageEnd' ou 'trailEnd'.
  final String type;

  /// Identifiant de l'etape atteinte.
  final String stageId;

  /// Horodatage de la detection.
  final DateTime timestamp;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ArrivalEvent &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          stageId == other.stageId &&
          timestamp == other.timestamp;

  @override
  int get hashCode => Object.hash(type, stageId, timestamp);

  @override
  String toString() =>
      'ArrivalEvent(type: $type, stageId: $stageId, timestamp: $timestamp)';
}

/// Service de detection d'arrivee a la fin d'une etape.
///
/// Ecoute un Stream<Position> et une liste de Stage,
/// calcule la distance haversine entre la position courante
/// et le point d'arrivee (endLat/endLng) de chaque etape.
///
/// Quand la distance est inferieure au [arrivalRadiusMeters] (defaut 150m),
/// un [ArrivalEvent] est emis.
///
/// **Fin de trek direction-aware** : quand un [TrekPlan] est fourni (sens de
/// marche + parcours), la « fin du sentier » (`trailEnd`) est la **derniere
/// etape du parcours dans le sens de marche** — pas systematiquement l'etape
/// au plus grand `orderIndex`. En Sud->Nord, la fin est donc l'etape 1, pas la
/// derniere du JSON. De plus, aucune arrivee n'est emise a l'**etape de depart**
/// du parcours (garde anti-felicitations prematurees). Sans plan, on retombe
/// sur le comportement historique (derniere = plus grand `orderIndex`), adapte
/// aux sentiers mono-sens sans decoupage.
///
/// Guard anti-doublon : un Set<String> [alreadyArrived] empeche
/// d'emettre deux fois la meme etape.
class ArrivalDetectionService {
  /// Cree un service de detection d'arrivee.
  ///
  /// [arrivalRadiusMeters] -- rayon de detection en metres (defaut 150m).
  ArrivalDetectionService({
    this.arrivalRadiusMeters = 150.0,
  });

  /// Rayon de detection d'arrivee en metres.
  final double arrivalRadiusMeters;

  /// Set des stageId deja emis — anti-doublon.
  final Set<String> alreadyArrived = {};

  /// Emet un Stream<ArrivalEvent> a partir d'un stream GPS.
  ///
  /// [positionStream] -- stream de positions GPS (fourni par GpsService).
  /// [stages] -- liste des etapes du sentier (triees par orderIndex attendu).
  /// [plan] -- plan de marche optionnel (sens + parcours). S'il est fourni :
  ///   * la fin du sentier (`trailEnd`) = **derniere etape du parcours dans le
  ///     sens de marche** ([TrekPlan.finalStageId]), direction-aware ;
  ///   * aucune arrivee n'est emise a l'**etape de depart** du parcours
  ///     ([TrekPlan.isStartStage]) — garde anti-felicitations prematurees ;
  ///   * les etapes hors parcours sont ignorees.
  ///   Sans plan, comportement historique : `trailEnd` = plus grand orderIndex
  ///   (sentier mono-sens sans decoupage).
  ///
  /// Pour chaque position recue, on verifie si on est dans le rayon
  /// d'arrivee de la fin (endLat/endLng) d'une etape.
  /// Si oui et que l'etape n'a pas deja ete emise, un ArrivalEvent est cree.
  ///
  /// Si la liste de stages est vide, le stream se ferme immediatement.
  Stream<ArrivalEvent> arrivalEvents(
    Stream<Position> positionStream,
    List<Stage> stages, {
    TrekPlan? plan,
  }) {
    if (stages.isEmpty) return const Stream.empty();

    // Fin de sentier direction-aware : id de la derniere etape du parcours dans
    // le sens de marche si un plan est fourni, sinon plus grand orderIndex.
    final String? finalStageId = plan?.finalStageId;
    final int maxOrderIndex =
        stages.map((s) => s.orderIndex).reduce((a, b) => a > b ? a : b);

    return positionStream.expand((position) {
      final lat = position.latitude;
      final lng = position.longitude;
      final events = <ArrivalEvent>[];

      for (final stage in stages) {
        // Deja emis — on saute
        if (alreadyArrived.contains(stage.id)) continue;

        // Avec un plan : ignorer les etapes hors parcours et l'etape de depart
        // (garde anti-felicitations prematurees — pas d'arrivee au refuge de
        // depart, p. ex. au lancement d'un trek pris a rebours du sens de
        // reference).
        if (plan != null &&
            (!plan.contains(stage.id) || plan.isStartStage(stage.id))) {
          continue;
        }

        final distToEnd = GeoUtils.haversineDistance(
          lat,
          lng,
          stage.endLat,
          stage.endLng,
        );

        if (distToEnd <= arrivalRadiusMeters) {
          alreadyArrived.add(stage.id);

          // Direction-aware : la fin de trek est la derniere etape du parcours
          // dans le sens de marche (si plan), sinon le plus grand orderIndex.
          final bool isFinal = finalStageId != null
              ? stage.id == finalStageId
              : stage.orderIndex == maxOrderIndex;

          events.add(ArrivalEvent(
            type: isFinal ? 'trailEnd' : 'stageEnd',
            stageId: stage.id,
            timestamp: DateTime.now(),
          ));
        }
      }

      return events;
    });
  }

  /// Reinitialise le guard anti-doublon.
  ///
  /// A appeler au demarrage d'un nouveau trek ou apres un reset.
  void reset() {
    alreadyArrived.clear();
  }
}

/// Provider Riverpod 3 pour ArrivalDetectionService.
///
/// Fournit une instance avec le rayon par defaut (150m).
/// Overridable dans les tests.
final arrivalDetectionServiceProvider =
    Provider<ArrivalDetectionService>((ref) {
  return ArrivalDetectionService();
});
