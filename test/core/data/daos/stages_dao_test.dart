import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/data/daos/stages_dao.dart';

/// Tests du DAO Stages sur une base in-memory.
void main() {
  late AppDatabase db;
  late StagesDao dao;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dao = StagesDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  /// Helper : cree un companion d'etape de test
  StagesCompanion makeStage({
    required String trailId,
    required int stageNumber,
    String name = 'Etape Test',
    double distanceKm = 10.0,
    int elevationGainM = 500,
    int elevationLossM = 300,
    String difficulty = 'moderate',
  }) {
    return StagesCompanion(
      trailId: Value(trailId),
      stageNumber: Value(stageNumber),
      name: Value(name),
      distanceKm: Value(distanceKm),
      elevationGainM: Value(elevationGainM),
      elevationLossM: Value(elevationLossM),
      description: const Value('Description test'),
      startLat: const Value(42.0),
      startLng: const Value(9.0),
      endLat: const Value(42.1),
      endLng: const Value(9.1),
      difficulty: Value(difficulty),
    );
  }

  group('StagesDao', () {
    test('insertAll insere les etapes correctement', () async {
      final stages = [
        makeStage(trailId: 'trail1', stageNumber: 1, name: 'Etape 1'),
        makeStage(trailId: 'trail1', stageNumber: 2, name: 'Etape 2'),
        makeStage(trailId: 'trail1', stageNumber: 3, name: 'Etape 3'),
      ];
      await dao.insertAll(stages);

      final result = await dao.getByTrailId('trail1');
      expect(result.length, 3);
    });

    test('getByTrailId retourne les etapes triees par numero', () async {
      await dao.insertAll([
        makeStage(trailId: 'trail1', stageNumber: 3, name: 'Trois'),
        makeStage(trailId: 'trail1', stageNumber: 1, name: 'Un'),
        makeStage(trailId: 'trail1', stageNumber: 2, name: 'Deux'),
      ]);

      final result = await dao.getByTrailId('trail1');
      expect(result[0].name, 'Un');
      expect(result[1].name, 'Deux');
      expect(result[2].name, 'Trois');
    });

    test('getByTrailId retourne vide si aucun sentier', () async {
      final result = await dao.getByTrailId('inexistant');
      expect(result, isEmpty);
    });

    test('getByTrailId filtre par sentier', () async {
      await dao.insertAll([
        makeStage(trailId: 'trail1', stageNumber: 1),
        makeStage(trailId: 'trail2', stageNumber: 1),
        makeStage(trailId: 'trail1', stageNumber: 2),
      ]);

      final result1 = await dao.getByTrailId('trail1');
      final result2 = await dao.getByTrailId('trail2');
      expect(result1.length, 2);
      expect(result2.length, 1);
    });

    test('getByStageNumber retourne la bonne etape', () async {
      await dao.insertAll([
        makeStage(trailId: 'trail1', stageNumber: 1, name: 'Premiere'),
        makeStage(trailId: 'trail1', stageNumber: 2, name: 'Deuxieme'),
      ]);

      final result = await dao.getByStageNumber('trail1', 2);
      expect(result, isNotNull);
      expect(result!.name, 'Deuxieme');
    });

    test('getByStageNumber retourne null si etape inexistante', () async {
      await dao.insertAll([
        makeStage(trailId: 'trail1', stageNumber: 1),
      ]);

      final result = await dao.getByStageNumber('trail1', 99);
      expect(result, isNull);
    });

    test('deleteByTrailId supprime les etapes du bon sentier', () async {
      await dao.insertAll([
        makeStage(trailId: 'trail1', stageNumber: 1),
        makeStage(trailId: 'trail1', stageNumber: 2),
        makeStage(trailId: 'trail2', stageNumber: 1),
      ]);

      final deleted = await dao.deleteByTrailId('trail1');
      expect(deleted, 2);

      final remaining = await dao.getByTrailId('trail2');
      expect(remaining.length, 1);
    });

    test('deleteByTrailId retourne 0 si rien a supprimer', () async {
      final deleted = await dao.deleteByTrailId('inexistant');
      expect(deleted, 0);
    });

    test('les champs numeriques sont corrects apres insertion', () async {
      await dao.insertAll([
        makeStage(
          trailId: 'trail1',
          stageNumber: 1,
          distanceKm: 15.5,
          elevationGainM: 1200,
          elevationLossM: 800,
          difficulty: 'hard',
        ),
      ]);

      final result = await dao.getByStageNumber('trail1', 1);
      expect(result!.distanceKm, 15.5);
      expect(result.elevationGainM, 1200);
      expect(result.elevationLossM, 800);
      expect(result.difficulty, 'hard');
    });
  });
}
