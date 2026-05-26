import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/data/daos/pois_dao.dart';

/// Tests du DAO Pois sur une base in-memory.
void main() {
  late AppDatabase db;
  late PoisDao dao;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dao = PoisDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  /// Helper : cree un companion POI de test
  PoisCompanion makePoi({
    required String trailId,
    required int stageNumber,
    String name = 'POI Test',
    String type = 'shelter',
    double lat = 42.0,
    double lng = 9.0,
    int altitudeM = 1000,
    String? openingHours,
  }) {
    return PoisCompanion(
      trailId: Value(trailId),
      stageNumber: Value(stageNumber),
      name: Value(name),
      description: const Value('Description POI'),
      type: Value(type),
      lat: Value(lat),
      lng: Value(lng),
      altitudeM: Value(altitudeM),
      openingHours: Value(openingHours),
    );
  }

  group('PoisDao', () {
    test('insertAll insere les POI correctement', () async {
      await dao.insertAll([
        makePoi(trailId: 'trail1', stageNumber: 1, name: 'Refuge'),
        makePoi(trailId: 'trail1', stageNumber: 1, name: 'Source'),
        makePoi(trailId: 'trail1', stageNumber: 2, name: 'Panorama'),
      ]);

      final result = await dao.getByTrailId('trail1');
      expect(result.length, 3);
    });

    test('getByTrailId retourne tous les POI du sentier', () async {
      await dao.insertAll([
        makePoi(trailId: 'trail1', stageNumber: 1),
        makePoi(trailId: 'trail1', stageNumber: 2),
        makePoi(trailId: 'trail2', stageNumber: 1),
      ]);

      final result = await dao.getByTrailId('trail1');
      expect(result.length, 2);
    });

    test('getByTrailId retourne vide si aucun POI', () async {
      final result = await dao.getByTrailId('inexistant');
      expect(result, isEmpty);
    });

    test('getByStage filtre par sentier et etape', () async {
      await dao.insertAll([
        makePoi(trailId: 'trail1', stageNumber: 1, name: 'A'),
        makePoi(trailId: 'trail1', stageNumber: 1, name: 'B'),
        makePoi(trailId: 'trail1', stageNumber: 2, name: 'C'),
      ]);

      final result = await dao.getByStage('trail1', 1);
      expect(result.length, 2);
    });

    test('getByStage retourne vide si etape sans POI', () async {
      await dao.insertAll([
        makePoi(trailId: 'trail1', stageNumber: 1),
      ]);

      final result = await dao.getByStage('trail1', 99);
      expect(result, isEmpty);
    });

    test('deleteByTrailId supprime les POI du bon sentier', () async {
      await dao.insertAll([
        makePoi(trailId: 'trail1', stageNumber: 1),
        makePoi(trailId: 'trail1', stageNumber: 2),
        makePoi(trailId: 'trail2', stageNumber: 1),
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

    test('les champs textuels et nullable sont corrects', () async {
      await dao.insertAll([
        makePoi(
          trailId: 'trail1',
          stageNumber: 1,
          name: 'Refuge du Col',
          type: 'shelter',
          altitudeM: 1500,
          openingHours: 'Juin-Sept',
        ),
      ]);

      final result = await dao.getByStage('trail1', 1);
      expect(result[0].name, 'Refuge du Col');
      expect(result[0].type, 'shelter');
      expect(result[0].altitudeM, 1500);
      expect(result[0].openingHours, 'Juin-Sept');
    });

    test('openingHours nullable fonctionne', () async {
      await dao.insertAll([
        makePoi(trailId: 'trail1', stageNumber: 1, openingHours: null),
      ]);

      final result = await dao.getByStage('trail1', 1);
      expect(result[0].openingHours, isNull);
    });
  });
}
