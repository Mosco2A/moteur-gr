/// Le GR20, et le premier sentier du depot dont AUCUN chiffre n'a ete saisi a
/// la main. Le moteur reste generique : ce fichier n'est qu'une DONNEE.
library;

import '../branding/stepways_legal.dart';
import 'trail_config.dart';

/// Les secours regionaux du GR20, PARTAGES PAR LE SENTIER ET SES CHAPITRES.
///
/// Secours regionaux fournis par la config (jamais hardcodes dans le moteur).
/// Le 112 est UNIVERSEL et vit dans le moteur
/// (`kUniversalEmergencyContacts`) : il n'est pas duplique ici.
///
/// CES DEUX NUMEROS SONT CEUX DU MARE A MARE CENTRE, et ils valent pour le GR20
/// POUR UNE RAISON VERIFIABLE : le PGHM de Corte couvre le secours en montagne
/// de toute la Corse, et le Parc naturel regional de Corse gere les refuges des
/// deux sentiers. Aucun numero non source n'est ajoute — la tache 647 a retire
/// un numero de secours dont la source n'avait jamais pu etre etablie, et un
/// numero faux coute le temps qu'on met a comprendre qu'il est faux, au pire
/// moment.
///
/// POURQUOI UNE CONSTANTE NOMMEE PLUTOT QUE TROIS LISTES (tache 841). Les deux
/// chapitres traversent exactement le meme terrain et relevent exactement des
/// memes secours. Les recopier en ferait TROIS endroits a corriger le jour ou
/// un numero change — et un numero de secours perime est de loin le pire
/// chiffre faux de l'application. Une constante ne peut pas divergier.
const kSecoursDuGr20 = <TrailEmergencyNumber>[
  TrailEmergencyNumber(
    name: 'PGHM Corte (secours en montagne)',
    phone: '+33495477146',
  ),
  TrailEmergencyNumber(
    name: 'Parc naturel regional de Corse',
    phone: '+33495345480',
  ),
];

/// Configuration du sentier GR20 (Corse).
///
/// TOUS LES CHIFFRES DE CE FICHIER SONT LUS SUR LA TRACE (tache 839), et c'est
/// la seule chose qu'il faut retenir de son en-tete. Ils sont produits par
/// `python tool/gr20_dans_stepways.py`, qui mesure
/// `assets/data/gr20/track.gpx` — la geometrie de la relation OpenStreetMap
/// 12484370 relevee en tache 837, 9 128 points, 9 128 altitudes, zero
/// manquante. Un test de garde
/// (`test/assets/gr20_chiffres_mesures_839_test.dart`) relit le JSON produit et
/// refuse que les totaux ci-dessous s'en ecartent : un chiffre modifie a la
/// main ici ferait rougir la gate.
///
/// CE QU'IL Y AVAIT AVANT, ET POURQUOI CE N'ETAIT PAS TENABLE. L'ancienne
/// application GR20 portait seize longueurs d'etape venues d'un TOPO, puis
/// MULTIPLIEES PAR 1,069 pour que leur somme tombe sur les 183 km annonces. Son
/// propre code l'avouait en commentaire : « on ancre sur le TOTAL fiable :
/// E1->E14 mises a l'echelle (x1,069) ». Le total etait donc juste et les
/// etapes fausses — jusqu'a 62 % d'ecart sur l'etape 13 (Usciolu vers Asinau :
/// 12,8 km annonces, 20,73 km mesures), 56 % sur l'etape 6, 43 % sur l'etape 3.
/// Toute journee recomposee sur ces longueurs heritait de l'erreur. Il n'y a
/// plus aucun coefficient : il y a une trace, et on la mesure.
///
/// DEUX AUTRES DEFAUTS CORRIGES PAR LA MESURE, ET PAS PAR UNE OPINION.
///  1. L'ORDRE DES TROIS DERNIERES ETAPES. L'ancien decoupage annonçait
///     Asinau -> Paliri -> Bavella -> Conca. Sur la trace, Bavella est au
///     PK 165,84 et Paliri au PK 170,38 : BAVELLA VIENT AVANT. Pose sur la
///     trace, l'ancien ordre faisait parcourir 37,55 km pour une section qui en
///     fait 28,49, soit 9,06 KM MARCHES DEUX FOIS, dont une etape « a
///     reculons ». L'ordre d'ici vient du tri par point kilometrique.
///  2. LES BORNES DES DEUX PARCOURS. L'ancien code declarait le nord sur les
///     etapes 1 a 8 avec le commentaire « jusqu'a Vizzavona ». Sa propre liste
///     le dementait : l'etape 8 finit au REFUGE DE L'ONDA, PK 81,59, soit
///     10,21 km et une journee entiere AVANT Vizzavona (PK 91,80), en pleine
///     montagne, sans gare et sans lit hors dortoir. Le nord compte donc NEUF
///     etapes et le sud SEPT, et ces deux nombres sont COMPTES par l'outil,
///     jamais ecrits (cf. `assets/data/gr20.json`, parcours NORD et SUD).
///
/// VIZZAVONA TOMBE A 50,0 % DE LA TRACE AU METRE PRES : 91,80 km au nord,
/// 91,79 km au sud. Le denivele, lui, n'est pas partage — le nord porte
/// 1,74 fois le D+ du sud pour la meme distance. Les deux moities se marchent
/// donc tres differemment, et c'est la que se lit la difficulte.
///
/// CE SENTIER N'EST PLUS UN PRODUIT (tache 841), ET C'EST LA SEULE CHOSE QUI A
/// CHANGE DEPUIS LA TACHE 839. Il declare ses deux chapitres
/// ([TrailConfig.chapterIds]), donc [TrailConfig.estVendable] est faux, donc il
/// quitte le catalogue de vente ([TrailCatalog.all]) et l'achat le refuse
/// nommement ([PurchaseStatusResult.sentierAChapitres]). Decision de Christophe
/// du 15/10 17:45, verbatim : « on achete le sentier seulement si il n y a pas
/// de chapitres. Sinon par exemple pour le GR20 on peut acheter chapitre 1,
/// chapitre 2, chapitre 1 and 2 ».
///
/// IL RESTE RESOLVABLE PAR SON IDENTIFIANT, ET CE N'EST PAS UNE DEMI-MESURE. Un
/// sentier mere est une NUMEROTATION DE REFERENCE (design #101920, 4.4) : ses
/// seize etapes, sa trace de 9 128 points, ses trente et une nuits et ses
/// soixante-quatorze couchages restent la donnee d'ou les chapitres sont
/// decoupes, et la regle CH-10 veut que cette numerotation ne bouge JAMAIS —
/// sinon les droits deja vendus designeraient les mauvaises journees. Le rendre
/// introuvable, comme l'est un sentier fictif, casserait le decoupage lui-meme.
/// Ce qui disparait est le PRODUIT, pas la reference.
const gr20TrailConfig = TrailConfig(
  id: 'gr20',
  name: 'GR20',
  displayName: 'GR20',
  tagline: 'La Corse dans toute sa longueur, de Calenzana a Conca',
  // SEIZE ETAPES, et c'est le nombre de coupures RELEVEES moins une : dix-sept
  // objets OpenStreetMap nommes (le depart plus seize fins d'etape), projetes
  // sur la trace puis tries par point kilometrique.
  totalStages: 16,
  // 183,59 km = somme des seize etapes mesurees. La trace entiere mesure
  // 183,585 km : les deux concordent, parce que les etapes sont des tranches de
  // CETTE trace et non des chiffres rapportes.
  totalDistanceKm: 183.59,
  // 11 644 m = somme des seize D+ mesures, etape par etape. Mesure sur la trace
  // ENTIERE, le meme filtre rend 11 603 m : l'ecart de 41 m (0,35 %) vient
  // de ce que chaque etape ancre ses deux bouts sur l'altitude reelle avant de
  // sommer — correction mesuree en tache 838, sans laquelle les courts trajets
  // perdent jusqu'a 16 % de leur denivele. On porte ici la somme des etapes,
  // pour que le total affiche soit EXACTEMENT celui que le randonneur obtient
  // en additionnant ses journees. Pour memoire, le topo FFRP annonce 12 550 m.
  totalElevationGain: 11644,
  region: 'Corse',
  country: 'France',
  primaryColorValue: 0xFF37474F, // Gris granit
  secondaryColorValue: 0xFFEF6C00, // Orange balisage GR
  gpxAssetPath: 'assets/data/gr20/track.gpx',
  directions: ['NS', 'SN'],
  // LES DUREES PROPOSEES, ET POURQUOI CELLES-LA. Christophe, 15/10 18:00,
  // verbatim : « Beaucoup font tout le GR en 7 jours. D'autre en 10/12 ». Le
  // nombre de jours n'est PAS une propriete du sentier, c'est un choix du
  // marcheur : ces valeurs ne sont donc que des reperes du selecteur, et les
  // bornes reelles du curseur sont derivees des donnees chargees
  // (`durationBoundsProvider`). 16 est l'allure federale (une etape par jour).
  //
  // TACHE 848 — 10 DEVIENT 9, PARCE QUE C'EST L'ECHELLE QUE CHRISTOPHE
  // PRESENTE. Le 17/10 11:05, verbatim : « Et quand tu presente tu mets 7
  // jours= experts, 9jours = tres difficile, 12 jours Difficile, 16 jours =
  // Difficile ». Les quatre reperes du selecteur sont donc les quatre allures
  // qu'il annonce : une fiche qui propose 10 jours quand le discours parle de 9
  // oblige le lecteur a faire la conversion lui-meme.
  //
  // TACHE 852 — LES QUATRE ALLURES RESTENT, LES QUATRE VERDICTS QU'IL ANNONCAIT
  // NE TIENNENT PAS, ET C'EST MESURE. La bande « expert » n'existe plus (17/10
  // 17:25) et la difficulte se calcule desormais sur l'effort complet d'une
  // journee — distance, montee, descente. Resultat sur les quatre reperes
  // ci-dessous, decoupage sur les trente et une nuits relevees : TRES DIFFICILE
  // aux quatre, et aux vingt-cinq autres allures de 7 a 31 jours, DANS LES DEUX
  // SENS. Son echelle descendante (difficile a 12 et 16 jours) ne sort pas des
  // chiffres, parce que la premiere journee — 11,3 km, 1 455 m de montee,
  // 26,5 km-effort — ne se coupe pas : il n'existe aucun couchage dans la
  // montee. Ce n'est pas le selecteur qu'il faut corriger, c'est le discours.
  availableDurations: [7, 9, 12, 16],
  defaultDuration: 16,
  offlineFirst: true,
  hasPremium: false,
  // LES DEUX CHAPITRES, ET CETTE SEULE LIGNE RETIRE LE SENTIER DE LA VENTE.
  //
  // L'ORDRE EST CELUI DE LA TRACE, et il ne se renumerote jamais (regle CH-10
  // du design #101920) : on ajoute a la fin, on archive un membre, on ne
  // renumerote pas — sinon les droits deja vendus designent les mauvaises
  // journees.
  chapterIds: ['gr20-nord', 'gr20-sud'],
  emergencyNumbers: kSecoursDuGr20,
  // Dossier de donnees du sentier : etapes, points d'interet et trace.
  seedAssetsBase: 'assets/data/gr20',
  // Fichier monolithique : les trois parcours (integral, nord, sud), les seize
  // etapes et les soixante-quatorze couchages releves, tous porteurs de leur
  // identifiant OpenStreetMap dans leur id.
  accommodationsAssetPath: 'assets/data/gr20.json',
  // LES TRENTE ET UNE NUITS OUVERTES AU DECOUPAGE (tache 839) : seize fins
  // d'etape et quinze coupures de jour relevees en tache 838, plus les trente
  // et un segments mesures entre nuits consecutives.
  possibleNightsAssetPath: 'assets/data/gr20/nuits_possibles.json',
  // LA FICHE DU SENTIER (tache 846) : sa description en trois questions — ou
  // c'est, ce qu'on y voit, a quoi s'attendre — et son manifeste de photos.
  // AUCUN de ces textes ne vit dans le code, et aucune photo n'est choisie ici.
  ficheAssetPath: 'assets/data/gr20/fiche.json',
  // 2 578 m — L'ALTITUDE LA PLUS HAUTE DE LA TRACE, MESUREE SUR SES 9 128
  // POINTS. Elle tombe dans l'etape 4 (Ascu-Stagnu vers Tighjettu), celle qui
  // franchit le point le plus haut du chemin. C'est le plus haut du catalogue,
  // et 1 066 m au-dessus de celui du Mare a Mare Centre : voila pourquoi
  // l'altitude est un critere a part et non une consequence du denivele.
  maxAltitudeM: 2578,
  privacyPolicyUrl: StepwaysLegal.privacyPolicyUrl,
);
