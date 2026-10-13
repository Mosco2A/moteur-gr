/// Un sentier entierement invente pour les tests : aucune correspondance avec
/// un lieu reel.
library;

import '../branding/stepways_legal.dart';
import 'trail_config.dart';

/// Configuration du sentier fictif pour les tests.
///
/// Sentier invente "Sentier des Volcans" — 5 etapes en Auvergne.
/// Donnees 100% fictives, aucune correspondance reelle.
///
/// IL N EST PLUS AU CATALOGUE, ET IL NE L A JAMAIS MERITE (tache 793). Ce
/// fichier declarait sa fiction des sa deuxieme ligne, et ce sentier etait
/// pourtant VISIBLE au catalogue et ACHETABLE a 4,95 EUR — cinq etapes au
/// palier de 0,99. Nom credible, region credible, 72 km et 2 420 m de denivele
/// credibles : rien, dans ce que voyait le randonneur, ne disait que le chemin
/// n existe pas. Decision de Christophe du 10/10 : « tu degage ».
///
/// CE QUI A CHANGE N EST PAS CE FICHIER MAIS CE QU IL AVOUE. La fiction etait
/// ecrite en prose, donc lisible par un humain et par personne d autre. Elle
/// est maintenant portee par [TrailConfig.isFictional], une DONNEE, et
/// [TrailCatalog] refuse de mettre au catalogue ce qui se declare fictif.
///
/// IL RESTE AU DEPOT, VOLONTAIREMENT. Soixante-six fichiers de test et deux
/// campagnes d integration s en servent de DECOR — fixtures d etapes, de POI,
/// de trace, de theme, de partage. Les sortir du depot serait une chirurgie de
/// 270 lignes sans un gramme de benefice pour le randonneur. La regle est
/// simple : ce que le randonneur ne voit pas peut rester s il sert au harnais.
const testTrailConfig = TrailConfig(
  id: 'test-trail',
  name: 'Sentier des Volcans',
  displayName: 'Volcans Trail',
  tagline: 'Au coeur des crateres oublies',
  totalStages: 5,
  totalDistanceKm: 72.0,
  totalElevationGain: 2420,
  region: 'Auvergne',
  country: 'France',
  primaryColorValue: 0xFF8B4513, // Brun volcanique
  secondaryColorValue: 0xFFD2691E, // Orange terre
  gpxAssetPath: 'assets/gpx/test_trail.gpx',
  directions: ['NS', 'SN'],
  availableDurations: [3, 5, 7],
  defaultDuration: 5,
  offlineFirst: true,
  hasPremium: false,
  // CE SENTIER N EXISTE PAS, ET IL LE DIT MAINTENANT EN DONNEE. C est ce seul
  // drapeau qui le tient hors du catalogue : [TrailCatalog] filtre sur la
  // propriete, jamais sur l identifiant.
  isFictional: true,
  privacyPolicyUrl: StepwaysLegal.privacyPolicyUrl,
);
