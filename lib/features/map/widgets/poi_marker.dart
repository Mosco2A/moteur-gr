import 'package:flutter/material.dart';

import '../../../core/models/poi.dart';

/// Widget marqueur personnalisé pour un point d'intérêt sur la carte.
///
/// Affiche un cercle coloré avec une icône blanche au centre.
/// Chaque type de POI a sa propre couleur et icône Material.
class PoiMarker extends StatelessWidget {
  const PoiMarker({super.key, required this.type, this.size = 36});

  /// Type du POI qui détermine l'icône et la couleur
  final PoiType type;

  /// Taille totale du marqueur en pixels
  final double size;

  /// Retourne l'icône Material associée au type de POI.
  static IconData iconFor(PoiType type) {
    return switch (type) {
      PoiType.shelter => Icons.house,
      PoiType.water => Icons.water_drop,
      PoiType.viewpoint => Icons.visibility,
      PoiType.campsite => Icons.holiday_village,
      PoiType.restaurant => Icons.restaurant,
      PoiType.emergency => Icons.local_hospital,
      PoiType.danger => Icons.warning,
      PoiType.shop => Icons.shopping_bag,
    };
  }

  /// Retourne la couleur associée au type de POI.
  static Color colorFor(PoiType type) {
    return switch (type) {
      PoiType.shelter => const Color(0xFF5D4037),
      PoiType.water => const Color(0xFF1565C0),
      PoiType.viewpoint => const Color(0xFF2E7D32),
      PoiType.campsite => const Color(0xFF558B2F),
      PoiType.restaurant => const Color(0xFFE65100),
      PoiType.emergency => const Color(0xFFC62828),
      PoiType.danger => const Color(0xFFEF6C00),
      PoiType.shop => const Color(0xFF6A1B9A),
    };
  }

  @override
  Widget build(BuildContext context) {
    final color = colorFor(type);
    final icon = iconFor(type);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
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
        icon,
        color: Colors.white,
        size: size * 0.5,
      ),
    );
  }
}
