import 'package:flutter/services.dart' show rootBundle;

import '../../features/trek/data/gpx_parser.dart' as trek_gpx;
import 'track_point.dart';

// Re-export les nouveaux types pour les usages existants
export '../../features/trek/data/gpx_parser.dart'
    show GpxParseResult, GpxMetadata;

/// Parseur de fichiers GPX depuis les assets de l'application.
///
/// Conserve l'API historique (parseFromAsset, parseFromString)
/// tout en deleguant au nouveau GpxParser (features/trek/data/).
///
/// Les nouveaux usages doivent utiliser [trek_gpx.GpxParser.parse()]
/// pour acceder aux metadata et multi-segments.
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
  /// Delegue au nouveau GpxParser et aplatit les segments.
  /// Pour acceder aux metadata/multi-segments, utiliser
  /// [trek_gpx.GpxParser.parse()] directement.
  static List<TrackPoint> parseFromString(String xmlString) {
    final result = trek_gpx.GpxParser.parse(xmlString);
    return result.allTrackPoints;
  }

  /// Parse complet avec metadata et multi-segments.
  ///
  /// Raccourci vers [trek_gpx.GpxParser.parse()].
  static trek_gpx.GpxParseResult parse(String gpxContent) {
    return trek_gpx.GpxParser.parse(gpxContent);
  }
}
