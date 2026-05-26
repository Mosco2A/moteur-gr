import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/data/daos/stages_dao.dart';
import 'package:moteur_gr/core/data/daos/pois_dao.dart';

/// Tests du chargement de donnees (logique utilisee par DownloadNotifier).
///
/// On teste la logique d'insertion directement sur les DAOs
/// car DownloadNotifier depend de rootBundle (assets Flutter).
void main() {
  group('Download logic', () {
    test('insertion batch de stages fonctionne', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final dao = StagesDao(db);

      final stages = List.generate(10, (i) => StagesCompanion(
        trailId: const Value('batch_test'),
        stageNumber: Value(i + 1),
        name: Value('Etape ${i + 1}'),
        distanceKm: Value(10.0 + i),
        elevationGainM: Value(500 + i * 100),
        elevationLossM: Value(300 + i * 50),
        description: Value('Description ${i + 1}'),
        startLat: Value(42.0 + i * 0.01),
        startLng: Value(9.0 + i * 0.01),
        endLat: Value(42.01 + i * 0.01),
        endLng: Value(9.01 + i * 0.01),
        difficulty: const Value('moderate'),
      ));

      await dao.insertAll(stages);
      final result = await dao.getByTrailId('batch_test');
      expect(result.length, 10);
      expect(result.first.stageNumber, 1);
      expect(result.last.stageNumber, 10);

      await db.close();
    });

    test('insertion batch de POI fonctionne', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final dao = PoisDao(db);

      final types = ['shelter', 'water', 'viewpoint', 'campsite', 'restaurant'];
      final pois = List.generate(5, (i) => PoisCompanion(
        trailId: const Value('batch_test'),
        stageNumber: Value(i + 1),
        name: Value('POI ${i + 1}'),
        description: Value('Desc ${i + 1}'),
        type: Value(types[i]),
        lat: Value(42.0 + i * 0.01),
        lng: Value(9.0 + i * 0.01),
        altitudeM: Value(1000 + i * 200),
      ));

      await dao.insertAll(pois);
      final result = await dao.getByTrailId('batch_test');
      expect(result.length, 5);

      await db.close();
    });

    test('rechargement : delete puis re-insert', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final dao = StagesDao(db);

      // Premiere insertion
      await dao.insertAll([
        const StagesCompanion(
          trailId: Value('reload'),
          stageNumber: Value(1),
          name: Value('V1'),
          distanceKm: Value(10.0),
          elevationGainM: Value(500),
          elevationLossM: Value(300),
          startLat: Value(42.0),
          startLng: Value(9.0),
          endLat: Value(42.1),
          endLng: Value(9.1),
        ),
      ]);

      // Suppression + re-insertion (comme DownloadNotifier)
      await dao.deleteByTrailId('reload');
      await dao.insertAll([
        const StagesCompanion(
          trailId: Value('reload'),
          stageNumber: Value(1),
          name: Value('V2'),
          distanceKm: Value(12.0),
          elevationGainM: Value(600),
          elevationLossM: Value(400),
          startLat: Value(42.0),
          startLng: Value(9.0),
          endLat: Value(42.1),
          endLng: Value(9.1),
        ),
      ]);

      final result = await dao.getByTrailId('reload');
      expect(result.length, 1);
      expect(result.first.name, 'V2');
      expect(result.first.distanceKm, 12.0);

      await db.close();
    });

    test('les differents sentiers sont isoles', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final stagesDao = StagesDao(db);
      final poisDao = PoisDao(db);

      // Sentier A
      await stagesDao.insertAll([
        const StagesCompanion(
          trailId: Value('sentierA'),
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
      ]);
      await poisDao.insertAll([
        const PoisCompanion(
          trailId: Value('sentierA'),
          stageNumber: Value(1),
          name: Value('POI A'),
          type: Value('shelter'),
          lat: Value(42.0),
          lng: Value(9.0),
        ),
      ]);

      // Sentier B
      await stagesDao.insertAll([
        const StagesCompanion(
          trailId: Value('sentierB'),
          stageNumber: Value(1),
          name: Value('B1'),
          distanceKm: Value(15.0),
          elevationGainM: Value(700),
          elevationLossM: Value(500),
          startLat: Value(43.0),
          startLng: Value(10.0),
          endLat: Value(43.1),
          endLng: Value(10.1),
        ),
      ]);

      // Supprimer A ne touche pas B
      await stagesDao.deleteByTrailId('sentierA');
      await poisDao.deleteByTrailId('sentierA');

      final stagesA = await stagesDao.getByTrailId('sentierA');
      final stagesB = await stagesDao.getByTrailId('sentierB');
      final poisA = await poisDao.getByTrailId('sentierA');

      expect(stagesA, isEmpty);
      expect(stagesB.length, 1);
      expect(poisA, isEmpty);

      await db.close();
    });
  });
}
