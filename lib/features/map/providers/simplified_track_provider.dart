import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/geo/douglas_peucker.dart';
import '../../../core/geo/track_point.dart';
import 'gpx_track_provider.dart';

/// Seuils de simplification Douglas-Peucker selon le niveau de zoom.
///
/// zoom < 9  → epsilon 200m (vue large, peu de points)
/// zoom 9-12 → epsilon 50m  (vue intermédiaire)
/// zoom >= 13 → epsilon 0   (tous les points, vue détaillée)
double _epsilonForZoom(int zoomLevel) {
  if (zoomLevel < 9) return 200.0;
  if (zoomLevel <= 12) return 50.0;
  return 0.0;
}

/// Provider du tracé simplifié, paramétré par (trailId, zoomLevel).
///
/// Applique l'algorithme Douglas-Peucker avec un epsilon adapté
/// au niveau de zoom courant. Les seuils sont discrets pour
/// limiter les recalculs inutiles.
final simplifiedTrackProvider = Provider.family<
    AsyncValue<List<TrackPoint>>, ({String trailId, int zoomLevel})>(
  (ref, params) {
    final rawTrack = ref.watch(gpxTrackProvider(params.trailId));

    return rawTrack.when(
      data: (points) {
        final epsilon = _epsilonForZoom(params.zoomLevel);

        // Pas de simplification si epsilon = 0
        if (epsilon == 0.0) return AsyncData(points);

        final simplified = DouglasPeucker.simplify(points, epsilon);
        return AsyncData(simplified);
      },
      loading: () => const AsyncLoading(),
      error: (error, stack) => AsyncError(error, stack),
    );
  },
);
