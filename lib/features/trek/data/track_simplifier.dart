import 'dart:math';

import '../domain/models/track_point.dart';

/// Algorithme de simplification de trace Douglas-Peucker.
///
/// Utilise la distance haversine (pas euclidienne) pour le calcul
/// de la distance perpendiculaire au segment.
///
/// Version iterative pour supporter les traces longs
/// sans risque de stack overflow.
class DouglasPeucker {
  DouglasPeucker._();

  static const double _earthRadiusMeters = 6371000.0;

  /// Epsilon par defaut : ~0.0001 degres soit environ 11 metres.
  static const double defaultEpsilon = 0.0001;

  /// Simplifie une liste de [TrackPoint] en supprimant les points
  /// dont la distance perpendiculaire au segment est inferieure
  /// a [epsilon] (en degres, defaut [defaultEpsilon] soit ~11m).
  ///
  /// Les premier et dernier points sont TOUJOURS conserves.
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
        final dist = _perpendicularDistance(
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

  /// Calcule la distance perpendiculaire (en metres) entre un point
  /// et un segment defini par deux points, via la formule de Haversine.
  ///
  /// Projette le point sur la droite (segA, segB) puis mesure
  /// la distance haversine entre le point et sa projection.
  static double _perpendicularDistance(
    double pointLat,
    double pointLng,
    double segALat,
    double segALng,
    double segBLat,
    double segBLng,
  ) {
    // Approximation cartesienne locale corrigee par cos(lat)
    final cosLat = cos(_toRadians((segALat + segBLat) / 2));

    final bx = (segBLng - segALng) * cosLat;
    final by = segBLat - segALat;
    final px = (pointLng - segALng) * cosLat;
    final py = pointLat - segALat;

    // Parametre t de la projection sur la droite AB
    final abLenSq = bx * bx + by * by;

    double t;
    if (abLenSq < 1e-15) {
      // Segment degenere (A == B)
      t = 0.0;
    } else {
      t = (px * bx + py * by) / abLenSq;
      t = t.clamp(0.0, 1.0);
    }

    // Point projete en lat/lng
    final projLat = segALat + t * by;
    final projLng = segALng + t * bx / cosLat;

    // Distance haversine entre le point et sa projection
    return _haversineDistance(pointLat, pointLng, projLat, projLng);
  }

  /// Distance haversine en metres entre deux points GPS.
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

  /// Convertit des degres en radians.
  static double _toRadians(double degrees) => degrees * pi / 180.0;
}
