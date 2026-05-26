import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/data/daos/stages_dao.dart';
import 'package:moteur_gr/core/models/stage.dart';

/// Tests du modele StageModel (fromJson, toCompanion, fromDb roundtrip).
void main() {
  group('StageModel', () {
    test('fromJson deserialisecorrectement', () {
      final json = {
        'id': 1,
        'trailId': 'trail1',
        'stageNumber': 3,
        'name': 'Col de Bavella',
        'distanceKm': 15.5,
        'elevationGainM': 1200,
        'elevationLossM': 800,
        'description': 'Etape spectaculaire',
        'startLat': 42.15,
        'startLng': 9.10,
        'endLat': 42.20,
        'endLng': 9.15,
        'difficulty': 'hard',
      };

      final model = StageModel.fromJson(json);
      expect(model.trailId, 'trail1');
      expect(model.stageNumber, 3);
      expect(model.name, 'Col de Bavella');
      expect(model.distanceKm, 15.5);
      expect(model.difficulty, 'hard');
    });

    test('fromJson avec valeurs par defaut', () {
      final json = {
        'trailId': 'trail1',
        'stageNumber': 1,
        'name': 'Depart',
        'distanceKm': 10.0,
        'elevationGainM': 500,
        'elevationLossM': 300,
        'startLat': 42.0,
        'startLng': 9.0,
        'endLat': 42.1,
        'endLng': 9.1,
      };

      final model = StageModel.fromJson(json);
      expect(model.id, 0);
      expect(model.description, '');
      expect(model.difficulty, 'moderate');
    });

    test('toCompanion genere un companion Drift valide', () {
      const model = StageModel(
        trailId: 'trail1',
        stageNumber: 2,
        name: 'Etape 2',
        distanceKm: 12.0,
        elevationGainM: 600,
        elevationLossM: 400,
        startLat: 42.1,
        startLng: 9.05,
        endLat: 42.15,
        endLng: 9.1,
      );

      final companion = model.toCompanion();
      expect(companion.trailId.value, 'trail1');
      expect(companion.stageNumber.value, 2);
      expect(companion.name.value, 'Etape 2');
      expect(companion.distanceKm.value, 12.0);
    });

    test('fromDb roundtrip : insertion puis lecture', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final dao = StagesDao(db);

      const original = StageModel(
        trailId: 'roundtrip',
        stageNumber: 1,
        name: 'Roundtrip Test',
        distanceKm: 8.5,
        elevationGainM: 450,
        elevationLossM: 250,
        description: 'Test roundtrip',
        startLat: 42.0,
        startLng: 9.0,
        endLat: 42.05,
        endLng: 9.05,
        difficulty: 'easy',
      );

      await dao.insertAll([original.toCompanion()]);
      final rows = await dao.getByTrailId('roundtrip');
      final restored = StageModel.fromDb(rows.first);

      expect(restored.trailId, original.trailId);
      expect(restored.stageNumber, original.stageNumber);
      expect(restored.name, original.name);
      expect(restored.distanceKm, original.distanceKm);
      expect(restored.elevationGainM, original.elevationGainM);
      expect(restored.elevationLossM, original.elevationLossM);
      expect(restored.description, original.description);
      expect(restored.difficulty, original.difficulty);

      await db.close();
    });

    test('equality fonctionne avec freezed', () {
      const a = StageModel(
        trailId: 't1', stageNumber: 1, name: 'A',
        distanceKm: 10, elevationGainM: 500, elevationLossM: 300,
        startLat: 42.0, startLng: 9.0, endLat: 42.1, endLng: 9.1,
      );
      const b = StageModel(
        trailId: 't1', stageNumber: 1, name: 'A',
        distanceKm: 10, elevationGainM: 500, elevationLossM: 300,
        startLat: 42.0, startLng: 9.0, endLat: 42.1, endLng: 9.1,
      );
      expect(a, equals(b));
    });

    test('copyWith modifie un champ sans toucher les autres', () {
      const model = StageModel(
        trailId: 't1', stageNumber: 1, name: 'Original',
        distanceKm: 10, elevationGainM: 500, elevationLossM: 300,
        startLat: 42.0, startLng: 9.0, endLat: 42.1, endLng: 9.1,
      );
      final modified = model.copyWith(name: 'Modifie');
      expect(modified.name, 'Modifie');
      expect(modified.trailId, 't1');
    });
  });
}
