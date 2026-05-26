import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/data/daos/stages_dao.dart';
import 'package:moteur_gr/core/models/stage.dart';
import 'package:moteur_gr/core/providers/database_provider.dart';
import 'package:moteur_gr/features/trail/providers/stages_provider.dart';

/// Tests du provider de stages.
void main() {
  group('stagesProvider', () {
    test('retourne une liste vide pour un sentier sans etapes', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)],
      );

      final stages = await container.read(stagesProvider('empty').future);
      expect(stages, isEmpty);

      container.dispose();
      await db.close();
    });

    test('retourne les StageModel pour un sentier avec etapes', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final dao = StagesDao(db);

      await dao.insertAll([
        const StagesCompanion(
          trailId: Value('trail1'),
          stageNumber: Value(1),
          name: Value('Etape 1'),
          distanceKm: Value(10.0),
          elevationGainM: Value(500),
          elevationLossM: Value(300),
          startLat: Value(42.0),
          startLng: Value(9.0),
          endLat: Value(42.1),
          endLng: Value(9.1),
        ),
        const StagesCompanion(
          trailId: Value('trail1'),
          stageNumber: Value(2),
          name: Value('Etape 2'),
          distanceKm: Value(15.0),
          elevationGainM: Value(800),
          elevationLossM: Value(600),
          startLat: Value(42.1),
          startLng: Value(9.1),
          endLat: Value(42.2),
          endLng: Value(9.2),
        ),
      ]);

      final container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)],
      );

      final stages = await container.read(stagesProvider('trail1').future);
      expect(stages.length, 2);
      expect(stages[0], isA<StageModel>());
      expect(stages[0].name, 'Etape 1');
      expect(stages[1].name, 'Etape 2');

      container.dispose();
      await db.close();
    });

    test('filtre correctement par trailId', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final dao = StagesDao(db);

      await dao.insertAll([
        const StagesCompanion(
          trailId: Value('a'),
          stageNumber: Value(1),
          name: Value('A1'),
          distanceKm: Value(10.0),
          elevationGainM: Value(500),
          elevationLossM: Value(300),
          startLat: Value(42.0),
          startLng: Value(9.0),
          endLat: Value(42.1),
          endLng: Value(9.1),
        ),
        const StagesCompanion(
          trailId: Value('b'),
          stageNumber: Value(1),
          name: Value('B1'),
          distanceKm: Value(12.0),
          elevationGainM: Value(600),
          elevationLossM: Value(400),
          startLat: Value(43.0),
          startLng: Value(10.0),
          endLat: Value(43.1),
          endLng: Value(10.1),
        ),
      ]);

      final container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)],
      );

      final stagesA = await container.read(stagesProvider('a').future);
      final stagesB = await container.read(stagesProvider('b').future);
      expect(stagesA.length, 1);
      expect(stagesB.length, 1);
      expect(stagesA[0].name, 'A1');
      expect(stagesB[0].name, 'B1');

      container.dispose();
      await db.close();
    });
  });
}
