import 'package:flutter/material.dart';

/// Style visuel associe a un type de POI.
///
/// Icone Material, couleur, et cle de label i18n.
class PoiTypeStyle {
  const PoiTypeStyle({
    required this.icon,
    required this.color,
    required this.labelKey,
  });

  /// Icone Material pour ce type
  final IconData icon;

  /// Couleur associee a ce type
  final Color color;

  /// Cle de traduction pour le label (ex: 'water', 'refuge')
  final String labelKey;
}

/// Configuration centralisee des types de POI.
///
/// Registre statique extensible : chaque type connu a un style defini.
/// Les types inconnus obtiennent un fallback generique (location_on, gris).
class PoiTypeConfig {
  PoiTypeConfig._();

  /// Styles connus par type de POI (String extensible)
  static const Map<String, PoiTypeStyle> _styles = {
    'water': PoiTypeStyle(
      icon: Icons.water_drop,
      color: Color(0xFF1565C0),
      labelKey: 'Eau',
    ),
    'refuge': PoiTypeStyle(
      icon: Icons.house,
      color: Color(0xFF5D4037),
      labelKey: 'Refuge',
    ),
    'shelter': PoiTypeStyle(
      icon: Icons.house,
      color: Color(0xFF5D4037),
      labelKey: 'Refuge',
    ),
    'shop': PoiTypeStyle(
      icon: Icons.shopping_cart,
      color: Color(0xFF2E7D32),
      labelKey: 'Commerce',
    ),
    'accommodation': PoiTypeStyle(
      icon: Icons.hotel,
      color: Color(0xFF6A1B9A),
      labelKey: 'Hebergement',
    ),
    'danger': PoiTypeStyle(
      icon: Icons.warning,
      color: Color(0xFFC62828),
      labelKey: 'Danger',
    ),
    'viewpoint': PoiTypeStyle(
      icon: Icons.visibility,
      color: Color(0xFFE65100),
      labelKey: 'Point de vue',
    ),
    'info': PoiTypeStyle(
      icon: Icons.info,
      color: Color(0xFF616161),
      labelKey: 'Information',
    ),
    'campsite': PoiTypeStyle(
      icon: Icons.holiday_village,
      color: Color(0xFF558B2F),
      labelKey: 'Bivouac',
    ),
    'restaurant': PoiTypeStyle(
      icon: Icons.restaurant,
      color: Color(0xFFE65100),
      labelKey: 'Restaurant',
    ),
    'emergency': PoiTypeStyle(
      icon: Icons.local_hospital,
      color: Color(0xFFC62828),
      labelKey: 'Urgence',
    ),
  };

  /// Style par defaut pour les types inconnus
  static const _fallback = PoiTypeStyle(
    icon: Icons.location_on,
    color: Color(0xFF616161),
    labelKey: 'POI',
  );

  /// Retourne le style pour un type donne.
  /// Types connus: water, refuge, shelter, shop, accommodation,
  /// danger, viewpoint, info, campsite, restaurant, emergency.
  /// Types inconnus: fallback generique (location_on, gris, type brut).
  static PoiTypeStyle getStyle(String type) {
    return _styles[type] ?? PoiTypeStyle(
      icon: _fallback.icon,
      color: _fallback.color,
      labelKey: type,
    );
  }

  /// Liste de tous les types connus
  static Set<String> get knownTypes => _styles.keys.toSet();
}
