import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/geo/douglas_peucker.dart';
import '../../../core/geo/track_point.dart';
import '../../trek/presentation/map/marker_cluster.dart';
import 'gpx_track_provider.dart';

/// Provider du tracé simplifié, paramétré par (trailId, zoomLevel).
///
/// Applique l'algorithme Douglas-Peucker avec un epsilon dynamique
/// adapté au niveau de zoom courant ([dynamicEpsilonForZoom]) : l'epsilon
/// décroît exponentiellement à mesure qu'on zoome, jusqu'à 0 (plein détail)
/// au-delà du zoom 15. La famille reste clé sur un zoom entier pour mémoïser
/// le calcul et ne le rejouer qu'au franchissement d'un niveau.
final simplifiedTrackProvider = Provider.family<
    AsyncValue<List<TrackPoint>>, ({String trailId, int zoomLevel})>(
  (ref, params) {
    final rawTrack = ref.watch(gpxTrackProvider(params.trailId));

    return rawTrack.when(
      data: (points) {
        final epsilon = dynamicEpsilonForZoom(params.zoomLevel);

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
