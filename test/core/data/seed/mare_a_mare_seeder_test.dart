import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/data/daos/trail_meta_dao.dart';
import 'package:moteur_gr/core/data/daos/trail_itineraries_dao.dart';
import 'package:moteur_gr/core/data/daos/trail_stages_dao.dart';
import 'package:moteur_gr/core/data/daos/trail_accommodations_dao.dart';
import 'package:moteur_gr/core/data/daos/trail_pois_dao.dart';
import 'package:moteur_gr/core/data/seed/mare_a_mare_seeder.dart';

/// Tests du seeder Mare a Mare Centre.
///
/// Verifie le parsing JSON et l'insertion dans les DAOs
/// sur une base in-memory.
void main() {
  late AppDatabase db;
  late MareAMareSeeder seeder;
  late Map<String, dynamic> jsonData;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    seeder = MareAMareSeeder(db);

    // Charger le JSON depuis le fichier asset
    final file = File('assets/data/mare_a_mare_centre.json');
    final content = await file.readAsString();
    jsonData = json.decode(content) as Map<String, dynamic>;
  });

  tearDown(() async {
    await db.close();
  });

  group('MareAMareSeeder - parsing JSON', () {
    test('le JSON contient trail_meta avec les bons champs', () {
      final meta = jsonData['trail_meta'] as Map<String, dynamic>;
      expect(meta['id'], 'mare-a-mare-centre');
      expect(meta['code'], 'mam-centre');
      expect(meta['dataVersion'], 1);
      expect(meta['status'], 'active');
    });

    test('le JSON contient 1 itineraire Est-Ouest', () {
      final itineraries = jsonData['itineraries'] as List;
      expect(itineraries.length, 1);
      expect(itineraries[0]['code'], 'EW');
      expect(itineraries[0]['stageCount'], 7);
      expect(itineraries[0]['distanceKm'], 84.0);
    });

    test('le JSON contient 7 etapes', () {
      final stages = jsonData['stages'] as List;
      expect(stages.length, 7);
    });

    test('les etapes ont des noms i18n en 5 langues', () {
      final stage = jsonData['stages'][0] as Map<String, dynamic>;
      expect(stage['nameFr'], isNotEmpty);
      expect(stage['nameEn'], isNotEmpty);
      expect(stage['nameDe'], isNotEmpty);
      expect(stage['nameIt'], isNotEmpty);
      expect(stage['nameEs'], isNotEmpty);
    });

    test('les coordonnees GPS sont en Corse', () {
      final stages = jsonData['stages'] as List;
      for (final stage in stages) {
        final s = stage as Map<String, dynamic>;
        // Corse: lat entre 41.3 et 43.1, lng entre 8.5 et 9.6
        expect(s['startLat'], greaterThanOrEqualTo(41.3));
        expect(s['startLat'], lessThanOrEqualTo(43.1));
        expect(s['startLng'], greaterThanOrEqualTo(8.5));
        expect(s['startLng'], lessThanOrEqualTo(9.6));
        expect(s['endLat'], greaterThanOrEqualTo(41.3));
        expect(s['endLat'], lessThanOrEqualTo(43.1));
        expect(s['endLng'], greaterThanOrEqualTo(8.5));
        expect(s['endLng'], lessThanOrEqualTo(9.6));
      }
    });

    test('le JSON contient des hebergements', () {
      final accommodations = jsonData['accommodations'] as List;
      expect(accommodations.length, greaterThanOrEqualTo(7));
    });

    test('le JSON contient des POIs', () {
      final pois = jsonData['pois'] as List;
      expect(pois.length, greaterThanOrEqualTo(7));
    });

    test('les POIs ont des descriptions i18n en 5 langues', () {
      final poi = jsonData['pois'][0] as Map<String, dynamic>;
      expect(poi['descriptionFr'], isNotEmpty);
      expect(poi['descriptionEn'], isNotEmpty);
      expect(poi['descriptionDe'], isNotEmpty);
      expect(poi['descriptionIt'], isNotEmpty);
      expect(poi['descriptionEs'], isNotEmpty);
    });
  });

  group('MareAMareSeeder - insertion en base', () {
    test('seedFromJson insere le trail_meta', () async {
      await seeder.seedFromJson(jsonData);

      final metaDao = TrailMetaDao(db);
      final meta = await metaDao.getById('mare-a-mare-centre');
      expect(meta, isNotNull);
      expect(meta!.code, 'mam-centre');
      expect(meta.dataVersion, 1);
      expect(meta.status, 'active');
    });

    test('seedFromJson insere l itineraire', () async {
      await seeder.seedFromJson(jsonData);

      final itDao = TrailItinerariesDao(db);
      final it = await itDao.getById('mam-centre-ew');
      expect(it, isNotNull);
      expect(it!.code, 'EW');
      expect(it.distanceKm, 84.0);
      expect(it.elevationGain, 3550);
      expect(it.stageCount, 7);
    });

    test('seedFromJson insere les 7 etapes', () async {
      await seeder.seedFromJson(jsonData);

      final stagesDao = TrailStagesDao(db);
      final stages = await stagesDao.getByItineraryId('mam-centre-ew');
      expect(stages.length, 7);
    });

    test('les etapes sont triees par numero', () async {
      await seeder.seedFromJson(jsonData);

      final stagesDao = TrailStagesDao(db);
      final stages = await stagesDao.getByItineraryId('mam-centre-ew');
      for (var i = 0; i < stages.length; i++) {
        expect(stages[i].stageNumber, i + 1);
      }
    });

    test('l etape 1 a les bonnes donnees', () async {
      await seeder.seedFromJson(jsonData);

      final stagesDao = TrailStagesDao(db);
      final s1 = await stagesDao.getById('mam-ew-s1');
      expect(s1, isNotNull);
      expect(s1!.startLat, closeTo(42.0156, 0.001));
      expect(s1.startLng, closeTo(9.4039, 0.001));
      expect(s1.distanceKm, 15.0);
      expect(s1.elevationGain, 850);
      expect(s1.difficulty, 'hard');
    });

    test('l etape 7 descend vers la mer', () async {
      await seeder.seedFromJson(jsonData);

      final stagesDao = TrailStagesDao(db);
      final s7 = await stagesDao.getById('mam-ew-s7');
      expect(s7, isNotNull);
      expect(s7!.endLat, closeTo(41.8903, 0.001));
      expect(s7.endLng, closeTo(8.8128, 0.001));
      expect(s7.difficulty, 'easy');
      expect(s7.durationMinutes, 210);
    });

    test('seedFromJson insere les hebergements', () async {
      await seeder.seedFromJson(jsonData);

      final accDao = TrailAccommodationsDao(db);
      final all = await accDao.getAll();
      expect(all.length, 11);
    });

    test('les hebergements sont lies aux bonnes etapes', () async {
      await seeder.seedFromJson(jsonData);

      final accDao = TrailAccommodationsDao(db);
      final s1Acc = await accDao.getByStageId('mam-ew-s1');
      expect(s1Acc.length, 2);
      expect(s1Acc.any((a) => a.type == 'gite'), isTrue);
      expect(s1Acc.any((a) => a.type == 'camping'), isTrue);
    });

    test('seedFromJson insere les POIs', () async {
      await seeder.seedFromJson(jsonData);

      final poisDao = TrailPoisDao(db);
      final all = await poisDao.getAll();
      expect(all.length, 14);
    });

    test('les POIs sont lies aux bonnes etapes', () async {
      await seeder.seedFromJson(jsonData);

      final poisDao = TrailPoisDao(db);
      final s3Pois = await poisDao.getByStageId('mam-ew-s3');
      expect(s3Pois.length, 2);
      // Sources thermales de Guitera
      expect(s3Pois.any((p) => p.type == 'water'), isTrue);
    });

    test('les POIs water ont des coordonnees realistes', () async {
      await seeder.seedFromJson(jsonData);

      final poisDao = TrailPoisDao(db);
      final waterPois = await poisDao.getByType('water');
      expect(waterPois.length, greaterThanOrEqualTo(3));
      for (final p in waterPois) {
        expect(p.lat, greaterThanOrEqualTo(41.3));
        expect(p.lat, lessThanOrEqualTo(43.1));
        expect(p.lng, greaterThanOrEqualTo(8.5));
        expect(p.lng, lessThanOrEqualTo(9.6));
      }
    });

    test('les noms i18n de l itineraire sont corrects', () async {
      await seeder.seedFromJson(jsonData);

      final itDao = TrailItinerariesDao(db);
      final it = await itDao.getById('mam-centre-ew');
      expect(it!.nameFr, contains('Est-Ouest'));
      expect(it.nameEn, contains('East-West'));
      expect(it.nameDe, contains('Ost-West'));
      expect(it.nameIt, contains('Est-Ovest'));
      expect(it.nameEs, contains('Este-Oeste'));
    });

    test('seedFromJson est idempotent (insertOrReplace)', () async {
      await seeder.seedFromJson(jsonData);
      await seeder.seedFromJson(jsonData);

      final stagesDao = TrailStagesDao(db);
      final stages = await stagesDao.getByItineraryId('mam-centre-ew');
      expect(stages.length, 7);
    });

    test('la distance totale correspond', () async {
      await seeder.seedFromJson(jsonData);

      final stagesDao = TrailStagesDao(db);
      final stages = await stagesDao.getByItineraryId('mam-centre-ew');
      final totalDist = stages.fold<double>(0, (sum, s) => sum + s.distanceKm);
      expect(totalDist, closeTo(84.0, 0.1));
    });

    test('le denivele total correspond', () async {
      await seeder.seedFromJson(jsonData);

      final stagesDao = TrailStagesDao(db);
      final stages = await stagesDao.getByItineraryId('mam-centre-ew');
      final totalGain = stages.fold<int>(0, (sum, s) => sum + s.elevationGain);
      expect(totalGain, 3550);
    });
  });
}
