import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Composant de trace GPX affichant une polyline sur la carte.
///
/// Widget stateless qui retourne un [PolylineLayer] flutter_map v8
/// avec une seule [Polyline] construite a partir des points fournis.
///
/// La couleur est parametrable (defaut bleu) — le rouge est reserve
/// au GR20, le moteur generique utilise un bleu neutre.
class TraceLayer extends StatelessWidget {
  const TraceLayer({
    super.key,
    required this.points,
    this.color = defaultColor,
    this.strokeWidth = defaultStrokeWidth,
  });

  /// Points du trace GPX a afficher.
  final List<LatLng> points;

  /// Couleur du trace (defaut bleu neutre, PAS rouge GR20).
  final Color color;

  /// Epaisseur du trait en pixels.
  final double strokeWidth;

  /// Couleur par defaut : bleu neutre.
  static const Color defaultColor = Color(0xFF1565C0);

  /// Epaisseur par defaut du trace en pixels.
  static const double defaultStrokeWidth = 4.0;

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
