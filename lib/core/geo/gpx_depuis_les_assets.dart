import 'package:flutter/services.dart' show rootBundle;

import '../../features/trek/data/gpx_parser.dart' as trek_gpx;
import 'track_point.dart';

// Re-export les nouveaux types pour les usages existants
export '../../features/trek/data/gpx_parser.dart'
    show GpxParseResult, GpxMetadata;

/// Lecture d'un GPX range dans les assets Flutter : la seule porte qui a
/// besoin de `rootBundle`, devant le parseur en Dart pur de
/// `features/trek/data/gpx_parser.dart`, auquel elle delegue tout.
///
/// Elle porte ce nom-la parce que c'est la couture qui justifie son
/// existence : `tool/publier_sentier.dart` depend du parseur pur, donc le
/// parseur ne peut pas toucher a `dart:ui`, donc l'acces aux assets vit ici
/// (ARB-645-04-c, decision de Christophe du 02/10/2026).
class GpxDepuisLesAssets {
  GpxDepuisLesAssets._();

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
