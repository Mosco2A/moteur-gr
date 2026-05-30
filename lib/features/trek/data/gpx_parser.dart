import 'package:gpx/gpx.dart';

import '../../../core/geo/geo_utils.dart';
import '../../../core/geo/track_point.dart';

/// Metadata extraites de l'en-tete GPX.
class GpxMetadata {
  const GpxMetadata({
    this.name,
    this.desc,
    this.author,
  });

  /// Nom du trace (balise <name> dans <metadata>)
  final String? name;

  /// Description du trace
  final String? desc;

  /// Auteur du trace
  final String? author;

  @override
  String toString() => 'GpxMetadata(name: $name, desc: $desc, author: $author)';
}

/// Resultat du parsing GPX complet.
///
/// Contient les metadata, les tracks (multi-segments),
/// et les waypoints du fichier GPX.
class GpxParseResult {
  const GpxParseResult({
    required this.metadata,
    required this.tracks,
    required this.waypoints,
  });

  /// Metadata du fichier GPX
  final GpxMetadata metadata;

  /// Tracks: chaque element est un segment (liste de TrackPoint).
  /// Multi-tracks et multi-segments sont geres a plat.
  final List<List<TrackPoint>> tracks;

  /// Waypoints du fichier GPX
  final List<TrackPoint> waypoints;

  /// Raccourci: tous les points de tous les tracks/segments a plat.
  List<TrackPoint> get allTrackPoints =>
      tracks.expand((segment) => segment).toList();

  /// Nombre total de points dans tous les tracks
  int get totalPoints => allTrackPoints.length;
}

/// Parseur de fichiers GPX.
///
/// Extrait metadata, tracks multi-segments et waypoints
/// depuis un contenu GPX XML.
class GpxParser {
  GpxParser._();

  /// Parse un contenu GPX et retourne un GpxParseResult complet.
  ///
  /// Gere multi-tracks et multi-segments (trkseg).
  /// Calcule les distances cumulees par segment.
  ///
  /// Leve une [FormatException] si le GPX est invalide.
  static GpxParseResult parse(String gpxContent) {
    if (gpxContent.trim().isEmpty) {
      throw const FormatException('Contenu GPX vide');
    }

    final Gpx gpx;
    try {
      gpx = GpxReader().fromString(gpxContent);
    } catch (e) {
      throw FormatException('GPX invalide: $e');
    }

    // --- Metadata ---
    final meta = gpx.metadata;
    final metadata = GpxMetadata(
      name: meta?.name,
      desc: meta?.desc,
      author: meta?.author?.name,
    );

    // --- Tracks (multi-segments) ---
    final tracks = <List<TrackPoint>>[];
    for (final trk in gpx.trks) {
      for (final seg in trk.trksegs) {
        final points = <TrackPoint>[];
        var cumulativeDistance = 0.0;

        for (final wpt in seg.trkpts) {
          final lat = wpt.lat;
          final lng = wpt.lon;
          final alt = wpt.ele;

          if (lat == null || lng == null) continue;

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

        if (points.isNotEmpty) {
          tracks.add(points);
        }
      }
    }

    // --- Waypoints ---
    final waypoints = <TrackPoint>[];
    for (final wpt in gpx.wpts) {
      final lat = wpt.lat;
      final lng = wpt.lon;
      final alt = wpt.ele;

      if (lat == null || lng == null) continue;

      waypoints.add(TrackPoint(
        lat: lat.toDouble(),
        lng: lng.toDouble(),
        altitude: alt?.toDouble() ?? 0.0,
        distanceFromStart: 0.0,
      ));
    }

    return GpxParseResult(
      metadata: metadata,
      tracks: tracks,
      waypoints: waypoints,
    );
  }
}
