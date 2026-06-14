import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../data/waypoint_service.dart';
import '../domain/waypoint_type_config.dart';

/// Couche de marqueurs des waypoints communautaires (F8A-04, FarOut R1).
///
/// Affiche un [MarkerLayer] flutter_map avec une icone par type de waypoint
/// (style via [WaypointTypeConfig]). Seuls les waypoints dont le type est dans
/// [visibleTypes] sont affiches (Comment Filtering FarOut). Au tap : [onTap].
///
/// ZERO logique reseau : ce widget recoit la liste deja lue du cache par le
/// provider parent (offline-first R3).
class WaypointsMapLayer extends StatelessWidget {
  const WaypointsMapLayer({
    super.key,
    required this.waypoints,
    required this.visibleTypes,
    this.onTap,
    this.markerSize = 38.0,
  });

  /// Waypoints disponibles (lus du cache local).
  final List<WaypointView> waypoints;

  /// Types actuellement visibles (filtre FarOut).
  final Set<String> visibleTypes;

  /// Callback au tap sur un waypoint.
  final void Function(WaypointView waypoint)? onTap;

  /// Taille des marqueurs en pixels.
  final double markerSize;

  @override
  Widget build(BuildContext context) {
    final filtered =
        waypoints.where((w) => visibleTypes.contains(w.type)).toList();

    if (filtered.isEmpty) {
      return const SizedBox.shrink();
    }

    return MarkerLayer(
      markers: filtered.map((wp) {
        final style = WaypointTypeConfig.getStyle(wp.type);
        return Marker(
          point: LatLng(wp.latitude, wp.longitude),
          width: markerSize,
          height: markerSize,
          child: Semantics(
            button: onTap != null,
            label: wp.titre,
            child: GestureDetector(
              key: ValueKey('waypoint-marker-${wp.id}'),
              onTap: onTap != null ? () => onTap!(wp) : null,
              child: Container(
                decoration: BoxDecoration(
                  color: style.color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    // Liseré renforcé pour une contribution communautaire.
                    color: wp.isCommunity ? Colors.amberAccent : Colors.white,
                    width: wp.isCommunity ? 3 : 2,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Icon(
                  style.icon,
                  color: Colors.white,
                  size: markerSize * 0.5,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
