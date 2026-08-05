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
/// derniere du JSON.
///
/// **Etape de depart — garde de POSITION (#98856, port GR20 07d7ce8)** : au
/// lancement, on veut eviter un faux « arrive » declenche pres du refuge de
/// DEPART. L'ancienne version bloquait l'etape de depart par IDENTITE
/// (`plan.isStartStage`), ce qui ecartait AUSSI l'arrivee reelle a la fin de
/// cette etape (verrou oeuf-poule : le trek restait bloque a la 1re etape). On
/// neutralise desormais la detection UNIQUEMENT tant qu'on est encore au point
/// de DEPART physique de l'etape de depart (extremite non partagee avec l'etape
/// suivante, donc direction-aware ; distance <= [departureRadiusMeters]) ;
/// l'arrivee reelle a l'autre extremite (distToEnd) est bien emise. Sans plan,
/// on retombe sur le comportement historique (derniere = plus grand
/// `orderIndex`), adapte aux sentiers mono-sens sans decoupage.
///
/// Guard anti-doublon : un Set<String> [alreadyArrived] empeche
/// d'emettre deux fois la meme etape.
class ArrivalDetectionService {
  /// Cree un service de detection d'arrivee.
  ///
  /// [arrivalRadiusMeters] -- rayon de detection en metres (defaut 150m).
  /// [departureRadiusMeters] -- rayon autour du point de DEPART de l'etape de
  /// depart en-deca duquel une detection est consideree comme un faux positif
  /// « on est encore au refuge de depart » (#98856, port GR20). Defaut 150m.
  ArrivalDetectionService({
    this.arrivalRadiusMeters = 150.0,
    this.departureRadiusMeters = 150.0,
  });

  /// Rayon de detection d'arrivee en metres.
  final double arrivalRadiusMeters;

  /// #98856 (port GR20 07d7ce8) — Rayon (m) autour du point de DEPART de
  /// l'etape de depart. Sert UNIQUEMENT a neutraliser un faux positif d'arrivee
  /// au tout debut du trek (on n'a pas encore quitte le refuge de depart), sans
  /// jamais bloquer l'arrivee REELLE (distToEnd) de cette meme etape de depart.
  /// Remplace l'ancien blocage par IDENTITE `plan.isStartStage(...)` qui ecartait
  /// toute detection d'arrivee de l'etape de depart (verrou oeuf-poule).
  final double departureRadiusMeters;

  /// Set des stageId deja emis — anti-doublon.
  final Set<String> alreadyArrived = {};

  /// Emet un Stream<ArrivalEvent> a partir d'un stream GPS.
  ///
  /// [positionStream] -- stream de positions GPS (fourni par GpsService).
  /// [stages] -- liste des etapes du sentier (triees par orderIndex attendu).
  /// [plan] -- plan de marche optionnel (sens + parcours). S'il est fourni :
  ///   * la fin du sentier (`trailEnd`) = **derniere etape du parcours dans le
  ///     sens de marche** ([TrekPlan.finalStageId]), direction-aware ;
  ///   * l'**etape de depart** ([TrekPlan.isStartStage]) n'emet pas d'arrivee
  ///     tant qu'on est encore a son point de depart (garde de POSITION,
  ///     distToStart <= [departureRadiusMeters]), mais son arrivee REELLE (fin
  ///     de l'etape) est bien emise — #98856, port GR20 07d7ce8 ;
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

        // Avec un plan : ignorer les etapes hors parcours.
        if (plan != null && !plan.contains(stage.id)) {
          continue;
        }

        final distToEnd = GeoUtils.haversineDistance(
          lat,
          lng,
          stage.endLat,
          stage.endLng,
        );

        // #98856 FIX VERROU OEUF-POULE (port GR20 07d7ce8) — On NE bloque PLUS
        // l'etape de depart par IDENTITE (`plan.isStartStage`). L'ancien garde
        // ecartait TOUTE detection d'arrivee de l'etape de depart, y compris
        // l'arrivee REELLE a sa fin : en Nord->Sud (etape de depart = etape 1)
        // comme en Sud->Nord (etape de depart = derniere du JSON), l'avancement
        // de la 1re etape n'etait jamais capte (verrou oeuf-poule, preuve
        // terrain laugr20). On remplace ce blocage par un garde de POSITION :
        // on ne neutralise la detection QUE si on est encore au point de DEPART
        // physique de l'etape de depart (faux positif au lancement). Ce point
        // est direction-aware : c'est l'extremite de l'etape de depart qui n'est
        // PAS partagee avec l'etape suivante du parcours (le vrai trailhead) —
        // en sens direct c'est `start`, en sens inverse c'est `end`. L'arrivee
        // reelle (l'autre extremite / distToEnd) passe.
        if (plan != null && plan.isStartStage(stage.id)) {
          final distToDeparture =
              _distanceToDeparturePoint(lat, lng, stage, stages, plan);
          if (distToDeparture != null &&
              distToDeparture <= departureRadiusMeters) {
            // Faux positif au refuge de depart : on n'emet rien pour cette etape
            // sur ce point, mais on la laisse eligible pour la vraie arrivee.
            continue;
          }
        }

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

  /// #98856 — Distance (m) au point de DEPART physique de l'etape de depart,
  /// direction-aware, ou null si indeterminable.
  ///
  /// Le point de depart d'une etape est celle de ses deux extremites
  /// (`start`/`end`) qui n'est PAS partagee avec l'etape SUIVANTE du parcours —
  /// c.-a-d. le trailhead d'ou l'on s'elance :
  ///  * sens direct (parcours dans l'ordre croissant) : l'etape suivante commence
  ///    a `end` de l'etape de depart -> le depart est `start` ;
  ///  * sens inverse : l'etape suivante « rejoint » `start` de l'etape de depart
  ///    -> le depart est `end`.
  /// On tranche en comparant a quelle extremite l'etape suivante est la plus
  /// proche (via ses propres extremites). Sans etape suivante (parcours
  /// mono-etape), il n'y a pas de trailhead distinct : on retourne null (aucune
  /// suppression -> l'arret reste manuel, coherent avec resolveArrival).
  double? _distanceToDeparturePoint(
    double lat,
    double lng,
    Stage startStage,
    List<Stage> stages,
    TrekPlan plan,
  ) {
    final nextId = plan.nextStageId(startStage.id);
    if (nextId == null) return null; // mono-etape : pas de trailhead distinct.

    Stage? next;
    for (final s in stages) {
      if (s.id == nextId) {
        next = s;
        break;
      }
    }
    if (next == null) return null;

    // Extremite de l'etape de depart la plus proche de l'etape suivante = point
    // d'ARRIVEE (jonction) ; l'autre extremite = point de DEPART (trailhead).
    double nearestOf(double aLat, double aLng) {
      final d1 =
          GeoUtils.haversineDistance(aLat, aLng, next!.startLat, next.startLng);
      final d2 =
          GeoUtils.haversineDistance(aLat, aLng, next.endLat, next.endLng);
      return d1 < d2 ? d1 : d2;
    }

    final startEndProximity =
        nearestOf(startStage.startLat, startStage.startLng);
    final endEndProximity = nearestOf(startStage.endLat, startStage.endLng);

    // Le depart est l'extremite la PLUS ELOIGNEE de l'etape suivante.
    final departIsStart = startEndProximity > endEndProximity;
    final depLat = departIsStart ? startStage.startLat : startStage.endLat;
    final depLng = departIsStart ? startStage.startLng : startStage.endLng;

    return GeoUtils.haversineDistance(lat, lng, depLat, depLng);
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
