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
  totalElevationGain: 3750,
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
  // PARITE GR20, LOT 2 (#99433) : sentier VITRINE de demonstration. Entierement
  // jouable (GPS + journal + navigation) SANS achat, comme le mode demo « tout
  // debloque » de GR20. Le debridage passe par CE flag (donnee de config), pas
  // par un id de localite en dur : seule la vitrine par defaut est debridee, le
  // modele a la carte reste intact sur les autres sentiers (decision Christophe).
  isShowcaseTrail: true,
  emergencyNumbers: [
    // Secours regional fourni par la config (jamais hardcode dans le moteur).
    TrailEmergencyNumber(name: 'Secours montagne Corse', phone: '+33495613636'),
  ],
  // Declenche le chargement du DOSSIER de donnees (stages/pois/track) au seed.
  seedAssetsBase: 'assets/data/mare_a_mare_centre',
  // Fiches conseils rattachees au sentier (chargees au seed).
  tipAssetPaths: ['assets/tips/mare_a_mare_tips.json'],
  privacyPolicyUrl: 'https://example.org/mare-a-mare-centre/privacy',
);
