import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/config/test_trail_config.dart';

/// Tests de la configuration du sentier fictif.
///
/// Verifie que testTrailConfig est valide :
/// champs non vides, totalStages == 5, coherence generale.
void main() {
  group('testTrailConfig', () {
    test('id non vide', () {
      expect(testTrailConfig.id, isNotEmpty);
    });

    test('name non vide', () {
      expect(testTrailConfig.name, isNotEmpty);
    });

    test('displayName non vide', () {
      expect(testTrailConfig.displayName, isNotEmpty);
    });

    test('tagline non vide', () {
      expect(testTrailConfig.tagline, isNotEmpty);
    });

    test('totalStages vaut 5', () {
      expect(testTrailConfig.totalStages, 5);
    });

    test('totalDistanceKm est positif', () {
      expect(testTrailConfig.totalDistanceKm, greaterThan(0));
    });

    test('totalElevationGain est positif', () {
      expect(testTrailConfig.totalElevationGain, greaterThan(0));
    });

    test('region non vide', () {
      expect(testTrailConfig.region, isNotEmpty);
    });

    test('country non vide', () {
      expect(testTrailConfig.country, isNotEmpty);
    });

    test('gpxAssetPath pointe vers un fichier gpx', () {
      expect(testTrailConfig.gpxAssetPath, endsWith('.gpx'));
    });

    test('primaryColorValue est un entier valide non nul', () {
      expect(testTrailConfig.primaryColorValue, isNonZero);
    });

    test('secondaryColorValue est un entier valide non nul', () {
      expect(testTrailConfig.secondaryColorValue, isNonZero);
    });

    test('directions contient au moins une valeur', () {
      expect(testTrailConfig.directions, isNotEmpty);
    });

    test('availableDurations contient au moins une valeur', () {
      expect(testTrailConfig.availableDurations, isNotEmpty);
    });

    test('defaultDuration est dans availableDurations', () {
      expect(
        testTrailConfig.availableDurations,
        contains(testTrailConfig.defaultDuration),
      );
    });

    test('id correspond au trailId attendu', () {
      expect(testTrailConfig.id, 'test-trail');
    });
  });
}
