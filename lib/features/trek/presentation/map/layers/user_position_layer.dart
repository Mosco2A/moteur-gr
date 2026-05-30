import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../map/widgets/user_position_marker.dart';

/// Couche carte position utilisateur -- point bleu pulsant + cercle precision.
///
/// Compose un [CircleLayer] (cercle de precision GPS bleu translucide)
/// et un [MarkerLayer] (point bleu pulsant via [UserPositionMarker]).
/// Si [position] est null, retourne un [SizedBox.shrink] (invisible).
/// Le cercle de precision utilise [accuracy] en metres (rayon reel sur la carte).
class UserPositionLayer extends StatelessWidget {
  const UserPositionLayer({
    super.key,
    required this.position,
    this.accuracy,
    this.markerSize = 20.0,
    this.accuracyColor = const Color(0x301976D2),
    this.accuracyBorderColor = const Color(0x601976D2),
  });

  /// Position GPS de l utilisateur. Si null, le widget est invisible.
  final LatLng? position;

  /// Precision GPS en metres. Si null ou <= 0, le cercle de precision
  /// n est pas affiche (seul le point bleu reste visible).
  final double? accuracy;

  /// Taille du marqueur bleu en pixels.
  final double markerSize;

  /// Couleur de remplissage du cercle de precision (bleu translucide).
  final Color accuracyColor;

  /// Couleur de bordure du cercle de precision.
  final Color accuracyBorderColor;

  @override
  Widget build(BuildContext context) {
    final pos = position;
    if (pos == null) {
      return const SizedBox.shrink();
    }

    final hasAccuracy = accuracy != null && accuracy! > 0;

    return Stack(
      children: [
        // Cercle de precision GPS (rayon en metres sur la carte)
        if (hasAccuracy)
          CircleLayer(
            circles: [
              CircleMarker(
                point: pos,
                radius: accuracy!,
                useRadiusInMeter: true,
                color: accuracyColor,
                borderStrokeWidth: 1.5,
                borderColor: accuracyBorderColor,
              ),
            ],
          ),

        // Point bleu pulsant
        MarkerLayer(
          markers: [
            Marker(
              point: pos,
              width: markerSize * 3,
              height: markerSize * 3,
              child: UserPositionMarker(size: markerSize),
            ),
          ],
        ),
      ],
    );
  }
}
