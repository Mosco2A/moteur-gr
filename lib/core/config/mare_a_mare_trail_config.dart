import 'trail_config.dart';

/// Configuration du sentier Mare a Mare Centre (Corse) — premier sentier cible
/// du Moteur GR (StepWays, fiche projet #84627, design D3 #86163).
///
/// Le Moteur reste GENERIQUE : Mare a Mare est une DONNEE (une [TrailConfig])
/// enregistree au catalogue, pas une localite codee en dur dans le moteur. Cette
/// config est simplement la PREMIERE du catalogue ([TrailCatalog.all]), donc le
/// sentier propose et centre PAR DEFAUT a l'ouverture de l'app.
///
/// Donnees fictives/embarquees en P2-P3 (#84627) : metadonnees (distance,
/// denivele, etapes, secours) alignees sur le manifeste embarque
/// `assets/data/mare_a_mare_centre.json`. Le trace GPX
/// (`assets/data/mare_a_mare_centre/track.gpx`) suit le CORRIDOR reel du sentier
/// — traversee Est-Ouest de la Corse, de Ghisonaccia (cote orientale,
/// 42.0156 / 9.4039) a Porticcio (golfe d'Ajaccio, 41.8903 / 8.8128) en passant
/// par Cozzano, Guitera-les-Bains, Quasquara et Santa Maria Siche — mais reste
/// une polyligne SCHEMATIQUE basse resolution (~53 points), PAS l'export topo
/// officiel haute fidelite (cf. RAPPORT GO-62). La bounding box de ce trace sert
/// au centrage automatique de la carte (CameraFit.bounds dans MapScreen).
const mareAMareTrailConfig = TrailConfig(
  id: 'mare-a-mare-centre',
  name: 'Mare a Mare Centre',
  displayName: 'Mare a Mare',
  tagline: 'La traversee Est-Ouest de la Corse',
  totalStages: 7,
  totalDistanceKm: 84.0,
  totalElevationGain: 3550,
  region: 'Corse',
  country: 'France',
  primaryColorValue: 0xFF1B6CA8, // Bleu mer Tyrrhenienne / golfe d'Ajaccio
  secondaryColorValue: 0xFF2E7D32, // Vert maquis corse
  // Le trace embarque vit sous assets/data/mare_a_mare_centre/ (deja declare
  // dans pubspec.yaml) aux cotes du manifeste, des etapes et des POI du sentier.
  gpxAssetPath: 'assets/data/mare_a_mare_centre/track.gpx',
  // Traversee Est-Ouest (et retour Ouest-Est) — coherent avec l'itineraire
  // `mam-centre-ew` du manifeste embarque.
  directions: ['EW', 'WE'],
  availableDurations: [5, 7, 9],
  defaultDuration: 7,
  offlineFirst: true,
  hasPremium: false,
  emergencyNumbers: [
    // Secours regional fourni par la config (jamais hardcode dans le moteur).
    // Le 112 universel est gere par le moteur et n'est pas duplique ici.
    TrailEmergencyNumber(
      name: 'Secours montagne Corse (PGHM)',
      phone: '+33495611422',
    ),
  ],
  // Donnees embarquees du sentier (manifeste + etapes + POI + conseils) pour le
  // seed initial. Aligne sur l'arborescence assets/data/mare_a_mare_centre/.
  seedAssetsBase: 'assets/data/mare_a_mare_centre',
  tipAssetPaths: ['assets/tips/mare_a_mare_tips.json'],
  privacyPolicyUrl: 'https://example.org/mare-a-mare-centre/privacy',
);
