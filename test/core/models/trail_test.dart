import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/models/trail.dart';

/// Tests du modele Trail (fromJson, toJson).
void main() {
  group('Trail', () {
    test('fromJson deserialise correctement', () {
      final json = {
        'id': 'test_trail',
        'name': 'Test Trail',
        'displayName': 'Sentier de Test',
        'tagline': 'Un sentier pour les tests',
        'totalStages': 5,
        'totalDistanceKm': 80.5,
        'totalElevationGain': 4500,
        'region': 'Region Test',
        'country': 'France',
      };

      final trail = Trail.fromJson(json);
      expect(trail.id, 'test_trail');
      expect(trail.name, 'Test Trail');
      expect(trail.displayName, 'Sentier de Test');
      expect(trail.tagline, 'Un sentier pour les tests');
      expect(trail.totalStages, 5);
      expect(trail.totalDistanceKm, 80.5);
      expect(trail.totalElevationGain, 4500);
      expect(trail.region, 'Region Test');
      expect(trail.country, 'France');
    });

    test('fromJson avec tagline par defaut', () {
      final json = {
        'id': 'minimal',
        'name': 'Min',
        'displayName': 'Minimal',
        'totalStages': 1,
        'totalDistanceKm': 10.0,
        'totalElevationGain': 500,
        'region': 'Test',
        'country': 'France',
      };

      final trail = Trail.fromJson(json);
      expect(trail.tagline, '');
    });

    test('toJson serialise correctement', () {
      const trail = Trail(
        id: 'export_test',
        name: 'Export',
        displayName: 'Export Test',
        tagline: 'Accroche',
        totalStages: 3,
        totalDistanceKm: 45.0,
        totalElevationGain: 2000,
        region: 'Alpes',
        country: 'France',
      );

      final json = trail.toJson();
      expect(json['id'], 'export_test');
      expect(json['totalStages'], 3);
      expect(json['totalDistanceKm'], 45.0);
      expect(json['region'], 'Alpes');
    });

    test('roundtrip fromJson -> toJson', () {
      final original = {
        'id': 'roundtrip',
        'name': 'RT',
        'displayName': 'Roundtrip',
        'tagline': 'Test RT',
        'totalStages': 7,
        'totalDistanceKm': 120.0,
        'totalElevationGain': 6000,
        'region': 'Pyrenees',
        'country': 'France',
      };

      final trail = Trail.fromJson(original);
      final restored = trail.toJson();

      expect(restored['id'], original['id']);
      expect(restored['totalStages'], original['totalStages']);
      expect(restored['totalDistanceKm'], original['totalDistanceKm']);
    });

    test('equality fonctionne avec freezed', () {
      const a = Trail(
        id: 't1', name: 'A', displayName: 'A',
        totalStages: 1, totalDistanceKm: 10,
        totalElevationGain: 500, region: 'R', country: 'FR',
      );
      const b = Trail(
        id: 't1', name: 'A', displayName: 'A',
        totalStages: 1, totalDistanceKm: 10,
        totalElevationGain: 500, region: 'R', country: 'FR',
      );
      expect(a, equals(b));
    });

    test('copyWith modifie un champ', () {
      const trail = Trail(
        id: 't1', name: 'A', displayName: 'Original',
        totalStages: 1, totalDistanceKm: 10,
        totalElevationGain: 500, region: 'R', country: 'FR',
      );
      final modified = trail.copyWith(displayName: 'Modifie');
      expect(modified.displayName, 'Modifie');
      expect(modified.id, 't1');
    });
  });
}
