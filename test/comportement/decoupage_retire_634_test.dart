import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/config/test_trail_config.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/core/models/stage_row.dart';
import 'package:moteur_gr/features/feasibility/domain/feasibility_formula.dart';
import 'package:moteur_gr/features/feasibility/domain/feasibility_program.dart';
import 'package:moteur_gr/features/feasibility/domain/program_plan_search.dart';
import 'package:moteur_gr/features/planning/domain/planning_calculator.dart';
import 'package:moteur_gr/features/planning/providers/planned_days_provider.dart';
import 'package:moteur_gr/features/planning/providers/planning_provider.dart';
import 'package:moteur_gr/features/trail/providers/stages_provider.dart';

/// TACHE 634 — LE DECOUPAGE D'ETAPE EST RETIRE (DEM-260929-1327).
///
/// CE FICHIER REMPLACE `decoupe_curseur_558_test.dart`, qui verrouillait
/// exactement l'inverse. Le lot 558 avait fait couper une etape en deux
/// demi-journees quand le randonneur poussait le curseur ; Christophe l'a
/// refuse le 29/09, verbatim : « Decouper les etapes en deux est une mauvaise
/// idee... il n'y a pas de refuge et surtout JE N AI JAMAIS DEMANDE CA ».
///
/// D'OU VENAIT LE DECOUPAGE — MESURE FAITE AVANT DE RETIRER.
///  * Lot 558, commit d48661d du 25/09, memoire #100486. Justification ecrite :
///    « Le curseur de jours ne pouvait PAS alleger le verdict... Le seul remede
///    etait de COUPER la pire journee ». C'est une decision d'AGENT.
///  * AUCUNE decision de Christophe ne le soutient. Trois traces disent le
///    contraire, dont DEUX ANTERIEURES au lot 558 : #100549 du 26/09 10:02
///    (« decoupe la journee 1 en 2 === comment on fait???? pas une solution »),
///    #100649 du 26/09 17:51 (« couper une journer c est dormir ou? »), et
///    #100812 du 29/09, le present retour.
///  * Le lot 558 avait lui-meme note, dans ce qu'il laissait ouvert, que
///    « le point de coupe n'est pas un lieu releve » et que Christophe « ne l'a
///    jamais vu a l'ecran : a lui faire valider ».
///
/// CE QUE CES TESTS VERROUILLENT : qu'aucun chemin de l'application ne puisse
/// plus produire une demi-etape, et que ce qui reste — le REGROUPEMENT et le
/// REPOS — soit intact.
void main() {
  StageModel stage(int num, double km, int gain) => StageModel(
    trailId: 'test-trail',
    stageNumber: num,
    name: 'Etape $num',
    distanceKm: km,
    elevationGainM: gain,
    elevationLossM: (gain * 0.8).round(),
    startLat: 42.0,
    startLng: 9.0,
    endLat: 42.2,
    endLng: 9.2,
    departureName: 'Depart $num',
    arrivalName: 'Arrivee $num',
  );

  // 5 etapes dont une NETTEMENT plus dure : c'est elle qui fixe le verdict, et
  // c'est elle que le lot 558 coupait en deux.
  final cinqEtapes = [
    stage(1, 10.0, 300),
    stage(2, 12.0, 400),
    stage(3, 30.0, 1400), // la pire, et de loin
    stage(4, 9.0, 250),
    stage(5, 11.0, 350),
  ];

  group('le moteur de repartition ne coupe plus AUCUNE etape', () {
    test('quelle que soit la duree demandee, jamais plus de journees de marche '
        'que d etapes', () {
      // LE TEST DE FOND. Peu importe par ou l'on passe : si le nombre de
      // journees de marche ne peut pas depasser le nombre d'etapes, alors
      // aucune etape n'a ete coupee.
      for (var total = 1; total <= cinqEtapes.length * 4; total++) {
        final plan = PlanningCalculator.distribute(cinqEtapes, total);
        final marche = plan
            .where((d) => !d.isRestDay && d.stages.isNotEmpty)
            .length;
        expect(
          marche,
          lessThanOrEqualTo(cinqEtapes.length),
          reason:
              '$total jours produisent $marche journees de marche pour '
              '${cinqEtapes.length} etapes',
        );
      }
    });

    test('aucune journee ne porte un nom de portion', () {
      // Le lot 558 suffixait les portions « (1/2) » et « (2/2) ». Ces marques
      // ne doivent plus pouvoir apparaitre.
      for (var total = 1; total <= cinqEtapes.length * 4; total++) {
        for (final jour in PlanningCalculator.distribute(cinqEtapes, total)) {
          for (final etape in jour.stages) {
            expect(etape.name, isNot(contains('(1/2)')));
            expect(etape.name, isNot(contains('(2/2)')));
          }
        }
      }
    });

    test('chaque etape du sentier reste ENTIERE, aux chiffres pres', () {
      // Au-dela du nombre d'etapes, une etape par journee et rien d'autre.
      final plan = PlanningCalculator.distribute(cinqEtapes, 12);
      final marche = plan.where((d) => !d.isRestDay && d.stages.isNotEmpty);
      expect(marche.length, cinqEtapes.length);
      for (final source in cinqEtapes) {
        final jour = marche.firstWhere(
          (d) => d.stages.any((s) => s.stageNumber == source.stageNumber),
        );
        expect(jour.stages.single.distanceKm, source.distanceKm);
        expect(jour.stages.single.elevationGainM, source.elevationGainM);
        expect(jour.stages.single.name, source.name);
      }
    });

    test('le surplus de jours devient du REPOS, sans plafond', () {
      // Le lot 558 plafonnait le repos pour convertir le reste en decoupages.
      // Ce plafond n'a plus d'objet : tout jour en trop est un repos.
      for (final total in [6, 8, 12, 20]) {
        final plan = PlanningCalculator.distribute(cinqEtapes, total);
        expect(plan.length, total);
        expect(plan.where((d) => d.isRestDay).length, total - 5);
      }
    });

    test(
      'le REGROUPEMENT, lui, est intact : il n invente aucun point d arret',
      () {
        // Regrouper reunit des etapes qui EXISTENT sur une meme journee. Personne
        // ne dort au milieu de nulle part : on dort a l'arrivee de la derniere.
        final plan = PlanningCalculator.distribute(cinqEtapes, 3);
        // Le regroupement greedy peut rendre MOINS de journees que demande quand
        // il ne trouve pas assez de points de coupe entre etapes — comportement
        // d'origine, inchange par cette tache.
        expect(plan.length, lessThanOrEqualTo(3));
        expect(plan.length, lessThan(cinqEtapes.length));
        // AUCUNE ETAPE PERDUE, aucune inventee.
        expect(plan.expand((d) => d.stages).length, cinqEtapes.length);
        expect(
          plan.expand((d) => d.stages).map((s) => s.stageNumber).toSet(),
          cinqEtapes.map((s) => s.stageNumber).toSet(),
        );
        expect(plan.any((d) => d.stages.length > 1), isTrue);
      },
    );
  });

  group('le curseur du Programme ne peut plus couper', () {
    ProviderContainer container() => ProviderContainer(
      overrides: [
        trailConfigProvider.overrideWithValue(testTrailConfig),
        stagesProvider(
          'test-trail',
        ).overrideWith((ref) => Future.value(cinqEtapes)),
      ],
    );

    test('pousse a fond, le curseur n ajoute que du repos', () async {
      final c = container();
      addTearDown(c.dispose);
      await c.read(stagesProvider('test-trail').future);
      final bornes = c.read(durationBoundsProvider('test-trail'));

      // La borne haute vaut desormais la duree NATURELLE : plus de plage de
      // curseur reservee au decoupage.
      expect(bornes.max, bornes.naturalMax);

      c.read(selectedDurationProvider.notifier).set(bornes.max);
      final jours = c.read(plannedDaysProvider('test-trail'));
      final marche = jours.where((d) => !d.isRestDay && d.stages.isNotEmpty);
      expect(marche.length, cinqEtapes.length);
      for (final j in marche) {
        expect(j.stages.length, 1);
      }
    });

    test('la pire journee ne bouge plus d un gramme, et c est la verite', () {
      // CE QUE LE RETRAIT COUTE, DIT FRANCHEMENT. Le lot 558 existait pour que
      // pousser le curseur allege la pire journee. Ce n'est plus possible : le
      // verdict vaut C1 = la pire journee (GO-61), et seul le decoupage pouvait
      // l'alleger. La reponse honnete n'est pas de couper l'etape, c'est de
      // DIRE que cette etape-la depasse le plafond — ce que fait le conseil
      // `hardStageAlert` de l'ecran de faisabilite.
      double pireDe(int total) {
        var pire = 0.0;
        for (final jour in PlanningCalculator.distribute(cinqEtapes, total)) {
          if (jour.isRestDay) continue;
          final e = FeasibilityScale.v2.energyOf(
            distanceKm: jour.totalDistanceKm,
            elevationGainM: jour.totalElevationGainM,
          );
          if (e > pire) pire = e;
        }
        return pire;
      }

      final naturel = pireDe(cinqEtapes.length);
      for (final total in [6, 8, 12, 20]) {
        expect(pireDe(total), closeTo(naturel, 1e-9));
      }
    });
  });

  group('le CONSEIL du moteur est le plan du sentier, pas un plan invente', () {
    test('7 etapes -> 7 journees de marche, jamais 4 (DEM-260929-1132)', () {
      // LE RETOUR 3 DE CHRISTOPHE, VERROUILLE. « pourquoi la faisabilite de
      // mare a mare te le propose en 4 jours ?????? En te disant que c'est
      // exigeant, c'est completement con !!! ». Les 4 jours venaient de la
      // borne basse du curseur, ceil(7/2), que la recherche essayait en
      // premier : elle y REGROUPAIT les 7 etapes en 4 journees et s'arretait au
      // premier verdict non rouge.
      final sept = [
        stage(1, 15.0, 850),
        stage(2, 12.0, 600),
        stage(3, 10.0, 400),
        stage(4, 11.0, 550),
        stage(5, 14.0, 650),
        stage(6, 12.0, 500),
        stage(7, 10.0, 200),
      ];
      final bornes = DurationBounds.fromStageCount(sept.length);
      expect(
        bornes.min,
        4,
        reason:
            'la borne basse EST bien 4 : c est de la '
            'qu est sortie la proposition refusee',
      );

      final conseil = ProgramPlanSearch.planDuSentier(
        stages: sept,
        level: HikerLevel.confirmed,
        bounds: bornes,
        joursDeReposConseilles: bornes.restAllowance,
      );
      expect(conseil, isNotNull);
      expect(
        conseil!.walkingDays,
        7,
        reason: 'le plan du sentier, pas 4 jours',
      );
      expect(conseil.totalDays, greaterThanOrEqualTo(7));
      expect(conseil.verdict, isNot(FeasibilityVerdict.red));
    });

    test('un plan du sentier ROUGE ne donne AUCUN conseil, et c est franc', () {
      // Quand la pire etape depasse le plafond, aucune duree n'y peut plus
      // rien : le moteur se tait au lieu de pointer une valeur.
      final mur = [stage(1, 40.0, 3000)];
      final bornes = DurationBounds.fromStageCount(mur.length);
      final conseil = ProgramPlanSearch.planDuSentier(
        stages: mur,
        level: HikerLevel.beginner,
        bounds: bornes,
        joursDeReposConseilles: bornes.restAllowance,
      );
      expect(conseil, isNull);

      // Et l'ecran NOMME l'etape qui bloque au lieu de conseiller une coupe.
      final program = FeasibilityProgram.fromDayPlans(
        PlanningCalculator.distribute(mur, bornes.min),
      );
      final a = FeasibilityFormula.evaluate(
        stages: program.dayEfforts,
        level: HikerLevel.beginner,
        maxWalkingDays: program.maxWalkingDays,
        durationAdvice: ProgramDurationAdvice.impossible,
      );
      final cles = a.advice.map((x) => x.key).toList();
      expect(cles, isNot(contains('split')));
      expect(cles, isNot(contains('splitImpossible')));
      expect(cles, contains('noViableDuration'));
    });
  });

  group('l API du decoupage n existe plus du tout', () {
    test(
      'le plafond de journees par etape est redevenu le nombre d etapes',
      () {
        // `FeasibilityProgram.maxWalkingDays` valait 2 x nbEtapes tant que le
        // decoupage existait : c'etait la trace de l API dans le moteur de
        // verdict. Il vaut de nouveau le nombre d etapes.
        final program = FeasibilityProgram.fromDayPlans(
          PlanningCalculator.distribute(cinqEtapes, cinqEtapes.length),
        );
        expect(program.stageCount, cinqEtapes.length);
        expect(program.maxWalkingDays, cinqEtapes.length);
      },
    );
  });
}
