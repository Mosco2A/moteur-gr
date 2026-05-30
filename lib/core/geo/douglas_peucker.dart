import 'geo_utils.dart';
import 'track_point.dart';

/// Algorithme de simplification de trace Douglas-Peucker.
///
/// Version iterative pour supporter les traces longs
/// sans risque de stack overflow.
///
/// @deprecated Phase 2 : utiliser [track_simplifier.dart] dans
/// features/trek/data/ avec le modele TrackPoint Phase 2.
/// Ce fichier est conserve pour la retro-compatibilite avec
/// les providers map/ qui utilisent le TrackPoint core/geo/.
class DouglasPeucker {
  DouglasPeucker._();

  /// Simplifie une liste de TrackPoint en supprimant les points
  /// dont la distance perpendiculaire au segment est inferieure
  /// a [epsilonMeters].
  ///
  /// Les premier et dernier points sont toujours conserves.
  /// Retourne la liste originale si elle contient moins de 3 points.
  static List<TrackPoint> simplify(
    List<TrackPoint> points,
    double epsilonMeters,
  ) {
    if (points.length < 3) return List.of(points);

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
        final pt = points[i];
        final result = GeoUtils.projectPointOnSegment(
          pt.lat,
          pt.lng,
          startPt.lat,
          startPt.lng,
          endPt.lat,
          endPt.lng,
        );
        final dist = result.distanceToSegment;

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
}
