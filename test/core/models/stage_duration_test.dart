import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/data/daos/stages_dao.dart';
import 'package:moteur_gr/core/models/stage_row.dart';
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

    test('retombe sur le modele unique quand la duree est nulle', () {
      // LA DESCENTE EST PAYEE DEPUIS LA TACHE 839, et ce cas le prouve sur une
      // etape qui la connait : 12 km a 4 km/h = 10 800 s, plus 400 m de montee
      // a 9 s/m = 3 600 s, plus 300 m de descente a 1,67 s/m = 500 s, soit
      // 14 900 s = 248 min. La MEME etape annonçait 240 min avant ce lot : ses
      // 300 m de descente ne coutaient rien.
      expect(stageDurationMinutes(stageSansDuree), 248);
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

  group('estimatedStageDurationMinutes — LE modele de marche du depot', () {
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

    test('la descente coute 1,67 s par metre (tache 839)', () {
      // 600 m de descente = 1 000 s = 16,67 min, arrondies a 17.
      expect(
        estimatedStageDurationMinutes(
          distanceKm: 0.0,
          elevationGainM: 0,
          elevationLossM: 600,
        ),
        17,
      );
      // Une descente non fournie ne coute rien : c'est la seule reponse
      // honnete quand la source ne la connait pas.
      expect(
        estimatedStageDurationMinutes(distanceKm: 0.0, elevationGainM: 0),
        0,
      );
    });
  });

  group('walkingSeconds — IL N EXISTE QU UN MODELE (tache 839)', () {
    test('les constantes sont DERIVEES, jamais ecrites deux fois', () {
      // La vitesse en m/s se deduit des km/h : c'est la garde contre la
      // divergence qui existait (4,0 km/h d'un cote, 1,1 m/s de l'autre).
      expect(kWalkingFlatPaceMps, closeTo(1.1111, 0.0001));
      expect(kWalkingAscentSecondsPerMetre, 9.0);
      expect(kWalkingDescentSecondsPerMetre, closeTo(1.6667, 0.0001));
    });

    test('LE MODELE RETENU EST LE PRUDENT, et ce cas le chiffre', () {
      // Le cas mesure par la tache 838 : 200 m de montee en 1 km.
      // L'ancien modele d'etape rendait 45 min (descente gratuite, 400 m/h) ;
      // l'ancien modele d'ETA rendait 35 min (600 m/h). Le modele unique rend
      // le PRUDENT : 1 000 / 1,1111 + 200 x 9 = 900 + 1 800 = 2 700 s = 45 min.
      final secondes = walkingSeconds(
        distanceMetres: 1000,
        ascentMetres: 200,
        descentMetres: 0,
      );
      expect(secondes, closeTo(2700, 1));
    });

    test('une vitesse observee remplace la vitesse de reference', () {
      final reference = walkingSeconds(
        distanceMetres: 1000,
        ascentMetres: 0,
        descentMetres: 0,
      );
      final rapide = walkingSeconds(
        distanceMetres: 1000,
        ascentMetres: 0,
        descentMetres: 0,
        flatPaceMps: 2.0,
      );
      expect(rapide, lessThan(reference));
      // Mais le RELIEF ne se negocie pas : la penalite de montee est la meme.
      final avecMontee = walkingSeconds(
        distanceMetres: 1000,
        ascentMetres: 100,
        descentMetres: 0,
        flatPaceMps: 2.0,
      );
      expect(avecMontee - rapide, closeTo(900, 1));
    });

    test('une mesure absente ou aberrante compte pour zero', () {
      expect(
        walkingSeconds(
          distanceMetres: double.nan,
          ascentMetres: -100,
          descentMetres: double.infinity,
        ),
        0,
      );
      // Vitesse observee nulle -> vitesse de reference, jamais une division
      // par zero.
      expect(
        walkingSeconds(
          distanceMetres: 1000,
          ascentMetres: 0,
          descentMetres: 0,
          flatPaceMps: 0,
        ),
        closeTo(900, 1),
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
      // 350 (fournie) + 248 (modele unique, descente payee) = 598.
      expect(totalStagesDurationMinutes([stageAvecDuree, stageSansDuree]), 598);
    });
  });

  group('ROBUSTESSE champs nuls — DB roundtrip (fallback gracieux)', () {
    test(
      'un StageModel sans duree survit a un aller-retour DB sans crash',
      () async {
        final db = AppDatabase(NativeDatabase.memory());
        final dao = StagesDao(db);

        await dao.insertAll([stageSansDuree.toCompanion()]);
        final rows = await dao.getByTrailId('test-trail');
        final restored = StageModel.fromDb(rows.first);

        // La colonne est bien NULL en base (aucune valeur forcee).
        expect(restored.estimatedDurationMinutes, isNull);
        // ... et l'affichage retombe proprement sur le modele unique, DESCENTE
        // COMPRISE (tache 839) : 248 min et non 240, parce que les 300 m de
        // descente de cette etape coutent desormais 500 secondes.
        expect(stageDurationMinutes(restored), 248);
        expect(formatDurationMinutes(stageDurationMinutes(restored)), '4h08');

        await db.close();
      },
    );

    test(
      'un StageModel AVEC duree persiste et relit la valeur exacte',
      () async {
        final db = AppDatabase(NativeDatabase.memory());
        final dao = StagesDao(db);

        await dao.insertAll([stageAvecDuree.toCompanion()]);
        final rows = await dao.getByTrailId('mare-a-mare-centre');
        final restored = StageModel.fromDb(rows.first);

        expect(restored.estimatedDurationMinutes, 350);
        expect(stageDurationMinutes(restored), 350);

        await db.close();
      },
    );
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
