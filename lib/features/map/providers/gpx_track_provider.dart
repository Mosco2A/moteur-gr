import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/engine/trail_engine.dart';
import '../../../core/geo/gpx_parser.dart';
import '../../../core/geo/track_point.dart';

/// Provider du tracé GPX brut, paramétré par trailId.
///
/// Charge le fichier GPX depuis les assets via GpxParser.parseFromAsset
/// et met en cache le résultat pour éviter les relectures.
/// Utilise le gpxAssetPath de la TrailConfig active.
final gpxTrackProvider =
    FutureProvider.family<List<TrackPoint>, String>((ref, trailId) async {
  final config = ref.watch(trailConfigProvider);

  // Vérifier que le trailId correspond à la config active
  if (config.id != trailId) {
    throw ArgumentError(
      'Trail "$trailId" ne correspond pas à la config active "${config.id}"',
    );
  }

  final points = await GpxParser.parseFromAsset(config.gpxAssetPath);
  return points;
});
