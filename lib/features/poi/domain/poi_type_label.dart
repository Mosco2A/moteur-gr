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
    default:
      return PoiTypeConfig.getStyle(type).labelKey;
  }
}
