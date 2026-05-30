import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/models/poi.dart';
import '../domain/poi_type_config.dart';

/// Couche de marqueurs POI pour la carte — filtre par type visible.
///
/// Affiche un [MarkerLayer] flutter_map v8 avec une icone par POI,
/// style via [PoiTypeConfig.getStyle] (String extensible, fallback generique).
/// Seuls les POIs dont le type est dans [visibleTypes] sont affiches.
class PoiMarkersLayer extends StatelessWidget {
  const PoiMarkersLayer({
    super.key,
    required this.pois,
    required this.visibleTypes,
    this.onPoiTap,
    this.markerSize = 36.0,
  });

  /// Liste complete des POIs disponibles.
  final List<PoiModel> pois;

  /// Types actuellement visibles. Seuls les POIs dont le type
  /// est dans ce Set sont affiches sur la carte.
  final Set<String> visibleTypes;

  /// Callback appele au tap sur un marqueur POI.
  final void Function(PoiModel poi)? onPoiTap;

  /// Taille des marqueurs en pixels.
  final double markerSize;

  @override
  Widget build(BuildContext context) {
    final filtered = pois.where((p) => visibleTypes.contains(p.type)).toList();

    if (filtered.isEmpty) {
      return const SizedBox.shrink();
    }

    return MarkerLayer(
      markers: filtered.map((poi) {
        final style = PoiTypeConfig.getStyle(poi.type);
        return Marker(
          point: LatLng(poi.lat, poi.lng),
          width: markerSize,
          height: markerSize,
          child: GestureDetector(
            onTap: onPoiTap != null ? () => onPoiTap!(poi) : null,
            child: Container(
              decoration: BoxDecoration(
                color: style.color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
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
        );
      }).toList(),
    );
  }
}
