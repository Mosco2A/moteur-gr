import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/config/test_trail_config.dart';
import 'package:moteur_gr/core/config/trail_config.dart';
import 'package:moteur_gr/core/data/daos/stages_dao.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/core/geo/track_point.dart';
import 'package:moteur_gr/core/models/stage.dart';
import 'package:moteur_gr/core/providers/database_provider.dart';
import 'package:moteur_gr/features/trek/data/drift_trail_data_provider.dart';
import 'package:moteur_gr/features/trek/domain/trail_data_provider.dart';
import 'package:moteur_gr/features/trek/providers/trail_providers.dart';

/// Tests E2.1c — interface TrailDataProvider + Drift implementation.
void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('DriftTrailDataProvider', () {
    test('retourne des stages depuis la DB', () async {
      // Inserer des donnees de test
      final dao = StagesDao(db);
      await dao.insertAll([
        const StageModel(
          trailId: 'test-trail',
          stageNumber: 1,
          name: 'Etape 1',
          distanceKm: 10.0,
          elevationGainM: 500,
          elevationLossM: 300,
          startLat: 42.0,
          startLng: 9.0,
          endLat: 42.1,
          endLng: 9.1,
        ).toCompanion(),
        const StageModel(
          trailId: 'test-trail',
          stageNumber: 2,
          name: 'Etape 2',
          distanceKm: 8.0,
          elevationGainM: 400,
          elevationLossM: 600,
          startLat: 42.1,
          startLng: 9.1,
          endLat: 42.2,
          endLng: 9.2,
        ).toCompanion(),
      ]);

      final provider = DriftTrailDataProvider(
        db: db,
        trailConfig: testTrailConfig,
      );

      final stages = await provider.getStages('test-trail');

      expect(stages.length, 2);
      expect(stages[0].name, 'Etape 1');
      expect(stages[0].distanceKm, 10.0);
      expect(stages[1].name, 'Etape 2');
      expect(stages[1].stageNumber, 2);
    });
  });

  group('trailDataProvider Riverpod', () {
    test('inject et override fonctionnent', () {
      // Creer un fake provider pour les tests
      final fakeProvider = _FakeTrailDataProvider();

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          trailConfigProvider.overrideWithValue(testTrailConfig),
          trailDataProvider.overrideWithValue(fakeProvider),
        ],
      );

      final result = container.read(trailDataProvider);

      expect(result, isA<TrailDataProvider>());
      expect(result, same(fakeProvider));
      expect(result.getTrailConfig().id, 'test-trail');

      container.dispose();
    });
  });
}

/// Fake implementation pour tester l'override Riverpod
class _FakeTrailDataProvider implements TrailDataProvider {
  @override
  Future<List<StageModel>> getStages(String trailId) async => [];

  @override
  Future<List<TrackPoint>> getTrackPoints(String stageId) async => [];

  @override
  TrailConfig getTrailConfig() => testTrailConfig;
}
