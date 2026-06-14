import 'package:flutter/material.dart';

import '../data/waypoint_service.dart';

/// Style visuel associe a un type de waypoint communautaire (F8A-04).
///
/// Icone Material, couleur, et cle de label i18n (sous le namespace
/// `waypoints.types.*`). Calque le pattern POI ([PoiTypeConfig]).
class WaypointTypeStyle {
  const WaypointTypeStyle({
    required this.icon,
    required this.color,
    required this.labelKey,
  });

  /// Icone Material pour ce type.
  final IconData icon;

  /// Couleur associee a ce type.
  final Color color;

  /// Cle de traduction courte (ex 'eau', 'ravitaillement').
  final String labelKey;
}

/// Configuration centralisee des types de waypoint FarOut-like (R1).
///
/// Registre statique extensible : chaque type connu a un style defini. Les
/// types inconnus obtiennent un fallback generique (place, gris) — jamais de
/// crash sur une valeur serveur inattendue.
class WaypointTypeConfig {
  WaypointTypeConfig._();

  static const Map<String, WaypointTypeStyle> _styles = {
    WaypointType.eau: WaypointTypeStyle(
      icon: Icons.water_drop,
      color: Color(0xFF1565C0),
      labelKey: 'eau',
    ),
    WaypointType.ravitaillement: WaypointTypeStyle(
      icon: Icons.shopping_basket,
      color: Color(0xFF2E7D32),
      labelKey: 'ravitaillement',
    ),
    WaypointType.danger: WaypointTypeStyle(
      icon: Icons.warning_amber_rounded,
      color: Color(0xFFC62828),
      labelKey: 'danger',
    ),
    WaypointType.camp: WaypointTypeStyle(
      icon: Icons.holiday_village,
      color: Color(0xFF558B2F),
      labelKey: 'camp',
    ),
    WaypointType.connectivite: WaypointTypeStyle(
      icon: Icons.signal_cellular_alt,
      color: Color(0xFF6A1B9A),
      labelKey: 'connectivite',
    ),
    WaypointType.jonction: WaypointTypeStyle(
      icon: Icons.alt_route,
      color: Color(0xFFE65100),
      labelKey: 'jonction',
    ),
  };

  static const _fallback = WaypointTypeStyle(
    icon: Icons.place,
    color: Color(0xFF616161),
    labelKey: 'autre',
  );

  /// Retourne le style pour un type donne (fallback generique si inconnu).
  static WaypointTypeStyle getStyle(String type) {
    return _styles[type] ??
        WaypointTypeStyle(
          icon: _fallback.icon,
          color: _fallback.color,
          labelKey: type,
        );
  }

  /// Tous les types connus (ordre d'affichage du panneau de filtres).
  static List<String> get allTypes => WaypointType.values;
}
