/// Le registre des types de point d'interet : une icone, une couleur et un
/// libelle par type, avec repli generique sur l'inconnu.
library;

import 'package:flutter/material.dart';
import '../../core/branding/stepways_icons.dart';
import '../../core/theme/couleurs_semantiques.dart';

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
  final String icon;

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
      icon: StepwaysIcons.pluie,
      color: CouleursSemantiques.pointEau,
      labelKey: 'Eau',
    ),
    'refuge': PoiTypeStyle(
      icon: StepwaysIcons.hebergement,
      color: CouleursSemantiques.pointRefuge,
      labelKey: 'Refuge',
    ),
    'shelter': PoiTypeStyle(
      icon: StepwaysIcons.hebergement,
      color: CouleursSemantiques.pointRefuge,
      labelKey: 'Refuge',
    ),
    'shop': PoiTypeStyle(
      icon: StepwaysIcons.panier,
      color: CouleursSemantiques.pointRavitaillement,
      labelKey: 'Commerce',
    ),
    'accommodation': PoiTypeStyle(
      icon: StepwaysIcons.hebergement,
      color: CouleursSemantiques.pointHebergement,
      labelKey: 'Hebergement',
    ),
    'danger': PoiTypeStyle(
      icon: StepwaysIcons.danger,
      color: CouleursSemantiques.pointDanger,
      labelKey: 'Danger',
    ),
    'viewpoint': PoiTypeStyle(
      icon: StepwaysIcons.oeil,
      color: CouleursSemantiques.pointPointDeVue,
      labelKey: 'Point de vue',
    ),
    'info': PoiTypeStyle(
      icon: StepwaysIcons.info,
      color: CouleursSemantiques.pointInformation,
      labelKey: 'Information',
    ),
    'campsite': PoiTypeStyle(
      icon: StepwaysIcons.hebergement,
      color: CouleursSemantiques.pointBivouac,
      labelKey: 'Bivouac',
    ),
    'restaurant': PoiTypeStyle(
      icon: StepwaysIcons.restauration,
      color: CouleursSemantiques.pointRestaurant,
      labelKey: 'Restaurant',
    ),
    'emergency': PoiTypeStyle(
      icon: StepwaysIcons.secours,
      color: CouleursSemantiques.pointUrgence,
      labelKey: 'Urgence',
    ),
  };

  /// Style par defaut pour les types inconnus
  static const _fallback = PoiTypeStyle(
    icon: StepwaysIcons.repere,
    color: CouleursSemantiques.pointInconnu,
    labelKey: 'POI',
  );

  /// Retourne le style pour un type donne.
  /// Types connus: water, refuge, shelter, shop, accommodation,
  /// danger, viewpoint, info, campsite, restaurant, emergency.
  /// Types inconnus: fallback generique (location_on, gris, type brut).
  static PoiTypeStyle getStyle(String type) {
    return _styles[type] ??
        PoiTypeStyle(
          icon: _fallback.icon,
          color: _fallback.color,
          labelKey: type,
        );
  }

  /// Liste de tous les types connus
  static Set<String> get knownTypes => _styles.keys.toSet();

  /// Types de POI qui constituent un HEBERGEMENT d'etape.
  ///
  /// Remontee ici au LOT D (tache 554) : la fiche d'etape en avait une copie
  /// PRIVEE, et la liste des points de l'etape sur la carte en aurait fait une
  /// seconde. Deux definitions du mot « hebergement » finissent toujours par
  /// divergent — un refuge compte ici, pas la. Une seule, donc.
  ///
  /// Generique multi-sentiers : couvre le libelle du socle donnees (`shelter`)
  /// et ses synonymes du registre (`refuge`, `accommodation`, `campsite`).
  static const Set<String> accommodationTypes = {
    'shelter',
    'refuge',
    'accommodation',
    'campsite',
  };

  /// Types de POI qui designent un POINT D'EAU.
  ///
  /// Un seul type a ce jour, mais nomme pour la meme raison que
  /// [accommodationTypes] : la carte et la fiche d'etape lisent la meme regle.
  static const Set<String> waterTypes = {'water'};
}
