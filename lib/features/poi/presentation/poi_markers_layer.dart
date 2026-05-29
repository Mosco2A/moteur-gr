import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/data/database.dart';
import '../domain/poi_type_config.dart';

/// Taille par defaut d'un marqueur POI.
const _kPoiMarkerSize = 32.0;

/// Layer FlutterMap v8 affichant un marqueur par POI visible.
///
/// Filtre les POIs selon [visibleTypes] : seuls les POIs dont le type
/// est present dans le Set sont affiches. L'icone et la couleur de
/// chaque marqueur sont fournis par [PoiTypeConfig.getStyle].
///
/// Les types inconnus recoivent automatiquement le fallback generique
/// (pin gris) grace a PoiTypeConfig — ZERO enum, extensible cote serveur.
class PoiMarkersLayer extends StatelessWidget {
  const PoiMarkersLayer({
    super.key,
    required this.pois,
    required this.visibleTypes,
    required this.onPoiTap,
  });

  /// Liste complete des POIs disponibles (non filtrée).
  final List<Poi> pois;

  /// Types de POI actuellement visibles.
  /// Seuls les POIs dont [Poi.type] est dans ce Set sont affiches.
  final Set<String> visibleTypes;

  /// Callback appele au tap sur un marqueur POI.
  final void Function(Poi poi) onPoiTap;

  /// Retourne la sous-liste des POIs dont le type est visible.
  @visibleForTesting
  static List<Poi> filterVisible(List<Poi> pois, Set<String> visibleTypes) {
    return pois.where((poi) => visibleTypes.contains(poi.type)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final visible = filterVisible(pois, visibleTypes);
    return MarkerLayer(
      markers: [
        for (final poi in visible) _buildMarker(poi),
      ],
    );
  }

  /// Construit un [Marker] FlutterMap v8 pour un POI.
  ///
  /// Icone et couleur resolues via [PoiTypeConfig.getStyle].
  Marker _buildMarker(Poi poi) {
    final style = PoiTypeConfig.getStyle(poi.type);

    return Marker(
      point: LatLng(poi.lat, poi.lng),
      width: _kPoiMarkerSize,
      height: _kPoiMarkerSize,
      child: GestureDetector(
        onTap: () => onPoiTap(poi),
        child: Container(
          width: _kPoiMarkerSize,
          height: _kPoiMarkerSize,
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
            size: 18,
          ),
        ),
      ),
    );
  }
}
