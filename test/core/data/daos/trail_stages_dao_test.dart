import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/data/daos/trail_stages_dao.dart';

/// Tests du DAO TrailStages sur une base in-memory.
void main() {
  late AppDatabase db;
  late TrailStagesDao dao;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dao = TrailStagesDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  /// Helper : cree un companion TrailStages de test
  TrailStagesCompanion makeStage({
    required String id,
    required String itineraryId,
    required int stageNumber,
    String nameFr = 'Etape Test',
    String nameEn = 'Test Stage',
    String nameDe = 'Teststufe',
    String nameIt = 'Tappa Test',
    String nameEs = 'Etapa Test',
    double distanceKm = 12.0,
    int elevationGain = 800,
    int elevationLoss = 500,
    int durationMinutes = 360,
    String difficulty = 'moderate',
  }) {
    return TrailStagesCompanion(
      id: Value(id),
      itineraryId: Value(itineraryId),
      stageNumber: Value(stageNumber),
      nameFr: Value(nameFr),
      nameEn: Value(nameEn),
      nameDe: Value(nameDe),
      nameIt: Value(nameIt),
      nameEs: Value(nameEs),
      startLat: const Value(42.0),
      startLng: const Value(9.0),
      endLat: const Value(42.1),
      endLng: const Value(9.1),
      distanceKm: Value(distanceKm),
      elevationGain: Value(elevationGain),
      elevationLoss: Value(elevationLoss),
      durationMinutes: Value(durationMinutes),
      difficulty: Value(difficulty),
    );
  }

  group('TrailStagesDao', () {
    test('insertOrReplace puis getById retourne la bonne etape', () async {
      await dao.insertOrReplace(
        makeStage(id: 's1', itineraryId: 'it1', stageNumber: 1),
      );

      final result = await dao.getById('s1');
      expect(result, isNotNull);
      expect(result!.nameFr, 'Etape Test');
      expect(result.nameEn, 'Test Stage');
      expect(result.stageNumber, 1);
    });

    test('getByItineraryId retourne les etapes triees par numero', () async {
      await dao.insertOrReplace(
        makeStage(id: 's3', itineraryId: 'it1', stageNumber: 3, nameFr: 'Trois'),
      );
      await dao.insertOrReplace(
        makeStage(id: 's1', itineraryId: 'it1', stageNumber: 1, nameFr: 'Un'),
      );
      await dao.insertOrReplace(
        makeStage(id: 's2', itineraryId: 'it1', stageNumber: 2, nameFr: 'Deux'),
      );

      final result = await dao.getByItineraryId('it1');
      expect(result.length, 3);
      expect(result[0].nameFr, 'Un');
      expect(result[1].nameFr, 'Deux');
      expect(result[2].nameFr, 'Trois');
    });

    test('getByItineraryId filtre par itineraire', () async {
      await dao.insertOrReplace(
        makeStage(id: 's1', itineraryId: 'it1', stageNumber: 1),
      );
      await dao.insertOrReplace(
        makeStage(id: 's2', itineraryId: 'it2', stageNumber: 1),
      );
      await dao.insertOrReplace(
        makeStage(id: 's3', itineraryId: 'it1', stageNumber: 2),
      );

      final result1 = await dao.getByItineraryId('it1');
      final result2 = await dao.getByItineraryId('it2');
      expect(result1.length, 2);
      expect(result2.length, 1);
    });

    test('getByItineraryId retourne vide si aucun itineraire', () async {
      final result = await dao.getByItineraryId('inexistant');
      expect(result, isEmpty);
    });

    test('deleteById supprime la bonne etape', () async {
      await dao.insertOrReplace(
        makeStage(id: 's1', itineraryId: 'it1', stageNumber: 1),
      );
      await dao.insertOrReplace(
        makeStage(id: 's2', itineraryId: 'it1', stageNumber: 2),
      );

      final deleted = await dao.deleteById('s1');
      expect(deleted, 1);

      final remaining = await dao.getAll();
      expect(remaining.length, 1);
      expect(remaining.first.id, 's2');
    });

    test('les champs i18n sont corrects apres insertion', () async {
      await dao.insertOrReplace(makeStage(
        id: 's1',
        itineraryId: 'it1',
        stageNumber: 1,
        nameFr: 'Calenzana - Ortu di u Piobbu',
        nameEn: 'Calenzana to Ortu di u Piobbu',
        nameDe: 'Calenzana nach Ortu di u Piobbu',
        nameIt: 'Calenzana - Ortu di u Piobbu',
        nameEs: 'Calenzana a Ortu di u Piobbu',
      ));

      final result = await dao.getById('s1');
      expect(result!.nameFr, 'Calenzana - Ortu di u Piobbu');
      expect(result.nameEn, 'Calenzana to Ortu di u Piobbu');
      expect(result.nameDe, 'Calenzana nach Ortu di u Piobbu');
      expect(result.nameIt, 'Calenzana - Ortu di u Piobbu');
      expect(result.nameEs, 'Calenzana a Ortu di u Piobbu');
    });

    test('les champs numeriques sont corrects apres insertion', () async {
      await dao.insertOrReplace(makeStage(
        id: 's1',
        itineraryId: 'it1',
        stageNumber: 1,
        distanceKm: 15.5,
        elevationGain: 1200,
        elevationLoss: 800,
        durationMinutes: 480,
        difficulty: 'hard',
      ));

      final result = await dao.getById('s1');
      expect(result!.distanceKm, 15.5);
      expect(result.elevationGain, 1200);
      expect(result.elevationLoss, 800);
      expect(result.durationMinutes, 480);
      expect(result.difficulty, 'hard');
    });
  });
}
