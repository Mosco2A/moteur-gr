import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/data/revision_de_donnee.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/data/daos/trail_meta_dao.dart';
import 'package:moteur_gr/core/data/daos/trail_itineraries_dao.dart';
import 'package:moteur_gr/core/data/daos/trail_stages_dao.dart';
import 'package:moteur_gr/core/data/daos/trail_accommodations_dao.dart';
import 'package:moteur_gr/core/data/daos/trail_pois_dao.dart';
import 'package:moteur_gr/core/data/seed/trail_seeder.dart';

/// Tests du seeder generique TrailSeeder.
/// Fixture : asset JSON du sentier Mare a Mare Centre (donnees sentier).
///
/// Verifie le parsing JSON et l'insertion dans les DAOs
/// sur une base in-memory.
void main() {
  late AppDatabase db;
  late TrailSeeder seeder;
  late Map<String, dynamic> jsonData;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    seeder = TrailSeeder(db);

    // Charger le JSON depuis le fichier asset
    final file = File('assets/data/mare_a_mare_centre.json');
    final content = await file.readAsString();
    jsonData = json.decode(content) as Map<String, dynamic>;
  });

  tearDown(() async {
    await db.close();
  });

  group('TrailSeeder - parsing JSON', () {
    test('le JSON contient trail_meta avec les bons champs', () {
      final meta = jsonData['trail_meta'] as Map<String, dynamic>;
      expect(meta['id'], 'mare-a-mare-centre');
      expect(meta['code'], 'mam-centre');
      // Le fichier embarque porte encore son ancien compteur : il est LU par le
      // test comme une donnee du fichier, plus par le semeur (tache 610).
      expect(meta['dataVersion'], 1);
      expect(meta['status'], 'active');
    });

    test('le JSON contient 1 itineraire Est-Ouest', () {
      final itineraries = jsonData['itineraries'] as List;
      expect(itineraries.length, 1);
      expect(itineraries[0]['code'], 'EW');
      expect(itineraries[0]['stageCount'], 7);
      // TACHE 761 — 87,3 km mesures sur la trace relevee dans
      // OpenStreetMap, au lieu de 84,0 estimes a la main.
      expect(itineraries[0]['distanceKm'], 87.3);
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

  group('TrailSeeder - insertion en base', () {
    test('seedFromJson insere le trail_meta', () async {
      await seeder.seedFromJson(jsonData);

      final metaDao = TrailMetaDao(db);
      final meta = await metaDao.getById('mare-a-mare-centre');
      expect(meta, isNotNull);
      expect(meta!.code, 'mam-centre');
      // UN SENTIER EMBARQUE N A PAS D HORODATAGE DE SERVEUR : il vaut l ORIGINE,
      // donc tout ce que le serveur publiera pour lui sera plus recent et
      // descendra. Le semeur ne recopie plus l ancien compteur, qui lu comme un
      // instant designerait 1970 (tache 610).
      expect(meta.dataVersion, HorodatageServeur.origine);
      expect(meta.status, 'active');
    });

    test('seedFromJson insere l itineraire', () async {
      await seeder.seedFromJson(jsonData);

      final itDao = TrailItinerariesDao(db);
      final it = await itDao.getById('mam-centre-ew');
      expect(it, isNotNull);
      expect(it!.code, 'EW');
      // TACHE 761 — les deux totaux sont desormais MESURES sur la trace.
      expect(it.distanceKm, 87.3);
      expect(it.elevationGain, 4274);
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
      // TACHE 761 — LE DEPART EST DESORMAIS SUR LE CHEMIN, ET AU BORD DE
      // L EAU. Le point declare (42,0156 / 9,4039) etait le CENTRE DU VILLAGE
      // de Ghisonaccia, a 4,4 km du sentier ; un sentier « de la mer a la mer »
      // part de la mer, et le premier point de la trace relevee est a 5,4 m
      // d altitude. Les chiffres de l etape suivent : 19,9 km mesures au lieu
      // de 15,0 estimes, 1 058 m de D+ calcules sur le profil du terrain.
      expect(s1!.startLat, closeTo(41.9757, 0.001));
      expect(s1.startLng, closeTo(9.3994, 0.001));
      expect(s1.distanceKm, 19.9);
      expect(s1.elevationGain, 1058);
      expect(s1.difficulty, 'hard');
    });

    test('l etape 7 descend vers la mer', () async {
      await seeder.seedFromJson(jsonData);

      final stagesDao = TrailStagesDao(db);
      final s7 = await stagesDao.getById('mam-ew-s7');
      expect(s7, isNotNull);
      // TACHE 761 — L ARRIVEE EST LE DERNIER POINT DE LA TRACE, a 1,4 m
      // d altitude : la plage de Porticcio. Le point declare tombait a 77 m de
      // la, l ecart est donc minime ; la duree, elle, passe de 210 a 175 min
      // parce que l etape mesure 11,1 km pour seulement 54 m de montee — c est
      // la plus longue descente du sentier, 898 m perdus vers la mer.
      expect(s7!.endLat, closeTo(41.8900, 0.001));
      expect(s7.endLng, closeTo(8.8030, 0.001));
      expect(s7.difficulty, 'easy');
      expect(s7.durationMinutes, 175);
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
      expect(totalDist, closeTo(87.3, 0.1));
    });

    test('le denivele total correspond', () async {
      await seeder.seedFromJson(jsonData);

      final stagesDao = TrailStagesDao(db);
      final stages = await stagesDao.getByItineraryId('mam-centre-ew');
      final totalGain = stages.fold<int>(0, (sum, s) => sum + s.elevationGain);
      // TACHE 761 — LES 3 550 ET LES 3 750 SONT RECONCILIES. Les deux
      // etaient des sommes justes de sept etapes, mais de DEUX
      // DECOUPAGES DIFFERENTS : stages.json et mare_a_mare_centre.json ne
      // nommaient pas les memes villages. Les deux fichiers portent
      // maintenant le meme decoupage, mesure sur la trace.
      expect(totalGain, 4274);
    });
  });
}
