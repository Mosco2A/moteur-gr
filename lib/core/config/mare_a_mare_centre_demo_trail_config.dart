import '../branding/stepways_legal.dart';
import 'trail_config.dart';

/// Configuration du sentier MARE A MARE CENTRE DEMO — le sentier de
/// demonstration GRATUIT de StepWays (tache 601).
///
/// DECISION DE CHRIS, 27/09 12:24, verbatim : « il faut un sentier demo, pas un
/// sentier bride demo. Les donnees peuvent etre celle de mare a mare. Mais il y
/// a mare a mare ET mare a mare demo des le catalogue ».
///
/// UN SENTIER A PART ENTIERE, PAS UN MODE D AFFICHAGE. Il a son propre
/// identifiant, son propre nom (compose dans les cinq langues a l affichage,
/// cf. `catalog.freeTrailName`), ses propres donnees et ses propres droits. Rien
/// n est bride, grise ni verrouille dessus : tout le parcours est vivable —
/// preparation, faisabilite, sac, depart, navigation, journal, arrivee, diplome.
///
/// CE QU IL REMPLACE, ET POURQUOI C EST MIEUX. Avant lui, la demonstration se
/// faisait sur le VRAI Mare a Mare via un drapeau `isShowcaseTrail` qui le
/// declarait exempt du mode demo. Une exemption est un trou dans le modele : le
/// sentier payant devenait invendable (jouable, realisable et sans pub sans
/// avoir rien paye), et le drapeau n etait soutenu par AUCUNE decision. Un
/// sentier gratuit, lui, est une ENTREE du modele : son prix est nul
/// ([TrailConfig.priceStages] a 0), et tout le reste se deduit de ce prix.
///
/// DEUX ETAPES, et c est une decision reversible (Skynet, 27/09) : assez pour
/// vivre le parcours entier du premier ecran au diplome, trop peu pour
/// remplacer un sentier de sept etapes. Les totaux ci-dessous sont la SOMME
/// REELLE des deux premieres etapes des donnees source (15 + 12 km ; 850 + 600
/// m de D+) — jamais recopies du sentier complet, qu ils contrediraient.
///
/// SES DONNEES SONT CELLES DU MARE A MARE, limitees aux deux premieres etapes
/// et reversees sous SON identifiant (`assets/data/mare_a_mare_centre_demo/`).
/// Les identifiants d etapes et de POI sont prefixes `-demo-` : aucune jointure
/// Drift ne peut confondre les deux sentiers, donc aucune progression ne peut se
/// melanger. Les fiches conseils, elles, sont partagees : elles parlent du
/// terrain, pas d un droit d acces.
const mareAMareCentreDemoTrailConfig = TrailConfig(
  id: 'mare-a-mare-centre-demo',
  // Nom TECHNIQUE, jamais affiche tel quel : l affichage compose le nom du
  // sentier gratuit dans la langue du randonneur (cf. `catalog.freeTrailName`).
  name: 'Mare a Mare Centre Demo',
  displayName: 'Mare a Mare Centre',
  tagline: 'Les deux premieres etapes, offertes',
  totalStages: 2,
  totalDistanceKm: 27.0,
  totalElevationGain: 1450,
  region: 'Corse',
  country: 'France',
  primaryColorValue: 0xFF2E7D32, // Vert maquis (meme terrain, meme identite)
  secondaryColorValue: 0xFF1565C0, // Bleu Mediterranee
  gpxAssetPath: 'assets/data/mare_a_mare_centre_demo/track.gpx',
  directions: ['NS', 'SN'],
  // Deux etapes se marchent en deux ou trois jours : proposer 5, 7 ou 9 jours
  // comme le sentier complet n aurait aucun sens.
  availableDurations: [2, 3],
  defaultDuration: 2,
  offlineFirst: true,
  hasPremium: false,
  // LE PRIX EST NUL — c est TOUT ce qui fait de lui un sentier gratuit. Aucune
  // exemption, aucun cas particulier ailleurs dans le moteur : l acces, la
  // realisation et la publicite se deduisent de ce seul nombre.
  priceStages: 0,
  emergencyNumbers: [
    // Meme terrain, meme secours : la Corse ne change pas parce que le sentier
    // est gratuit. La securite n est jamais une contrepartie commerciale.
    TrailEmergencyNumber(name: 'Secours montagne Corse', phone: '+33495613636'),
  ],
  seedAssetsBase: 'assets/data/mare_a_mare_centre_demo',
  accommodationsAssetPath: 'assets/data/mare_a_mare_centre_demo.json',
  tipAssetPaths: ['assets/tips/mare_a_mare_tips.json'],
  privacyPolicyUrl: StepwaysLegal.privacyPolicyUrl,
);
