import 'trail_config.dart';

/// Configuration du sentier fictif pour les tests.
///
/// Sentier invente "Sentier des Volcans" — 5 etapes en Auvergne.
/// Donnees 100% fictives, aucune correspondance reelle.
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
  privacyPolicyUrl: 'https://example.org/test-trail/privacy',
);
