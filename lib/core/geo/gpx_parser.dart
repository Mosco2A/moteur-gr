import 'package:flutter/services.dart' show rootBundle;
import 'package:gpx/gpx.dart';

import 'geo_utils.dart';
import 'track_point.dart';

/// Parseur de fichiers GPX depuis les assets de l'application.
///
/// Extrait les points du premier track et calcule
/// les distances cumulees via Haversine.
class GpxParser {
  GpxParser._();

  /// Parse un fichier GPX depuis les assets Flutter.
  ///
  /// Lit le fichier via rootBundle, extrait les trkpt du premier trk,
  /// et calcule la distance cumulee pour chaque point.
  ///
  /// Retourne une liste vide si le fichier ne contient aucun track.
  static Future<List<TrackPoint>> parseFromAsset(String assetPath) async {
    final xmlString = await rootBundle.loadString(assetPath);
    return parseFromString(xmlString);
  }

  /// Parse un fichier GPX depuis une chaine XML.
  ///
  /// Methode utilitaire, utilisable aussi dans les tests
  /// sans avoir besoin de rootBundle.
  static List<TrackPoint> parseFromString(String xmlString) {
    final gpx = GpxReader().fromString(xmlString);

    if (gpx.trks.isEmpty) return [];

    final track = gpx.trks.first;
    final points = <TrackPoint>[];
    var cumulativeDistance = 0.0;

    for (final segment in track.trksegs) {
      for (final wpt in segment.trkpts) {
        final lat = wpt.lat;
        final lng = wpt.lon;
        final alt = wpt.ele;

        if (lat == null || lng == null) continue;

        // Calculer la distance depuis le point precedent
        if (points.isNotEmpty) {
          final prev = points.last;
          cumulativeDistance += GeoUtils.haversineDistance(
            prev.lat,
            prev.lng,
            lat.toDouble(),
            lng.toDouble(),
          );
        }

        points.add(TrackPoint(
          lat: lat.toDouble(),
          lng: lng.toDouble(),
          altitude: alt?.toDouble() ?? 0.0,
          distanceFromStart: cumulativeDistance,
        ));
      }
    }

    return points;
  }
}
