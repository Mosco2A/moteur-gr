/// Le registre des types de point d'interet : une icone, une couleur et un
/// libelle par type, avec repli generique sur l'inconnu.
library;

import 'package:flutter/material.dart';
import '../../core/branding/stepways_icons.dart';
import '../../core/models/water_action.dart';
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
    // UN POINT D'EAU SE DESSINE EN GOUTTE, PAS EN AVERSE (tache 772).
    //
    // Retour de Christophe, deux fois plutot qu'une : « L'icone source est
    // toujours un nuage avec de la pluie ???? ».
    //
    // CE QUI ETAIT EN CAUSE, MESURE AVANT DE TOUCHER QUOI QUE CE SOIT : le
    // FICHIER n'avait rien a se reprocher. `assets/icons/point-eau.svg` dessine
    // bien une goutte, et il existait depuis le depart — il n'etait simplement
    // appele NULLE PART. C'est la clef qui avait glisse : le point d'eau
    // portait le dessin de la METEO (`pluie.svg`, un nuage et trois gouttes),
    // tout en gardant la couleur `pointEau`. Le bleu disait « eau », le trace
    // disait « il pleut ».
    'water': PoiTypeStyle(
      icon: StepwaysIcons.pointEau,
      color: CouleursSemantiques.pointEau,
      labelKey: 'Eau',
    ),
    'refuge': PoiTypeStyle(
      icon: StepwaysIcons.hebergement,
      color: CouleursSemantiques.hutPoint,
      labelKey: 'Refuge',
    ),
    'shelter': PoiTypeStyle(
      icon: StepwaysIcons.hebergement,
      color: CouleursSemantiques.hutPoint,
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
      color: CouleursSemantiques.bivouacPoint,
      labelKey: 'Bivouac',
    ),
    'restaurant': PoiTypeStyle(
      icon: StepwaysIcons.restauration,
      color: CouleursSemantiques.pointRestaurant,
      labelKey: 'Restaurant',
    ),
    'emergency': PoiTypeStyle(
      icon: StepwaysIcons.emergency,
      color: CouleursSemantiques.emergencyPoint,
      labelKey: 'Urgence',
    ),
  };

  /// UN POINT D'EAU SE DESSINE PAR LE GESTE A FAIRE (tache 846).
  ///
  /// POURQUOI LE DESSIN DOIT CHANGER, ET PAS SEULEMENT LE TEXTE. On arrive
  /// assoiffe devant un point d'eau, et dans cet etat on ne lit pas les
  /// etiquettes : on reconnait une forme. Une source thermale qui portait la
  /// goutte bleue de la fontaine etait donc une invitation a boire, quoi
  /// qu'ecrive sa fiche.
  ///
  /// LES TROIS ECARTS, ET CE QU'ILS DISENT. La goutte reste la goutte dans les
  /// trois cas — c'est de l'eau, et ca doit se voir de loin. Ce qui change est
  /// l'interieur du dessin et la teinte :
  ///  * A FILTRER : un tamis dans la goutte, un bleu-vert. De l'eau utilisable,
  ///    avec un geste.
  ///  * A TRAITER OU FAIRE BOUILLIR : la meme teinte — c'est aussi de l'eau
  ///    utilisable avec un geste — mais le rechaud, parce que le geste n'est
  ///    pas le meme et qu'un filtre n'y repond pas.
  ///  * NE PAS BOIRE : la goutte barree, en rouge. Pas une nuance d'eau : un
  ///    refus.
  ///
  /// BOIRE TEL QUEL N'EST PAS DANS CETTE TABLE, et c'est voulu : une fontaine
  /// garde EXACTEMENT le dessin et la couleur qu'elle avait: rien a signaler,
  /// rien a changer, aucune carte existante modifiee pour rien.
  static const Map<WaterAction, PoiTypeStyle> _stylesDeLEau = {
    WaterAction.filter: PoiTypeStyle(
      icon: StepwaysIcons.pointEauAFiltrer,
      color: CouleursSemantiques.pointEauAFiltrer,
      labelKey: 'Eau a filtrer',
    ),
    WaterAction.treatOrBoil: PoiTypeStyle(
      icon: StepwaysIcons.rechaud,
      color: CouleursSemantiques.pointEauAFiltrer,
      labelKey: 'Eau a traiter',
    ),
    WaterAction.doNotDrink: PoiTypeStyle(
      icon: StepwaysIcons.pointEauInterdit,
      color: CouleursSemantiques.pointEauNonPotable,
      labelKey: 'Eau non potable',
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
  ///
  /// [waterAction] — LE GESTE A FAIRE, quand l'appelant tient le point et pas
  /// seulement son type. Il est IGNORE hors d'un point d'eau : l'appelant peut
  /// donc le passer sans se demander si le type s'y prete, et c'est ce registre
  /// — seul detenteur de [waterTypes] — qui tranche. Absent, un point d'eau
  /// garde le dessin de la fontaine, comme avant la tache 846.
  static PoiTypeStyle getStyle(String type, {WaterAction? waterAction}) {
    if (waterAction != null && waterTypes.contains(type)) {
      final parLeGeste = _stylesDeLEau[waterAction];
      if (parLeGeste != null) return parLeGeste;
    }
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
