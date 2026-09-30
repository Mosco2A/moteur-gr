import '../branding/stepways_legal.dart';
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
///
/// CE SENTIER DECLARAIT UNE TRACE QUI N EXISTAIT PAS, ET IL ECHOUAIT DEJA
/// (corrige par la tache 607). `gpxAssetPath` valait
/// `assets/gpx/gr_pyrenees.gpx` ; mesure du 27/09 22:25 : le dossier
/// `assets/gpx/` ne contient que `.gitkeep` et `test_trail.gpx`. Ce sentier etait
/// donc AU CATALOGUE avec AUCUNE trace, et la carte affichait « impossible de
/// charger la trace » — un asset DECLARE qui ne se lit pas reste une erreur,
/// volontairement (`LecteurDeTrace`).
///
/// LA CORRECTION EST DE NE PLUS MENTIR, PAS DE FABRIQUER UNE TRACE. Le chemin
/// est desormais VIDE : ce sentier n a pas de trace embarquee, il le dit, et la
/// carte NOMME l absence (`SourceDeLaTrace.aucune`) au lieu de tomber en erreur.
/// Ses donnees viendront par le chemin distant, comme tout sentier neuf depuis la
/// tache 606 — et en attendant, sa source de publication
/// (`publication/sources/gr-pyrenees/`) le retire du catalogue avec le statut
/// `draft` (#M6), sans republier l application.
///
/// POURQUOI ON NE LUI A PAS INVENTE SA TRACE. La tache 607 disposait de l outil
/// qu il fallait, et ce sentier aurait pu etre le premier publie par le nouveau
/// chemin. Mais ses chiffres sont explicitement FICTIFS (248 km, 12 etapes,
/// 16 800 m de denivele) : produire une trace plausible et la publier `active`
/// mettrait un itineraire de MONTAGNE INVENTE entre les mains d un randonneur.
/// C est la meme faute que le fichier tronque que cette tache ferme par ailleurs,
/// en pire — celle-la serait volontaire.
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
  // VIDE, ET C EST LA CORRECTION : ce sentier n a pas de trace embarquee. Le
  // chemin declare ici pointait sur un fichier absent du depot (tache 607).
  gpxAssetPath: '',
  directions: ['EW', 'WE'],
  availableDurations: [10, 12, 14, 18],
  defaultDuration: 12,
  offlineFirst: true,
  hasPremium: false,
  emergencyNumbers: [
    // Secours regional fourni par la config (jamais hardcode dans le moteur).
    TrailEmergencyNumber(
      name: 'Secours montagne Pyrenees',
      phone: '+33561000000',
    ),
  ],
  privacyPolicyUrl: StepwaysLegal.privacyPolicyUrl,
);
