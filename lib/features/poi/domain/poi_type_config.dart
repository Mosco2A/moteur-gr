import 'package:flutter/material.dart';

/// Style visuel associe a un type de POI.
///
/// Chaque type connu (water, refuge, shop, etc.) possede son propre style.
/// Les types inconnus utilisent un fallback generique via [PoiTypeConfig.getStyle].
class PoiTypeStyle {
  const PoiTypeStyle({
    required this.icon,
    required this.color,
    required this.labelKey,
  });

  /// Icone Material a afficher sur la carte et dans les listes.
  final IconData icon;

  /// Couleur du marqueur / badge.
  final Color color;

  /// Cle de traduction pour le libelle (ex: 'poi_type_water').
  final String labelKey;
}

/// Configuration extensible des types de POI.
///
/// Le type POI est un String libre (JAMAIS une enum) pour permettre
/// l'ajout de nouveaux types cote serveur sans mise a jour de l'app.
/// Les types connus ont un style dedie ; tout type inconnu recoit
/// un fallback generique (pin gris + type brut comme label).
class PoiTypeConfig {
  PoiTypeConfig._();

  /// Styles des types de POI connus.
  static const Map<String, PoiTypeStyle> _styles = {
    'water': PoiTypeStyle(
      icon: Icons.water_drop,
      color: Colors.blue,
      labelKey: 'poi_type_water',
    ),
    'refuge': PoiTypeStyle(
      icon: Icons.house,
      color: Colors.brown,
      labelKey: 'poi_type_refuge',
    ),
    'shop': PoiTypeStyle(
      icon: Icons.shopping_cart,
      color: Colors.green,
      labelKey: 'poi_type_shop',
    ),
    'accommodation': PoiTypeStyle(
      icon: Icons.hotel,
      color: Colors.purple,
      labelKey: 'poi_type_accommodation',
    ),
    'danger': PoiTypeStyle(
      icon: Icons.warning,
      color: Colors.red,
      labelKey: 'poi_type_danger',
    ),
    'viewpoint': PoiTypeStyle(
      icon: Icons.visibility,
      color: Colors.orange,
      labelKey: 'poi_type_viewpoint',
    ),
    'info': PoiTypeStyle(
      icon: Icons.info,
      color: Colors.grey,
      labelKey: 'poi_type_info',
    ),
  };

  /// Retourne le style pour un [type] de POI.
  ///
  /// Si le type est connu, retourne le style associe.
  /// Sinon, retourne un fallback generique : pin gris, label = type brut.
  static PoiTypeStyle getStyle(String type) {
    return _styles[type] ??
        PoiTypeStyle(
          icon: Icons.location_on,
          color: Colors.grey,
          labelKey: type,
        );
  }
}
