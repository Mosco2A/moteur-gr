/// LE CHAPITRE SUD DU GR20 — un sentier COMPLET, vendu separement du nord.
library;

import '../branding/stepways_legal.dart';
import 'gr20_trail_config.dart';
import 'trail_config.dart';

/// Configuration du chapitre SUD du GR20 (Vizzavona vers Conca).
///
/// LE RAISONNEMENT COMPLET EST DANS [gr20NordTrailConfig], et il n'est pas
/// recopie ici : la decision de Christophe du 15/10, la regle CH-11 (un
/// chapitre est un sentier complet), la coupe a Vizzavona et l'origine des
/// chiffres y sont expliquees une fois. Ce fichier ne porte que ce qui est
/// PROPRE au sud.
///
/// SEPT ETAPES, DONC SEPT ETAPES A PAYER. Neuf au nord plus sept au sud font
/// seize : exactement le prix du sentier entier. Aucune remise pour qui prend
/// les deux, aucune penalite pour qui n'en prend qu'un — c'est la somme des
/// etapes, prelevee sur la cagnotte, et rien d'autre.
///
/// MEME LONGUEUR QUE LE NORD, PRESQUE MOITIE MOINS DE MONTEE. 91,79 km contre
/// 91,80, mais 4 243 m de D+ contre 7 401. C'est le chapitre le plus accessible
/// des deux, et c'est une information qui vaut d'etre lue avant de choisir : a
/// prix d'etapes presque egal, l'effort ne l'est pas du tout.
///
/// IL COMMENCE A VIZZAVONA, QUI N'EST PAS UNE DE SES NUITS. Vizzavona est
/// l'ARRIVEE du chapitre nord — donc une de ses quinze nuits — et le DEPART du
/// sud : on y dort avant de partir, comme a Calenzana pour le sentier entier.
/// C'est ce qui garantit que les trente et une nuits du GR20 se repartissent
/// sans perte ni doublon : quinze au nord, seize au sud.
const gr20SudTrailConfig = TrailConfig(
  id: 'gr20-sud',
  name: 'GR20 Sud',
  // LE NOM DU PRODUIT EST A ARBITRER — voir la note de [gr20NordTrailConfig]
  // sur la gate G1 du design #101920 et sur l'article L.713-6.
  displayName: 'GR20 Sud',
  tagline: 'La moitie sud de la Corse, de Vizzavona a Conca',
  totalStages: 7,
  // 91,79 km = somme des sept etapes mesurees ; la tranche de trace mesure
  // 91,788 km. Nord plus sud font 183,585 km, soit la trace entiere au metre.
  totalDistanceKm: 91.79,
  totalElevationGain: 4243,
  region: 'Corse',
  country: 'France',
  primaryColorValue: 0xFF37474F,
  secondaryColorValue: 0xFFEF6C00,
  gpxAssetPath: 'assets/data/gr20-sud/track.gpx',
  directions: ['NS', 'SN'],
  availableDurations: [5, 7],
  defaultDuration: 7,
  offlineFirst: true,
  hasPremium: false,
  parentTrailId: 'gr20',
  emergencyNumbers: kSecoursDuGr20,
  seedAssetsBase: 'assets/data/gr20-sud',
  accommodationsAssetPath: 'assets/data/gr20-sud.json',
  possibleNightsAssetPath: 'assets/data/gr20-sud/nuits_possibles.json',
  privacyPolicyUrl: StepwaysLegal.privacyPolicyUrl,
);
