import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/data/daos/trail_pois_dao.dart';

/// Tests du DAO TrailPois sur une base in-memory.
void main() {
  late AppDatabase db;
  late TrailPoisDao dao;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dao = TrailPoisDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  /// Helper : cree un companion TrailPois de test
  TrailPoisCompanion makePoi({
    required String id,
    required String stageId,
    String nameFr = 'Point Test',
    String nameEn = 'Test Point',
    String nameDe = 'Testpunkt',
    String nameIt = 'Punto Test',
    String nameEs = 'Punto Test',
    String type = 'water',
    double lat = 42.0,
    double lng = 9.0,
    double? elevation,
    String? descriptionFr,
  }) {
    return TrailPoisCompanion(
      id: Value(id),
      stageId: Value(stageId),
      nameFr: Value(nameFr),
      nameEn: Value(nameEn),
      nameDe: Value(nameDe),
      nameIt: Value(nameIt),
      nameEs: Value(nameEs),
      type: Value(type),
      lat: Value(lat),
      lng: Value(lng),
      elevation: Value(elevation),
      descriptionFr: Value(descriptionFr),
    );
  }

  group('TrailPoisDao', () {
    test('insertOrReplace puis getById retourne le bon POI', () async {
      await dao.insertOrReplace(
        makePoi(id: 'p1', stageId: 's1', nameFr: 'Source Spasimata'),
      );

      final result = await dao.getById('p1');
      expect(result, isNotNull);
      expect(result!.nameFr, 'Source Spasimata');
      expect(result.type, 'water');
    });

    test('getByStageId retourne les POI de la bonne etape', () async {
      await dao.insertOrReplace(makePoi(id: 'p1', stageId: 's1'));
      await dao.insertOrReplace(makePoi(id: 'p2', stageId: 's1'));
      await dao.insertOrReplace(makePoi(id: 'p3', stageId: 's2'));

      final result1 = await dao.getByStageId('s1');
      final result2 = await dao.getByStageId('s2');
      expect(result1.length, 2);
      expect(result2.length, 1);
    });

    test('getByType retourne les POI du bon type', () async {
      await dao.insertOrReplace(
        makePoi(id: 'p1', stageId: 's1', type: 'water'),
      );
      await dao.insertOrReplace(
        makePoi(id: 'p2', stageId: 's1', type: 'viewpoint'),
      );
      await dao.insertOrReplace(
        makePoi(id: 'p3', stageId: 's2', type: 'water'),
      );

      final waterPois = await dao.getByType('water');
      final viewpoints = await dao.getByType('viewpoint');
      expect(waterPois.length, 2);
      expect(viewpoints.length, 1);
    });

    test('getByStageId retourne vide si aucun POI', () async {
      final result = await dao.getByStageId('inexistant');
      expect(result, isEmpty);
    });

    test('deleteById supprime le bon POI', () async {
      await dao.insertOrReplace(makePoi(id: 'p1', stageId: 's1'));
      await dao.insertOrReplace(makePoi(id: 'p2', stageId: 's1'));

      final deleted = await dao.deleteById('p1');
      expect(deleted, 1);

      final remaining = await dao.getAll();
      expect(remaining.length, 1);
      expect(remaining.first.id, 'p2');
    });

    test('deleteAll supprime tous les POI', () async {
      await dao.insertOrReplace(makePoi(id: 'p1', stageId: 's1'));
      await dao.insertOrReplace(makePoi(id: 'p2', stageId: 's1'));

      final deleted = await dao.deleteAll();
      expect(deleted, 2);

      final remaining = await dao.getAll();
      expect(remaining, isEmpty);
    });

    test('elevation nullable fonctionne', () async {
      await dao.insertOrReplace(
        makePoi(id: 'p1', stageId: 's1', elevation: 1540.5),
      );
      await dao.insertOrReplace(
        makePoi(id: 'p2', stageId: 's1'),
      );

      final withElev = await dao.getById('p1');
      final withoutElev = await dao.getById('p2');
      expect(withElev!.elevation, 1540.5);
      expect(withoutElev!.elevation, isNull);
    });

    test('les champs i18n description sont corrects', () async {
      await dao.insertOrReplace(TrailPoisCompanion(
        id: const Value('p1'),
        stageId: const Value('s1'),
        nameFr: const Value('Bergerie'),
        nameEn: const Value('Sheepfold'),
        nameDe: const Value('Schaeferei'),
        nameIt: const Value('Ovile'),
        nameEs: const Value('Redil'),
        descriptionFr: const Value('Ancienne bergerie en ruine'),
        descriptionEn: const Value('Ancient ruined sheepfold'),
        descriptionDe: const Value('Alte Schaeferei-Ruine'),
        descriptionIt: const Value('Antico ovile in rovina'),
        descriptionEs: const Value('Antiguo redil en ruinas'),
        type: const Value('info'),
        lat: const Value(42.1),
        lng: const Value(9.1),
      ));

      final result = await dao.getById('p1');
      expect(result!.descriptionFr, 'Ancienne bergerie en ruine');
      expect(result.descriptionEn, 'Ancient ruined sheepfold');
      expect(result.descriptionDe, 'Alte Schaeferei-Ruine');
      expect(result.descriptionIt, 'Antico ovile in rovina');
      expect(result.descriptionEs, 'Antiguo redil en ruinas');
    });
  });
}
