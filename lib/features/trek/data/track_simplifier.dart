import 'dart:math';

import '../domain/models/track_point.dart';

/// Simplification de trace GPS par algorithme Douglas-Peucker.
///
/// Utilise la distance haversine (cross-track) pour le calcul
/// de distance perpendiculaire point-segment.
/// Version iterative pour supporter les traces longs
/// sans risque de stack overflow.
class DouglasPeucker {
  DouglasPeucker._();

  /// Rayon moyen de la Terre en metres.
  static const double _earthRadiusMeters = 6371000.0;

  /// Epsilon par defaut en degres (~11 metres a l'equateur).
  static const double defaultEpsilon = 0.0001;

  /// Simplifie une liste de [TrackPoint] en supprimant les points
  /// dont la distance perpendiculaire au segment est inferieure
  /// a [epsilon] (en degres, defaut [defaultEpsilon] ~ 11m).
  ///
  /// Les premier et dernier points sont TOUJOURS preserves.
  /// Retourne la liste originale si elle contient moins de 3 points.
  static List<TrackPoint> simplify(
    List<TrackPoint> points, [
    double epsilon = defaultEpsilon,
  ]) {
    if (points.length < 3) return List.of(points);

    // Convertir epsilon degres en metres pour la comparaison haversine
    final epsilonMeters = epsilon * _earthRadiusMeters * pi / 180.0;

    // Tableau de booleens pour marquer les points a conserver
    final keep = List.filled(points.length, false);
    keep[0] = true;
    keep[points.length - 1] = true;

    // Pile iterative : paires (startIndex, endIndex) a traiter
    final stack = <(int, int)>[];
    stack.add((0, points.length - 1));

    while (stack.isNotEmpty) {
      final (startIdx, endIdx) = stack.removeLast();

      if (endIdx - startIdx < 2) continue;

      final startPt = points[startIdx];
      final endPt = points[endIdx];

      // Chercher le point le plus eloigne du segment [start, end]
      var maxDist = 0.0;
      var maxIdx = startIdx;

      for (var i = startIdx + 1; i < endIdx; i++) {
        final dist = _crossTrackDistance(
          points[i].lat,
          points[i].lng,
          startPt.lat,
          startPt.lng,
          endPt.lat,
          endPt.lng,
        );

        if (dist > maxDist) {
          maxDist = dist;
          maxIdx = i;
        }
      }

      // Si la distance max depasse epsilon, conserver ce point
      // et subdiviser le segment
      if (maxDist > epsilonMeters) {
        keep[maxIdx] = true;
        stack.add((startIdx, maxIdx));
        stack.add((maxIdx, endIdx));
      }
    }

    // Construire la liste simplifiee en conservant l'ordre
    final result = <TrackPoint>[];
    for (var i = 0; i < points.length; i++) {
      if (keep[i]) {
        result.add(points[i]);
      }
    }

    return result;
  }

  /// Convertit des degres en radians.
  static double _toRadians(double degrees) => degrees * pi / 180.0;

  /// Distance haversine entre deux points GPS, en metres.
  static double _haversineDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLng / 2) *
            sin(dLng / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return _earthRadiusMeters * c;
  }

  /// Distance perpendiculaire (cross-track) d'un point a un segment
  /// defini par deux points, en metres.
  ///
  /// Utilise la formule de cross-track distance basee sur haversine.
  /// Si le segment est degenere (A == B), retourne la distance au point A.
  /// Si la projection tombe en dehors du segment, retourne la distance
  /// au point le plus proche (A ou B).
  static double _crossTrackDistance(
    double pointLat,
    double pointLng,
    double segALat,
    double segALng,
    double segBLat,
    double segBLng,
  ) {
    // Segment degenere
    final segLength = _haversineDistance(segALat, segALng, segBLat, segBLng);
    if (segLength < 0.001) {
      return _haversineDistance(pointLat, pointLng, segALat, segALng);
    }

    // Distance angulaire A -> Point
    final distAP =
        _haversineDistance(segALat, segALng, pointLat, pointLng) /
            _earthRadiusMeters;

    // Bearing A -> B
    final bearingAB = _bearing(segALat, segALng, segBLat, segBLng);

    // Bearing A -> Point
    final bearingAP = _bearing(segALat, segALng, pointLat, pointLng);

    // Cross-track distance (formule spherique)
    final crossTrack =
        asin(sin(distAP) * sin(bearingAP - bearingAB)).abs() *
            _earthRadiusMeters;

    // Along-track distance pour verifier si la projection
    // tombe sur le segment
    final alongTrack =
        acos(cos(distAP) / cos(crossTrack / _earthRadiusMeters)) *
            _earthRadiusMeters;

    // Si la projection tombe avant A ou apres B,
    // retourner la distance au point le plus proche
    if (alongTrack < 0) {
      return _haversineDistance(pointLat, pointLng, segALat, segALng);
    }
    if (alongTrack > segLength) {
      return _haversineDistance(pointLat, pointLng, segBLat, segBLng);
    }

    return crossTrack;
  }

  /// Bearing (cap) en radians de point 1 vers point 2.
  static double _bearing(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    final dLng = _toRadians(lng2 - lng1);
    final lat1Rad = _toRadians(lat1);
    final lat2Rad = _toRadians(lat2);

    final y = sin(dLng) * cos(lat2Rad);
    final x =
        cos(lat1Rad) * sin(lat2Rad) -
            sin(lat1Rad) * cos(lat2Rad) * cos(dLng);

    return atan2(y, x);
  }
}
