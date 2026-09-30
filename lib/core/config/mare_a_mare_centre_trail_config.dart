import '../branding/stepways_legal.dart';
import 'trail_config.dart';

/// Configuration du sentier Mare a Mare Centre (Corse).
///
/// PARITE GR20 — LOT 1 (cadrage #99423 §4.3). Sentier de demonstration reel
/// de StepWays : au lancement, l'app demarre sur ce sentier avec carte, etapes,
/// POI, meteo et conseils peuples.
///
/// Le Moteur GR reste GENERIQUE multi-sentiers (#84627) : ce fichier n'est qu'une
/// DONNEE de plus (une [TrailConfig]), au meme titre que [testTrailConfig] ou
/// [pyreneesTrailConfig]. AUCUNE localite n'est hardcodee DANS LE MOTEUR : la
/// Corse, le nombre d'etapes et les chemins d'assets vivent ici, en configuration.
///
/// L'[id] est EXACTEMENT le `trailId` des assets embarques
/// (`assets/data/mare_a_mare_centre/{stages,pois}.json` -> `mam-c-s*`) et de la
/// trace GPX : toute divergence casserait les jointures Drift au seed.
/// Totaux (7 etapes / 84 km / D+ 3750 m) derives des donnees `stages.json`.
const mareAMareCentreTrailConfig = TrailConfig(
  id: 'mare-a-mare-centre',
  name: 'Mare a Mare Centre',
  displayName: 'Mare a Mare Centre',
  tagline: 'De la mer a la mer, au coeur de la Corse',
  totalStages: 7,
  totalDistanceKm: 84.0,
  // INTEGRATION 647 — LE COMPILE S ALIGNE SUR LA BASE : 3550 m, et non 3750.
  // La fiche du sentier en base (lot 641) porte 3550, somme des deniveles des
  // sept etapes. Le compile en annoncait 3750 : deux chiffres pour un seul
  // sentier, et c est celui de la base qui est calcule.
  totalElevationGain: 3550,
  region: 'Corse',
  country: 'France',
  primaryColorValue: 0xFF2E7D32, // Vert maquis
  secondaryColorValue: 0xFF1565C0, // Bleu Mediterranee
  gpxAssetPath: 'assets/data/mare_a_mare_centre/track.gpx',
  directions: ['NS', 'SN'],
  availableDurations: [5, 7, 9],
  defaultDuration: 7,
  offlineFirst: true,
  hasPremium: false,
  // PRIX : 7 etapes, soit une par etape (defaut du modele, `priceStages` nul).
  // CE SENTIER EST PAYANT, ET IL L EST REDEVENU (tache 601). Il portait
  // `isShowcaseTrail: true`, qui le resolvait `owned` sans le moindre achat : il
  // etait donc INVENDABLE — realisation gratuite, outils complets gratuits, et
  // meme le sans-pub permanent reserve a l achat. La demonstration se fait
  // desormais sur un AUTRE sentier, gratuit, du catalogue
  // (`mareAMareCentreDemoTrailConfig`).
  emergencyNumbers: [
    // Secours regionaux fournis par la config (jamais hardcodes dans le moteur).
    // Le 112 n est pas ici : il est UNIVERSEL et vit dans le moteur
    // (`kUniversalEmergencyContacts`), parce qu il vaut sur tous les sentiers.
    //
    // INTEGRATION 647 — UN NUMERO NON CONFIRME EST PARTI, ET C EST UNE DECISION
    // DE CHRISTOPHE DU 30/09. Cette liste portait « Secours montagne Corse
    // +33 4 95 61 36 36 », dont la SOURCE n a jamais pu etre etablie. Un numero
    // de secours faux ne coute pas un appel rate : il coute le temps qu on met a
    // comprendre qu il est faux, et c est le pire moment pour le decouvrir. On
    // ne garde donc que ce qui est source.
    //
    // CES DEUX-LA LE SONT, et ils sont ceux que porte la fiche du sentier en
    // base (lot 641, publication/sources/mare-a-mare-centre/sentier.json) : le
    // compile et la base disent desormais la MEME chose, ce qui est tout
    // l interet d avoir les deux.
    TrailEmergencyNumber(
      name: 'PGHM Corte (secours en montagne)',
      phone: '+33495477146',
    ),
    TrailEmergencyNumber(
      name: 'Parc naturel regional de Corse',
      phone: '+33495345480',
    ),
  ],
  // Declenche le chargement du DOSSIER de donnees (stages/pois/track) au seed.
  seedAssetsBase: 'assets/data/mare_a_mare_centre',
  // R4 : fichier monolithique portant les HEBERGEMENTS (11 gites/campings/hotel
  // reels, keyes par etape) charge dans les tables relationnelles riches lues
  // par l'assistant Nuitees (getAccommodations). Sans cela, les noms de nuitee
  // etaient absents (le dossier ci-dessus ne seede pas les hebergements).
  accommodationsAssetPath: 'assets/data/mare_a_mare_centre.json',
  // Fiches conseils rattachees au sentier (chargees au seed).
  tipAssetPaths: ['assets/tips/mare_a_mare_tips.json'],
  privacyPolicyUrl: StepwaysLegal.privacyPolicyUrl,
);
