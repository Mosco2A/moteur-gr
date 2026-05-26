import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/geo/track_point.dart';

/// Construit le PolylineLayer pour afficher le tracé du sentier.
///
/// Convertit les TrackPoints en LatLng pour flutter_map,
/// applique la couleur et le style du tracé.
class TrailPolyline {
  TrailPolyline._();

  /// Épaisseur par défaut du tracé en pixels
  static const double defaultStrokeWidth = 4.0;

  /// Construit un PolylineLayer depuis une liste de TrackPoints.
  ///
  /// [points] — liste des points du tracé (simplifiés ou bruts)
  /// [color] — couleur du tracé (couleur primaire du sentier)
  /// [strokeWidth] — épaisseur du trait (défaut 4.0)
  static PolylineLayer build({
    required List<TrackPoint> points,
    required Color color,
    double strokeWidth = defaultStrokeWidth,
  }) {
    final latLngPoints = points
        .map((tp) => LatLng(tp.lat, tp.lng))
        .toList(growable: false);

    return PolylineLayer(
      polylines: [
        Polyline(
          points: latLngPoints,
          color: color,
          strokeWidth: strokeWidth,
          strokeCap: StrokeCap.round,
          strokeJoin: StrokeJoin.round,
        ),
      ],
    );
  }
}
