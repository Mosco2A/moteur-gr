import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/config/test_trail_config.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/data/daos/stages_dao.dart';
import 'package:moteur_gr/features/trek/data/drift_trail_data_provider.dart';
import 'package:moteur_gr/features/trek/domain/models/stage.dart' as trek;

/// Tests de DriftTrailDataProvider.
void main() {
  group('DriftTrailDataProvider', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('getStages retourne les stages depuis la DB Drift', () async {
      // Inserer des etapes via le DAO existant
      final dao = StagesDao(db);
      await dao.insertAll([
        const StagesCompanion(
          trailId: Value('test-trail'),
          stageNumber: Value(1),
          name: Value('Refuge A - Refuge B'),
          distanceKm: Value(12.5),
          elevationGainM: Value(800),
          elevationLossM: Value(400),
          startLat: Value(42.50),
          startLng: Value(8.85),
          endLat: Value(42.46),
          endLng: Value(8.93),
          difficulty: Value('hard'),
        ),
        const StagesCompanion(
          trailId: Value('test-trail'),
          stageNumber: Value(2),
          name: Value('Refuge B - Refuge C'),
          distanceKm: Value(8.0),
          elevationGainM: Value(500),
          elevationLossM: Value(600),
          startLat: Value(42.46),
          startLng: Value(8.93),
          endLat: Value(42.40),
          endLng: Value(9.00),
          difficulty: Value('moderate'),
        ),
      ]);

      // Creer le provider avec la config de test
      final provider = DriftTrailDataProvider(
        db: db,
        trailConfig: testTrailConfig,
      );

      // Charger les etapes
      final stages = await provider.getStages();

      // Verifications
      expect(stages, isA<List<trek.Stage>>());
      expect(stages.length, 2);

      // Premiere etape
      expect(stages[0].id, 'test-trail-1');
      expect(stages[0].nameFr, 'Refuge A - Refuge B');
      expect(stages[0].distance, 12.5);
      expect(stages[0].elevationGain, 800);
      expect(stages[0].elevationLoss, 400);
      expect(stages[0].difficulty, 'hard');
      expect(stages[0].orderIndex, 0);
      expect(stages[0].startLat, 42.50);
      expect(stages[0].startLng, 8.85);

      // Deuxieme etape
      expect(stages[1].id, 'test-trail-2');
      expect(stages[1].nameFr, 'Refuge B - Refuge C');
      expect(stages[1].distance, 8.0);
      expect(stages[1].elevationGain, 500);
      expect(stages[1].difficulty, 'moderate');
      expect(stages[1].orderIndex, 1);
    });

    test('getStages retourne une liste vide sans donnees', () async {
      final provider = DriftTrailDataProvider(
        db: db,
        trailConfig: testTrailConfig,
      );

      final stages = await provider.getStages();
      expect(stages, isEmpty);
    });

    test('getTrailConfig retourne la configuration du sentier', () async {
      final provider = DriftTrailDataProvider(
        db: db,
        trailConfig: testTrailConfig,
      );

      final config = await provider.getTrailConfig();
      expect(config, isNotNull);
      expect(config!.id, 'test-trail');
      expect(config.name, 'Sentier des Volcans');
      expect(config.totalStages, 5);
      expect(config.totalDistanceKm, 72.0);
      expect(config.totalElevationGain, 2420);
    });

    test('getTrackPoints retourne une liste vide (pas encore implemente)',
        () async {
      final provider = DriftTrailDataProvider(
        db: db,
        trailConfig: testTrailConfig,
      );

      final points = await provider.getTrackPoints('test-trail-1');
      expect(points, isEmpty);
    });
  });
}
