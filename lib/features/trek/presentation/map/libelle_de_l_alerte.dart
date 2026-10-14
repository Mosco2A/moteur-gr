/// CE QUE LE BANDEAU DE RAVITAILLEMENT DIT AU MARCHEUR (tache 834).
///
/// Un fichier a part, et pour deux raisons. La premiere est le plafond de
/// 500 lignes de `map_overlays.dart` (garde `taille_et_rangement_645`), que ces
/// libelles faisaient franchir. La seconde est meilleure : le choix du mot est
/// une decision PURE — une alerte entre, une phrase sort — et une fonction pure
/// se teste sans monter un ecran ni simuler un GPS.
library;

import '../../../../core/models/water_action.dart';
import '../../../../core/utils/nombre_en_clair.dart';
import '../../../../i18n/translations.g.dart';
import '../../../map/map_facade.dart' show SupplyGapAlert, SupplyGapKind;

/// LE TITRE DU BANDEAU : ce qui manque, ET LE GESTE A FAIRE (tache 846).
///
/// Pour les vivres, un seul titre. Pour l'eau, le titre PORTE LE GESTE : «
/// Points d'eau a filtrer » plutot que « Points d'eau limites » quand l'eau
/// retrouvee se filtre.
///
/// POURQUOI DANS LE TITRE, ET C'EST UNE MESURE QUI L'A DECIDE. Le geste avait
/// d'abord ete ecrit en fin de corps de texte, en une phrase de plus
/// (« Le prochain est a filtrer. »). MESURE AU BANC : sur un telephone de
/// 320 points — le plus petit encore vendu — cette phrase coutait 32 POINTS DE
/// HAUTEUR, soit DEUX lignes. Or le bandeau partage sa [Column] avec la
/// pastille SOS et se trouve au-dessus d'elle : trente-deux points, c'est le
/// SOS repousse vers le bas pendant la marche. Dans le titre, le geste coute
/// ZERO : « a filtrer » remplace « limites », la ligne existait deja.
///
/// ET C'EST AUSSI LE MEILLEUR ENDROIT. Le titre est en gras, c'est ce qu'on
/// lit en premier et parfois la seule chose qu'on lit. Rien n'est perdu de la
/// rarete : le corps du texte dit toujours « Dernier point d'eau avant
/// 2 etapes et 28,6 km ».
///
/// IL SE TAIT QUAND IL N'Y A RIEN A FAIRE. Une fontaine qui se boit telle
/// quelle garde le titre d'avant — le silence est alors l'information juste. Et
/// une eau « ne pas boire » n'apparait jamais ici : elle ne compte deja plus
/// comme de l'eau en amont ([WaterAction.donneDeLEau]), donc l'alerte ne
/// l'annonce pas.
String titreDeLAlerte(SupplyGapAlert alerte) {
  if (alerte.kind != SupplyGapKind.water) return t.shop.limitedTitle;
  return switch (alerte.waterAction) {
    WaterAction.filter => t.map.waterGapTitleFilter,
    WaterAction.treatOrBoil => t.map.waterGapTitleTreat,
    WaterAction.drinkAsIs ||
    WaterAction.doNotDrink ||
    null => t.map.waterGapTitle,
  };
}

/// LE TEXTE DU BANDEAU, ET IL DIT LA TAILLE DU TROU.
///
/// « Dernier ravitaillement avant 5 etapes et 52,5 km » fait charger deux kilos
/// de plus ; « attention ravitaillement » ne fait rien. Une etape du Mare a
/// Mare Centre mesure de 8,1 a 19,9 km : le nombre d'etapes, seul, ne dit pas
/// l'effort.
///
/// QUATRE LIBELLES ET PAS UN DE PLUS : deux sujets (l'eau, les vivres) fois
/// deux etats de la donnee (portee connue, portee inconnue). Quand les
/// distances d'etape manquent, on parle en etapes SANS inventer un kilometrage
/// — et le libelle de l'eau ne parle jamais de commerce, parce que ce serait
/// faux. CES QUATRE PHRASES SONT INTACTES DEPUIS LA TACHE 834 : le geste de la
/// 846 est passe dans le TITRE ([titreDeLAlerte]) et n'en a reecrit aucune.
///
/// LE SEPARATEUR DECIMAL SE LIT DANS LA LANGUE, jamais dans le code
/// ([nombreEnClair], tache 835) : « 52,5 km » en francais, « 52.5 km » en
/// anglais.
String texteDeLAlerte(SupplyGapAlert alerte) {
  final km = alerte.km;
  final eau = alerte.kind == SupplyGapKind.water;
  if (km == null) {
    return eau
        ? t.map.waterGapStages(n: alerte.gap)
        : t.shop.gapLong(n: alerte.gap);
  }
  final portee = nombreEnClair(km, LocaleSettings.currentLocale.languageCode);
  return eau
      ? t.map.waterGapRange(n: alerte.gap, km: portee)
      : t.map.supplyGapRange(n: alerte.gap, km: portee);
}
