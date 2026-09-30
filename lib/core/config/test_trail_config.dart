import 'trail_config.dart';

/// Configuration du sentier fictif pour les tests.
///
/// Sentier invente "Sentier des Volcans" — 5 etapes en Auvergne.
/// Donnees 100% fictives, aucune correspondance reelle.
///
/// IL EST DEVENU LE SENTIER GRATUIT DU CATALOGUE (tache 638, consequence
/// mesuree des bugs 1 et 8).
///
/// POURQUOI. Le lot 601 avait cree la notion de sentier GRATUIT — « un sentier
/// gratuit est une ENTREE du modele, dont le prix est nul ; une exemption serait
/// un trou » — et lui avait donne UNE seule instance : le « Mare a Mare Centre
/// Demo », ampute a deux etapes. Le test de Christophe du 30/09 a supprime cette
/// instance (bug 1, le doublon au catalogue ; bug 8, la demo doit etre le vrai
/// Mare a Mare entier). Le modele se retrouvait alors avec un niveau — le niveau
/// GRATUIT du modele eco (§2) — sans aucun sentier pour l'incarner.
///
/// CE QUE CELA CASSAIT, MESURE. Plus un seul sentier n'etait jouable sans payer :
/// « Mes treks » etait vide au premier lancement, et trois tests de parcours reel
/// (`aucun_geste_mort_573`, `resiliation_trois_clics_601`, personas « LE
/// CURIEUX ») tombaient parce que des ecrans entiers n'avaient plus aucun sentier
/// atteignable derriere eux. Le prix nul revient donc ici — sur un sentier
/// D'UNE AUTRE REGION, qui n'a jamais eu de prix a lui, et qui ne peut pas faire
/// doublon avec le Mare a Mare.
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
  // LE PRIX EST NUL — c'est TOUT ce qui fait de lui un sentier gratuit. Aucune
  // exemption, aucun cas particulier ailleurs dans le moteur : l'acces, la
  // realisation et la publicite se deduisent de ce seul nombre (lot 601).
  priceStages: 0,
  hasPremium: false,
  privacyPolicyUrl: 'https://example.org/test-trail/privacy',
);
