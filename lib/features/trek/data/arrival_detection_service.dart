import 'dart:async';

import '../../../core/geo/geo_utils.dart';
import '../domain/models/stage.dart';

/// Type d'evenement d'arrivee detecte.
enum ArrivalType {
  /// L'utilisateur est arrive a la fin d'une etape
  stageEnd,

  /// L'utilisateur est arrive a la fin du sentier (derniere etape)
  trailEnd,
}

/// Evenement emis lorsqu'une arrivee est detectee.
///
/// Contient le [type] d'arrivee, l'identifiant de l'etape [stageId]
/// et le [timestamp] de la detection.
class ArrivalEvent {
  const ArrivalEvent({
    required this.type,
    required this.stageId,
    required this.timestamp,
  });

  /// Type d'arrivee (fin d'etape ou fin de sentier)
  final ArrivalType type;

  /// Identifiant de l'etape concernee
  final String stageId;

  /// Horodatage de la detection
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

/// Service de detection d'arrivee en fin d'etape ou fin de sentier.
///
/// Compare la position GPS de l'utilisateur au point d'arrivee
/// de chaque etape. Quand la distance est inferieure au
/// [arrivalRadiusMeters], un [ArrivalEvent] est emis via [events].
///
/// Guard anti-doublon : chaque etape ne peut etre detectee qu'une
/// seule fois grace au [Set] interne [_alreadyArrived].
class ArrivalDetectionService {
  ArrivalDetectionService({
    this.arrivalRadiusMeters = defaultArrivalRadiusMeters,
    required List<Stage> stages,
  }) : _stages = List.unmodifiable(stages);

  /// Rayon de detection par defaut en metres.
  static const double defaultArrivalRadiusMeters = 150.0;

  /// Rayon configurable pour la detection d'arrivee.
  final double arrivalRadiusMeters;

  /// Liste des etapes du sentier (immutable apres construction).
  final List<Stage> _stages;

  /// Ensemble des identifiants d'etapes deja detectees (guard anti-doublon).
  final Set<String> _alreadyArrived = {};

  /// Controller pour le stream d'evenements d'arrivee.
  final StreamController<ArrivalEvent> _eventController =
      StreamController<ArrivalEvent>.broadcast();

  /// Stream d'evenements d'arrivee.
  ///
  /// Emet un [ArrivalEvent] a chaque fois qu'une arrivee est detectee.
  /// Chaque etape n'est emise qu'une seule fois (pas de doublon).
  Stream<ArrivalEvent> get events => _eventController.stream;

  /// Ensemble des etapes deja detectees (lecture seule pour les tests).
  Set<String> get alreadyArrived => Set.unmodifiable(_alreadyArrived);

  /// Verifie si la position courante declenche une arrivee.
  ///
  /// [lat] et [lng] sont les coordonnees GPS de l'utilisateur.
  /// Si la distance au point d'arrivee d'une etape est inferieure
  /// a [arrivalRadiusMeters] ET que cette etape n'a pas deja ete
  /// detectee, un [ArrivalEvent] est emis.
  void checkPosition(double lat, double lng) {
    if (_eventController.isClosed) return;

    for (final stage in _stages) {
      // Guard anti-doublon
      if (_alreadyArrived.contains(stage.id)) continue;

      final distance = GeoUtils.haversineDistance(
        lat,
        lng,
        stage.endLat,
        stage.endLng,
      );

      if (distance <= arrivalRadiusMeters) {
        _alreadyArrived.add(stage.id);

        // Determiner si c'est la fin du sentier (derniere etape par orderIndex)
        final isLastStage = _stages.every(
          (s) => s.orderIndex <= stage.orderIndex,
        );

        final event = ArrivalEvent(
          type: isLastStage ? ArrivalType.trailEnd : ArrivalType.stageEnd,
          stageId: stage.id,
          timestamp: DateTime.now(),
        );

        _eventController.add(event);
      }
    }
  }

  /// Reinitialise le guard anti-doublon.
  ///
  /// Permet de re-detecter toutes les etapes (utile en cas de
  /// redemarrage de trek ou de changement de sentier).
  void reset() {
    _alreadyArrived.clear();
  }

  /// Libere les ressources du service.
  ///
  /// Apres appel, aucun evenement ne sera plus emis.
  void dispose() {
    _eventController.close();
  }
}
