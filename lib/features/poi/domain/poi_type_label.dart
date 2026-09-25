import '../../../i18n/translations.g.dart';
import 'poi_type_config.dart';

/// Libellé TRADUIT d'un type de POI (LOT D, tâche 554).
///
/// POURQUOI CETTE FONCTION EXISTE : [PoiTypeStyle.labelKey] porte un libellé
/// ÉCRIT EN FRANÇAIS dans le registre (« Refuge », « Eau »…). Il sert de repli
/// pour les types exotiques, mais il ne se traduit pas — or StepWays sert cinq
/// langues. La table de correspondance vers `t.poi.*` existait déjà, PRIVÉE
/// dans `poi_info_sheet.dart` : elle est remontée ici pour que la légende de la
/// carte et la fiche POI ne divergent jamais sur le nom d'un même type.
///
/// Repli assumé sur [PoiTypeStyle.labelKey] pour un type sans clé de
/// traduction : mieux vaut le mot du registre qu'une case vide.
String poiTypeLabel(String type) {
  final poiT = t.poi;
  switch (type) {
    case 'water':
      return poiT.water;
    case 'refuge':
    case 'shelter':
      return poiT.shelter;
    case 'shop':
      return poiT.shop;
    case 'danger':
      return poiT.danger;
    case 'viewpoint':
      return poiT.viewpoint;
    case 'campsite':
      return poiT.campsite;
    case 'restaurant':
      return poiT.restaurant;
    case 'emergency':
      return poiT.emergency;
    case 'accommodation':
      return poiT.accommodation;
    case 'info':
      return poiT.info;
    default:
      return PoiTypeConfig.getStyle(type).labelKey;
  }
}

/// EXPLICATION d'un type de POI pour le guide de la carte (tâche 557).
///
/// POURQUOI ELLE EST SÉPARÉE DU LIBELLÉ : le nom (« Source ») sert partout —
/// légende, filtres, fiche. L'explication (« une source peut être à sec en
/// été : ne comptez pas dessus sans l'avoir vérifiée ») ne sert QUE dans le
/// guide, et elle dit ce que le nom ne dit pas : ce sur quoi on peut compter.
/// C'est le manque que la tâche 554 avait nommé et laissé ouvert — le guide
/// listait des noms sans explications, faute de clés traduites. Les clés
/// existent depuis la tâche 552 (`map.guide.poi.*`, cinq langues) : les voici
/// branchées.
///
/// Retourne `null` pour un type inconnu du guide : la ligne garde son nom et
/// perd son paragraphe, plutôt que d'afficher un texte emprunté à un autre type.
String? poiTypeGuide(String type) {
  final guide = t.map.guide.poi;
  switch (type) {
    case 'water':
      return guide.water;
    // `refuge` et `shelter` partagent une explication : ce sont deux noms du
    // même abri selon les sentiers, et le registre les distingue seulement par
    // l'icône.
    case 'refuge':
    case 'shelter':
      return guide.shelter;
    case 'accommodation':
      return guide.accommodation;
    case 'campsite':
      return guide.campsite;
    case 'shop':
      return guide.shop;
    case 'restaurant':
      return guide.restaurant;
    case 'viewpoint':
      return guide.viewpoint;
    case 'danger':
      return guide.danger;
    case 'emergency':
      return guide.emergency;
    case 'info':
      return guide.info;
    default:
      return null;
  }
}
