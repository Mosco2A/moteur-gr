import 'trail_config.dart';

/// Premier sentier de catalogue HORS Corse (F8D-01, Phase 8 P8-D).
///
/// Le Moteur GR est GENERIQUE multi-sentiers (#84627) : il ne doit RIEN
/// hardcoder de la Corse / du Mare a Mare. Ce sentier de demonstration situe
/// dans les Pyrenees prouve la genericite — un second jeu de donnees, neutre,
/// charge par la meme configuration que n'importe quel autre sentier.
///
/// Donnees fictives en P2-P3 (#84627) : aucune correspondance reelle exacte,
/// le backend (Phase 4) fournira les vraies donnees par sentier.
const pyreneesTrailConfig = TrailConfig(
  id: 'gr-pyrenees',
  name: 'GR Pyrenees',
  displayName: 'Traversee des Pyrenees',
  tagline: 'D un versant a l autre de la chaine',
  totalStages: 12,
  totalDistanceKm: 248.0,
  totalElevationGain: 16800,
  region: 'Pyrenees',
  country: 'France',
  primaryColorValue: 0xFF2E7D32, // Vert montagne
  secondaryColorValue: 0xFF1565C0, // Bleu torrent
  gpxAssetPath: 'assets/gpx/gr_pyrenees.gpx',
  directions: ['EW', 'WE'],
  availableDurations: [10, 12, 14, 18],
  defaultDuration: 12,
  offlineFirst: true,
  hasPremium: false,
  emergencyNumbers: [
    // Secours regional fourni par la config (jamais hardcode dans le moteur).
    TrailEmergencyNumber(
        name: 'Secours montagne Pyrenees', phone: '+33561000000'),
  ],
  privacyPolicyUrl: 'https://example.org/gr-pyrenees/privacy',
);
