import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/data/daos/stages_dao.dart';
import 'package:moteur_gr/core/models/stage.dart';
import 'package:moteur_gr/core/models/stage_duration.dart';

/// Tests du SOCLE « donnees externes » — champ riche duree par etape (parite
/// GR20). Couvre :
///   - la source unique [stageDurationMinutes] : donnee du sentier prioritaire,
///     sinon estimation Naismith (repli documente) ;
///   - la ROBUSTESSE aux champs nuls (sentier pauvre -> pas de crash, affichage
///     degrade coherent) prouvee de bout en bout (modele + DB roundtrip) ;
///   - le formatage « XhMM » ;
///   - les agregats (totaux jour/itineraire) respectant la donnee par etape.
void main() {
  // Etape SANS duree fournie (sentier pauvre, ex. test-trail) : le champ reste
  // nul -> l'affichage retombe sur l'estimation.
  const stageSansDuree = StageModel(
    trailId: 'test-trail',
    stageNumber: 1,
    name: 'Etape sans duree',
    distanceKm: 12.0,
    elevationGainM: 400,
    elevationLossM: 300,
    startLat: 42.0,
    startLng: 9.0,
    endLat: 42.1,
    endLng: 9.1,
  );

  // Etape AVEC duree fournie par la donnee du sentier : elle fait autorite,
  // meme si elle differe de l'estimation.
  const stageAvecDuree = StageModel(
    trailId: 'mare-a-mare-centre',
    stageNumber: 1,
    name: 'Etape avec duree',
    distanceKm: 15.0,
    elevationGainM: 850,
    elevationLossM: 100,
    startLat: 42.0,
    startLng: 9.4,
    endLat: 41.9,
    endLng: 9.3,
    estimatedDurationMinutes: 350,
  );

  group('stageDurationMinutes — source unique de verite', () {
    test('utilise la duree du sentier quand elle est fournie', () {
      // Donnee = 350 min ; estimation = 15/4 + 850/400 h = 5.875 h = 352.5 min.
      // La DONNEE doit primer sur l'estimation.
      expect(stageDurationMinutes(stageAvecDuree), 350);
      expect(hasProvidedDuration(stageAvecDuree), isTrue);
    });

    test('retombe sur l estimation Naismith quand la duree est nulle', () {
      // 12/4 + 400/400 = 3 + 1 = 4 h = 240 min.
      expect(stageDurationMinutes(stageSansDuree), 240);
      expect(hasProvidedDuration(stageSansDuree), isFalse);
    });

    test('une duree fournie <= 0 est ignoree (repli sur estimation)', () {
      const stageDureeZero = StageModel(
        trailId: 't',
        stageNumber: 1,
        name: 'x',
        distanceKm: 8.0,
        elevationGainM: 0,
        elevationLossM: 0,
        startLat: 0,
        startLng: 0,
        endLat: 0,
        endLng: 0,
        estimatedDurationMinutes: 0,
      );
      // 8/4 + 0 = 2 h = 120 min (estimation, car 0 est ignore).
      expect(stageDurationMinutes(stageDureeZero), 120);
      expect(hasProvidedDuration(stageDureeZero), isFalse);
    });
  });

  group('estimatedStageDurationMinutes — regle de marche Naismith', () {
    test('15 min/km a plat + 15 min/100 m de montee', () {
      expect(
        estimatedStageDurationMinutes(distanceKm: 4.0, elevationGainM: 0),
        60,
      );
      expect(
        estimatedStageDurationMinutes(distanceKm: 0.0, elevationGainM: 400),
        60,
      );
      expect(
        estimatedStageDurationMinutes(distanceKm: 10.0, elevationGainM: 200),
        180,
      );
    });
  });

  group('formatDurationMinutes — « Xh » / « XhMM »', () {
    test('formate heures et minutes avec padding', () {
      expect(formatDurationMinutes(350), '5h50');
      expect(formatDurationMinutes(240), '4h');
      expect(formatDurationMinutes(65), '1h05');
      expect(formatDurationMinutes(0), '0h');
    });
  });

  group('totalStagesDurationMinutes — agregat par etape', () {
    test('somme en respectant la donnee ou l estimation de chaque etape', () {
      // 350 (fournie) + 240 (estimee) = 590.
      expect(
        totalStagesDurationMinutes([stageAvecDuree, stageSansDuree]),
        590,
      );
    });
  });

  group('ROBUSTESSE champs nuls — DB roundtrip (fallback gracieux)', () {
    test('un StageModel sans duree survit a un aller-retour DB sans crash',
        () async {
      final db = AppDatabase(NativeDatabase.memory());
      final dao = StagesDao(db);

      await dao.insertAll([stageSansDuree.toCompanion()]);
      final rows = await dao.getByTrailId('test-trail');
      final restored = StageModel.fromDb(rows.first);

      // La colonne est bien NULL en base (aucune valeur forcee).
      expect(restored.estimatedDurationMinutes, isNull);
      // ... et l'affichage retombe proprement sur l'estimation.
      expect(stageDurationMinutes(restored), 240);
      expect(formatDurationMinutes(stageDurationMinutes(restored)), '4h');

      await db.close();
    });

    test('un StageModel AVEC duree persiste et relit la valeur exacte',
        () async {
      final db = AppDatabase(NativeDatabase.memory());
      final dao = StagesDao(db);

      await dao.insertAll([stageAvecDuree.toCompanion()]);
      final rows = await dao.getByTrailId('mare-a-mare-centre');
      final restored = StageModel.fromDb(rows.first);

      expect(restored.estimatedDurationMinutes, 350);
      expect(stageDurationMinutes(restored), 350);

      await db.close();
    });
  });

  group('JSON — deserialisation du champ optionnel', () {
    test('fromJson lit estimatedDurationMinutes quand present', () {
      final model = StageModel.fromJson({
        'trailId': 't',
        'stageNumber': 1,
        'name': 'x',
        'distanceKm': 10.0,
        'elevationGainM': 400,
        'elevationLossM': 300,
        'startLat': 0.0,
        'startLng': 0.0,
        'endLat': 0.0,
        'endLng': 0.0,
        'estimatedDurationMinutes': 210,
      });
      expect(model.estimatedDurationMinutes, 210);
    });

    test('fromJson laisse le champ nul quand absent', () {
      final model = StageModel.fromJson({
        'trailId': 't',
        'stageNumber': 1,
        'name': 'x',
        'distanceKm': 10.0,
        'elevationGainM': 400,
        'elevationLossM': 300,
        'startLat': 0.0,
        'startLng': 0.0,
        'endLat': 0.0,
        'endLng': 0.0,
      });
      expect(model.estimatedDurationMinutes, isNull);
    });
  });
}
