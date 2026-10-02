import 'package:flutter/material.dart';

import '../data/waypoint_service.dart';
import '../../../core/branding/stepways_icons.dart';
import '../../../core/theme/couleurs_semantiques.dart';

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
  final String icon;

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
      icon: StepwaysIcons.pluie,
      color: CouleursSemantiques.pointEau,
      labelKey: 'eau',
    ),
    WaypointType.ravitaillement: WaypointTypeStyle(
      icon: StepwaysIcons.panier,
      color: CouleursSemantiques.pointRavitaillement,
      labelKey: 'ravitaillement',
    ),
    WaypointType.danger: WaypointTypeStyle(
      icon: StepwaysIcons.danger,
      color: CouleursSemantiques.pointDanger,
      labelKey: 'danger',
    ),
    WaypointType.camp: WaypointTypeStyle(
      icon: StepwaysIcons.hebergement,
      color: CouleursSemantiques.pointBivouac,
      labelKey: 'camp',
    ),
    WaypointType.connectivite: WaypointTypeStyle(
      icon: StepwaysIcons.sansReseau,
      color: CouleursSemantiques.pointConnectivite,
      labelKey: 'connectivite',
    ),
    WaypointType.jonction: WaypointTypeStyle(
      icon: StepwaysIcons.itineraire,
      color: CouleursSemantiques.pointJonction,
      labelKey: 'jonction',
    ),
  };

  static const _fallback = WaypointTypeStyle(
    icon: StepwaysIcons.repere,
    color: CouleursSemantiques.pointInconnu,
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
