/// LE CHAPITRE NORD DU GR20 — un sentier COMPLET, et le premier produit de
/// StepWays dont l'unite de vente est le chapitre.
library;

import '../branding/stepways_legal.dart';
import 'gr20_trail_config.dart';
import 'trail_config.dart';

/// Configuration du chapitre NORD du GR20 (Calenzana vers Vizzavona).
///
/// POURQUOI CE FICHIER EXISTE, EN UNE PHRASE DE CHRISTOPHE (15/10 17:45),
/// verbatim : « on achete le sentier seulement si il n y a pas de chapitres.
/// Sinon par exemple pour le GR20 on peut acheter chapitre 1, chapitre 2,
/// chapitre 1 and 2 ». Le GR20 a donc deux chapitres, et ce sont EUX les
/// produits ; le sentier entier n'en est plus un.
///
/// UN CHAPITRE EST UN SENTIER COMPLET (regle CH-11 du design #101920), ET CE
/// N'EST PAS UNE FORMULE. Ce chapitre a sa propre trace
/// (`assets/data/gr20-nord/track.gpx`, 4 463 points decoupes dans les 9 128 de
/// la trace mere), ses propres etapes RENUMEROTEES de un a neuf, ses propres
/// reperes, ses propres couchages et ses propres nuits. Il ne partage RIEN avec
/// son sentier mere, et surtout pas sa trace : un randonneur qui achete le nord
/// ne telecharge pas le sud et ne le voit pas sur sa carte.
///
/// TOUS LES CHIFFRES D'ICI SONT CEUX DE LA TACHE 839, DECOUPES. Ils sont
/// produits par `python tool/gr20_chapitres.py`, qui ne mesure RIEN : il
/// decoupe les fichiers deja mesures par `tool/gr20_dans_stepways.py` sur la
/// trace relevee en tache 837. Un chiffre de chapitre est donc, par
/// construction, un chiffre du sentier entier — jamais une seconde mesure qui
/// pourrait dire autre chose que la premiere. Le test de garde
/// `test/assets/gr20_chapitres_mesures_841_test.dart` relit
/// `assets/data/gr20/chapitres.json` et refuse tout ecart avec ce fichier.
///
/// LA COUPE EST A VIZZAVONA, ET SEULEMENT LA. Christophe, 15/10 17:58,
/// verbatim : « vizzavona pardon, c'est la que ca se decoupe et seulement la ».
/// Vizzavona est le seul point du GR20 qui satisfait la regle CH-3 (un
/// transport public desservi toute l'annee) : elle a une gare sur la ligne
/// Ajaccio-Corte-Bastia, et un lit hors dortoir y existe. Elle tombe a 50,0 %
/// de la trace au metre pres — 91,797 km au nord, 91,788 km au sud.
///
/// NEUF ETAPES, ET PAS HUIT. Le decoupage par moities de l'ancienne
/// application s'arretait a l'etape 8, qui finit au REFUGE DE L'ONDA, une
/// journee entiere et 10,21 km AVANT Vizzavona, en pleine montagne, sans gare
/// et sans lit hors dortoir. Le rang de la coupe est TROUVE par le nom
/// d'arrivee d'etape, jamais ecrit : c'est la neuvieme etape qui arrive a
/// Vizzavona.
///
/// NEUF JOURS, ET C'EST L'EXCEPTION DECLAREE DU CATALOGUE. La regle CH-1 du
/// design pose cinq jours par chapitre, six par exception. Le GR20 n'y tient
/// pas : chaque moitie fait neuf ou sept etapes. C'est assume et dit a voix
/// haute plutot que de rendre la regle elastique pour tous les autres sentiers
/// — et le nombre de JOURS n'est de toute facon pas une propriete du sentier
/// (Christophe, 15/10 18:00 : « Beaucoup font tout le GR en 7 jours. D'autre en
/// 10/12 »), c'est un choix du marcheur que le curseur de duree porte deja.
///
/// LE DENIVELE DIT OU EST LA DIFFICULTE. Les deux moities font la meme
/// longueur, mais le nord porte 7 401 m de montee contre 4 243 m au sud, soit
/// 1,74 fois. Deux chapitres de meme prix ne sont pas deux chapitres de meme
/// effort, et la carte du catalogue l'annonce.
const gr20NordTrailConfig = TrailConfig(
  id: 'gr20-nord',
  name: 'GR20 Nord',
  // LE NOM DU PRODUIT EST A ARBITRER PAR CHRISTOPHE, ET LE POINT EST NOMME.
  // Le design #101920 pose en gate G1 que « GR » n'apparait dans aucun nom de
  // produit : la federation detient les signes GR et GR de Pays a l'INPI, et
  // l'article L.713-6 du code de la propriete intellectuelle ne couvre que la
  // citation qui indique une destination, pas le nom du produit vendu. Ce nom
  // reprend celui que la tache 839 avait deja ecrit dans la donnee du sentier,
  // et il contient « GR20 » : tant que le sentier entier n'etait pas vendu par
  // chapitres, le point ne se posait pas ; il se pose maintenant, parce que ce
  // sont les chapitres qui sont les PRODUITS. Le baptiser se fait en une ligne
  // de donnee (`CHAPITRES` dans `tool/gr20_chapitres.py`), sans toucher une
  // ligne de code ni un test.
  displayName: 'GR20 Nord',
  tagline: 'La moitie nord de la Corse, de Calenzana a Vizzavona',
  // NEUF ETAPES, DONC NEUF ETAPES A PAYER. Le prix d'un chapitre EST son
  // nombre d'etapes (`priceStages` nul = le prix vaut `totalStages`) : aucun
  // modele de vente nouveau, aucun lot a construire en boutique. Acheter les
  // deux chapitres coute neuf plus sept, soit seize etapes — exactement ce que
  // coutait le sentier entier.
  totalStages: 9,
  // 91,80 km = somme des neuf etapes mesurees. La tranche de trace, elle,
  // mesure 91,797 km : les deux concordent a trois metres, l'ecart etant
  // l'arrondi au centieme de chaque etape. On porte ici la somme des etapes,
  // pour que le total affiche soit celui que le randonneur obtient en
  // additionnant ses journees.
  totalDistanceKm: 91.80,
  // 7 401 m = somme des neuf D+ mesures. Le sud en porte 4 243.
  totalElevationGain: 7401,
  region: 'Corse',
  country: 'France',
  primaryColorValue: 0xFF37474F, // Gris granit, comme le sentier mere
  secondaryColorValue: 0xFFEF6C00, // Orange balisage
  gpxAssetPath: 'assets/data/gr20-nord/track.gpx',
  directions: ['NS', 'SN'],
  // Des reperes du selecteur, pas des promesses : les bornes reelles du
  // curseur sont derivees des quinze nuits chargees
  // (`durationBoundsProvider`), comme pour le sentier entier.
  availableDurations: [5, 7, 9],
  defaultDuration: 9,
  offlineFirst: true,
  hasPremium: false,
  // CE CHAPITRE EST UN CHAPITRE DU GR20, ET CE CHAMP NE SERT QU'A LE RANGER.
  parentTrailId: 'gr20',
  emergencyNumbers: kSecoursDuGr20,
  seedAssetsBase: 'assets/data/gr20-nord',
  accommodationsAssetPath: 'assets/data/gr20-nord.json',
  possibleNightsAssetPath: 'assets/data/gr20-nord/nuits_possibles.json',
  privacyPolicyUrl: StepwaysLegal.privacyPolicyUrl,
);
