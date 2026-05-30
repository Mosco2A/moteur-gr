import 'package:flutter/material.dart';

import '../../poi/domain/poi_type_config.dart';

/// Widget marqueur personnalise pour un point d'interet sur la carte.
///
/// Affiche un cercle colore avec une icone blanche au centre.
/// Chaque type de POI a sa propre couleur et icone via PoiTypeConfig.
class PoiMarker extends StatelessWidget {
  const PoiMarker({super.key, required this.type, this.size = 36});

  /// Type du POI (String extensible)
  final String type;

  /// Taille totale du marqueur en pixels
  final double size;

  /// Retourne l'icone Material associee au type de POI.
  static IconData iconFor(String type) {
    return PoiTypeConfig.getStyle(type).icon;
  }

  /// Retourne la couleur associee au type de POI.
  static Color colorFor(String type) {
    return PoiTypeConfig.getStyle(type).color;
  }

  @override
  Widget build(BuildContext context) {
    final style = PoiTypeConfig.getStyle(type);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: style.color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        style.icon,
        color: Colors.white,
        size: size * 0.5,
      ),
    );
  }
}
