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
  // HUIT JOURS EST AJOUTE, ET CE N'EST PAS UN REGLAGE DE CONFORT (tache 853).
  //
  // CE CHAPITRE EST LE SEUL ENDROIT DU GR20 OU L'ALLURE CHANGE LE VERDICT, et
  // la frontiere tombe exactement entre sept et huit jours. A SEPT il est tres
  // difficile, et c'est l'ENCHAINEMENT qui le monte, pas une journee qui
  // casse : sa plus dure ne vaut qu'un indice de terrain de 27, mais
  // journees dures se suivent sans un jour pour respirer. A HUIT il est
  // difficile — la suite tombe a trois — et il le reste jusqu'a seize.
  //
  // LE SELECTEUR N'OFFRAIT QUE 5 ET 7, soit les deux seules allures tres
  // difficiles. Le client ne pouvait donc ni voir ni choisir la seule allure
  // qui change ce qu'on lui vend, alors que la fiche de ce chapitre le lui
  // annonce noir sur blanc. Un texte qui promet un cran que le selecteur
  // n'atteint pas est pire qu'un texte muet. Douze ferme la serie du cote
  // etale, pour que l'ecart d'INDICE entre les allures se lise d'un coup : de
  // 35 a cinq jours a 20 a seize, le sud repond a l'allure (tache 858).
  availableDurations: [5, 7, 8, 12],
  defaultDuration: 7,
  offlineFirst: true,
  hasPremium: false,
  parentTrailId: 'gr20',
  emergencyNumbers: kSecoursDuGr20,
  seedAssetsBase: 'assets/data/gr20-sud',
  accommodationsAssetPath: 'assets/data/gr20-sud.json',
  possibleNightsAssetPath: 'assets/data/gr20-sud/nuits_possibles.json',
  // LA FICHE DU CHAPITRE (tache 853) — le raisonnement est dans
  // [gr20NordTrailConfig], il n'est pas recopie. Ce qui est PROPRE au sud :
  // SA COUVERTURE EST LA SIENNE, le col de Bavella et ses aiguilles. Sans fiche
  // propre, la carte du catalogue du sud s'ouvrait sur la couverture du sentier
  // mere — c'est-a-dire sur le lac de Capitello, qui est dans le NORD : on
  // vendait le sud avec une photo de l'autre moitie.
  ficheAssetPath: 'assets/data/gr20-sud/fiche.json',
  // 2 021 m — mesure sur les 4 666 points de la trace de ce chapitre, contre
  // 2 578 m au nord. Le sud plafonne 557 m plus bas, et c'est l'une des deux
  // mesures qui separent vraiment les deux moities.
  maxAltitudeM: 2021,
  privacyPolicyUrl: StepwaysLegal.privacyPolicyUrl,
);
