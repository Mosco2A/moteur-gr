import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Composant trace GPX - affiche une polyline sur la carte.
///
/// Encapsule un [PolylineLayer] flutter_map v8 avec une seule [Polyline].
/// Couleur configurable (defaut bleu), epaisseur configurable.
/// Utilise directement des [LatLng] (pas de TrackPoint) pour rester
/// decouple du modele metier.
class TraceLayer extends StatelessWidget {
  const TraceLayer({
    super.key,
    required this.points,
    this.color = Colors.blue,
    this.strokeWidth = 4.0,
  });

  /// Points GPS du trace a afficher.
  final List<LatLng> points;

  /// Couleur du trace. Defaut bleu (pas rouge GR20).
  final Color color;

  /// Epaisseur du trait en pixels.
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return PolylineLayer(
      polylines: [
        Polyline(
          points: points,
          color: color,
          strokeWidth: strokeWidth,
          strokeCap: StrokeCap.round,
          strokeJoin: StrokeJoin.round,
        ),
      ],
    );
  }
}
