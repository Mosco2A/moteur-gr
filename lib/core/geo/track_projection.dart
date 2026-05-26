import 'dart:math';

import 'geo_utils.dart';
import 'track_point.dart';

/// Résultat de la projection d'un point GPS sur le tracé.
///
/// Contient la position projetée, la distance au tracé,
/// l'index du segment, et les distances cumulées.
typedef TrackProjection = ({
  double projectedLat,
  double projectedLng,
  double distanceToTrackM,
  int trackIndexPosition,
  double distanceFromStartM,
  double distanceRemainingM,
});

/// Projette un point GPS utilisateur sur le segment de tracé le plus proche.
///
/// Optimisation : recherche dans une fenêtre de 50 segments autour
/// de la dernière projection connue pour éviter un scan complet.
class TrackProjector {
  TrackProjector._();

  /// Taille de la fenêtre de recherche autour du dernier index connu.
  static const int _searchWindow = 50;

  /// Projette [userLat, userLng] sur le tracé [trackPoints].
  ///
  /// [lastKnownIndex] — index du segment de la dernière projection.
  /// Si null, on scanne tout le tracé (premier appel).
  ///
  /// Retourne un [TrackProjection] avec toutes les infos nécessaires.
  /// Lève une [ArgumentError] si le tracé a moins de 2 points.
  static TrackProjection project({
    required double userLat,
    required double userLng,
    required List<TrackPoint> trackPoints,
    int? lastKnownIndex,
  }) {
    if (trackPoints.length < 2) {
      throw ArgumentError(
        'Le tracé doit contenir au moins 2 points '
        '(reçu: ${trackPoints.length}).',
      );
    }

    // Déterminer la fenêtre de recherche
    final totalSegments = trackPoints.length - 1;
    int startIdx;
    int endIdx;

    if (lastKnownIndex == null) {
      // Premier appel : scanner tout le tracé
      startIdx = 0;
      endIdx = totalSegments;
    } else {
      // Recherche dans une fenêtre autour du dernier index
      startIdx = max(0, lastKnownIndex - _searchWindow);
      endIdx = min(totalSegments, lastKnownIndex + _searchWindow);
    }

    // Trouver le segment le plus proche
    double bestDistance = double.infinity;
    int bestIndex = startIdx;
    double bestLat = trackPoints[startIdx].lat;
    double bestLng = trackPoints[startIdx].lng;

    for (int i = startIdx; i < endIdx; i++) {
      final a = trackPoints[i];
      final b = trackPoints[i + 1];

      final proj = GeoUtils.projectPointOnSegment(
        userLat, userLng,
        a.lat, a.lng,
        b.lat, b.lng,
      );

      if (proj.distanceToSegment < bestDistance) {
        bestDistance = proj.distanceToSegment;
        bestIndex = i;
        bestLat = proj.projectedLat;
        bestLng = proj.projectedLng;
      }
    }

    // Calculer la distance depuis le début du tracé
    // = distance cumulée jusqu'au segment + distance du point A au projeté
    final segmentStart = trackPoints[bestIndex];
    final distAlongSegment = GeoUtils.haversineDistance(
      segmentStart.lat, segmentStart.lng,
      bestLat, bestLng,
    );
    final distanceFromStart =
        segmentStart.distanceFromStart + distAlongSegment;

    // Distance totale du tracé = distanceFromStart du dernier point
    final totalDistance = trackPoints.last.distanceFromStart;
    final distanceRemaining = max(0.0, totalDistance - distanceFromStart);

    return (
      projectedLat: bestLat,
      projectedLng: bestLng,
      distanceToTrackM: bestDistance,
      trackIndexPosition: bestIndex,
      distanceFromStartM: distanceFromStart,
      distanceRemainingM: distanceRemaining,
    );
  }
}
