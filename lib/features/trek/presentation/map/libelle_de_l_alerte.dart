/// CE QUE LE BANDEAU DE RAVITAILLEMENT DIT AU MARCHEUR (tache 834).
///
/// Un fichier a part, et pour deux raisons. La premiere est le plafond de
/// 500 lignes de `map_overlays.dart` (garde `taille_et_rangement_645`), que ces
/// libelles faisaient franchir. La seconde est meilleure : le choix du mot est
/// une decision PURE — une alerte entre, une phrase sort — et une fonction pure
/// se teste sans monter un ecran ni simuler un GPS.
library;

import '../../../../core/utils/nombre_en_clair.dart';
import '../../../../i18n/translations.g.dart';
import '../../../map/map_facade.dart' show SupplyGapAlert, SupplyGapKind;

/// Le titre du bandeau, selon ce qui manque : de l'eau, ou des vivres.
String titreDeLAlerte(SupplyGapAlert alerte) =>
    alerte.kind == SupplyGapKind.water
    ? t.map.waterGapTitle
    : t.shop.limitedTitle;

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
/// faux.
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
