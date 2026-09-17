import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/feasibility/domain/feasibility_formula.dart';

/// Tests de la FORMULE DE FAISABILITE V1 (decision Chris #100068).
///
/// Couvre : km-effort, plafond par niveau, verdict tricolore (vert/orange/
/// rouge), verdict global + facteur limitant + jours au-dessus, conseils
/// programme (jours optimal, decoupe, repos), reco entrainement.
void main() {
  StageEffort stage({
    int index = 0,
    String name = 'Etape',
    double distanceKm = 0,
    int elevationGainM = 0,
  }) =>
      StageEffort(
        index: index,
        name: name,
        distanceKm: distanceKm,
        elevationGainM: elevationGainM,
      );

  group('km-effort (formule)', () {
    test('effort = distance + D+/100 (equivalence BP)', () {
      final s = stage(distanceKm: 12, elevationGainM: 800);
      expect(s.effortKm, closeTo(12 + 8, 1e-9)); // 20 km-effort
      expect(s.elevationEffortKm, closeTo(8, 1e-9));
    });

    test('100 m D+ vaut 1 km plat', () {
      expect(stage(elevationGainM: 100).effortKm, closeTo(1, 1e-9));
    });
  });

  group('plafonds par niveau', () {
    test('les plafonds croissent avec le niveau', () {
      final b = FeasibilityFormula.dailyCeilingFor(HikerLevel.beginner);
      final i = FeasibilityFormula.dailyCeilingFor(HikerLevel.intermediate);
      final c = FeasibilityFormula.dailyCeilingFor(HikerLevel.confirmed);
      final e = FeasibilityFormula.dailyCeilingFor(HikerLevel.expert);
      expect(b, lessThan(i));
      expect(i, lessThan(c));
      expect(c, lessThan(e));
      expect(b, closeTo(21, 1e-9)); // 18 + 300/100
      expect(i, closeTo(29, 1e-9)); // 22 + 700/100
    });
  });

  group('deriveLevel (profil -> niveau)', () {
    test('D+/jour eleve -> confirme ou plus', () {
      final level = FeasibilityFormula.deriveLevel(
        maxElevationGainPerDayDone: 800,
        maxDistancePerDayDone: 24,
      );
      expect(level, HikerLevel.confirmed);
    });

    test('jamais rien fait -> debutant', () {
      final level = FeasibilityFormula.deriveLevel(
        maxElevationGainPerDayDone: 0,
        maxDistancePerDayDone: 0,
      );
      expect(level, HikerLevel.beginner);
    });

    test('prend le plus prudent des deux axes (D+ eleve, distance faible)', () {
      final level = FeasibilityFormula.deriveLevel(
        maxElevationGainPerDayDone: 1300, // expert par D+
        maxDistancePerDayDone: 10, // debutant par distance
      );
      expect(level, HikerLevel.beginner);
    });

    test('age >= 75 redescend de deux crans', () {
      final level = FeasibilityFormula.deriveLevel(
        maxElevationGainPerDayDone: 1300,
        maxDistancePerDayDone: 30,
        age: 78,
      );
      // Brut expert (rang 3) -> -2 -> intermediaire (rang 1).
      expect(level, HikerLevel.intermediate);
    });

    test('forme excellente remonte d un cran', () {
      final level = FeasibilityFormula.deriveLevel(
        maxElevationGainPerDayDone: 500, // intermediaire
        maxDistancePerDayDone: 18, // intermediaire
        fitnessRank: 3,
      );
      expect(level, HikerLevel.confirmed);
    });
  });

  group('verdict tricolore par etape', () {
    // Plafond intermediaire = 29 km-effort. Seuils 0.85 (=24.65) et 1.10 (=31.9).
    test('VERT si ratio <= 0.85', () {
      final r = FeasibilityFormula.evaluate(
        stages: [stage(distanceKm: 15, elevationGainM: 500)], // 20 km-effort
        level: HikerLevel.intermediate,
      );
      expect(r.stageVerdicts.single.verdict, FeasibilityVerdict.green);
      expect(r.globalVerdict, FeasibilityVerdict.green);
    });

    test('ORANGE si 0.85 < ratio <= 1.10', () {
      // 28 km-effort / 29 = 0.965 -> orange.
      final r = FeasibilityFormula.evaluate(
        stages: [stage(distanceKm: 20, elevationGainM: 800)], // 28 km-effort
        level: HikerLevel.intermediate,
      );
      expect(r.stageVerdicts.single.verdict, FeasibilityVerdict.orange);
      expect(r.globalVerdict, FeasibilityVerdict.orange);
    });

    test('ROUGE si ratio > 1.10', () {
      // 40 km-effort / 29 = 1.38 -> rouge.
      final r = FeasibilityFormula.evaluate(
        stages: [stage(distanceKm: 24, elevationGainM: 1600)], // 40 km-effort
        level: HikerLevel.intermediate,
      );
      expect(r.stageVerdicts.single.verdict, FeasibilityVerdict.red);
      expect(r.globalVerdict, FeasibilityVerdict.red);
    });

    test('seuils exacts 0.85 et 1.10 sont inclusifs (vert / orange)', () {
      const th = FeasibilityThresholds.median;
      expect(th.verdictFor(0.85), FeasibilityVerdict.green);
      expect(th.verdictFor(0.8500001), FeasibilityVerdict.orange);
      expect(th.verdictFor(1.10), FeasibilityVerdict.orange);
      expect(th.verdictFor(1.1000001), FeasibilityVerdict.red);
    });

    test('seuils parametrables (surcharge)', () {
      const strict = FeasibilityThresholds(green: 0.5, orange: 0.7);
      // ratio 20/29 = 0.69 -> orange avec seuils stricts (vert par defaut).
      final r = FeasibilityFormula.evaluate(
        stages: [stage(distanceKm: 15, elevationGainM: 500)],
        level: HikerLevel.intermediate,
        thresholds: strict,
      );
      expect(r.stageVerdicts.single.verdict, FeasibilityVerdict.orange);
    });
  });

  group('verdict global + facteur limitant + jours au-dessus', () {
    test('verdict global = etape la plus contraignante', () {
      final r = FeasibilityFormula.evaluate(
        stages: [
          stage(index: 0, distanceKm: 10, elevationGainM: 300), // vert
          stage(index: 1, distanceKm: 24, elevationGainM: 1600), // rouge
          stage(index: 2, distanceKm: 12, elevationGainM: 400), // vert
        ],
        level: HikerLevel.intermediate,
      );
      expect(r.globalVerdict, FeasibilityVerdict.red);
      expect(r.hardestStageIndex, 1);
      expect(r.hardestStage!.stage.name, 'Etape');
    });

    test('facteur limitant = D+ quand le denivele domine', () {
      final r = FeasibilityFormula.evaluate(
        stages: [stage(distanceKm: 10, elevationGainM: 2500)], // D+/100=25 > 10
        level: HikerLevel.intermediate,
      );
      expect(r.limitingFactor, LimitingFactor.elevation);
    });

    test('facteur limitant = distance quand la distance domine', () {
      final r = FeasibilityFormula.evaluate(
        stages: [stage(distanceKm: 40, elevationGainM: 200)], // dist 40 > 2
        level: HikerLevel.intermediate,
      );
      expect(r.limitingFactor, LimitingFactor.distance);
    });

    test('facteur limitant = enchainement (2+ jours consecutifs au-dessus)', () {
      final r = FeasibilityFormula.evaluate(
        stages: [
          stage(index: 0, distanceKm: 22, elevationGainM: 800), // 30 -> orange
          stage(index: 1, distanceKm: 22, elevationGainM: 800), // 30 -> orange
          stage(index: 2, distanceKm: 10, elevationGainM: 200), // vert
        ],
        level: HikerLevel.intermediate,
      );
      expect(r.daysOverCapacity, 2);
      expect(r.limitingFactor, LimitingFactor.chaining);
    });

    test('tout vert -> facteur limitant none + verdict global vert', () {
      final r = FeasibilityFormula.evaluate(
        stages: [
          stage(distanceKm: 10, elevationGainM: 200),
          stage(distanceKm: 12, elevationGainM: 300),
        ],
        level: HikerLevel.confirmed,
      );
      expect(r.globalVerdict, FeasibilityVerdict.green);
      expect(r.limitingFactor, LimitingFactor.none);
      expect(r.daysOverCapacity, 0);
    });
  });

  group('conseils de programme', () {
    test('tout vert -> conseil balancedOk uniquement', () {
      final r = FeasibilityFormula.evaluate(
        stages: [stage(distanceKm: 10, elevationGainM: 200)],
        level: HikerLevel.confirmed,
      );
      expect(r.advice.map((a) => a.key), ['balancedOk']);
    });

    test('etape rouge -> conseil de decoupe (split) + jours optimal', () {
      final r = FeasibilityFormula.evaluate(
        stages: [
          stage(index: 0, distanceKm: 24, elevationGainM: 1600), // rouge
          stage(index: 1, distanceKm: 10, elevationGainM: 200), // vert
        ],
        level: HikerLevel.intermediate,
      );
      final keys = r.advice.map((a) => a.key).toList();
      expect(keys, contains('split'));
      // split pointe sur l'etape 1 (1-based).
      final split = r.advice.firstWhere((a) => a.key == 'split');
      expect(split.params['stage'], 1);
      // jours optimal > nb d'etapes actuel.
      expect(r.suggestedDays, greaterThan(2));
    });

    test('bloc au-dessus suivi d autres etapes -> conseil de repos', () {
      final r = FeasibilityFormula.evaluate(
        stages: [
          stage(index: 0, distanceKm: 22, elevationGainM: 800), // orange
          stage(index: 1, distanceKm: 22, elevationGainM: 800), // orange
          stage(index: 2, distanceKm: 10, elevationGainM: 200), // vert
        ],
        level: HikerLevel.intermediate,
      );
      final rest = r.advice.where((a) => a.key == 'rest');
      expect(rest, isNotEmpty);
      // repos suggere APRES l'etape 2 (fin du bloc au-dessus, 1-based).
      expect(rest.first.params['stages'], '2');
    });

    test('jours optimal >= nb d etapes et couvre la charge totale', () {
      final r = FeasibilityFormula.evaluate(
        stages: [
          stage(distanceKm: 24, elevationGainM: 1600), // 40
          stage(distanceKm: 24, elevationGainM: 1600), // 40
        ],
        level: HikerLevel.intermediate, // plafond 29
      );
      // effort total 80 / 29 = 2.75 -> ceil 3 ; 2 rouges -> 2+2=4 -> max 4.
      expect(r.suggestedDays, 4);
    });
  });

  group('reco entrainement', () {
    test('verdict vert -> 0 semaine', () {
      expect(
        FeasibilityFormula.trainingWeeksFor(
            HikerLevel.confirmed, FeasibilityVerdict.green),
        0,
      );
    });

    test('debutant + orange -> 12 semaines (borne haute)', () {
      expect(
        FeasibilityFormula.trainingWeeksFor(
            HikerLevel.beginner, FeasibilityVerdict.orange),
        12,
      );
    });

    test('expert + orange -> 6 semaines (entretien, borne basse)', () {
      expect(
        FeasibilityFormula.trainingWeeksFor(
            HikerLevel.expert, FeasibilityVerdict.orange),
        6,
      );
    });

    test('rouge ajoute une marge mais reste borne a 12', () {
      // confirme orange = 6 -> rouge = 8.
      expect(
        FeasibilityFormula.trainingWeeksFor(
            HikerLevel.confirmed, FeasibilityVerdict.red),
        8,
      );
      // debutant rouge = 12+2 borne 12.
      expect(
        FeasibilityFormula.trainingWeeksFor(
            HikerLevel.beginner, FeasibilityVerdict.red),
        12,
      );
    });

    test('reco integree au resultat non nulle si non-vert', () {
      final r = FeasibilityFormula.evaluate(
        stages: [stage(distanceKm: 24, elevationGainM: 1600)],
        level: HikerLevel.intermediate,
      );
      expect(r.recommendedTrainingWeeks, greaterThanOrEqualTo(6));
    });
  });

  group('cas limites', () {
    test('aucune etape -> verdict vert, aucun facteur, 0 jour', () {
      final r = FeasibilityFormula.evaluate(
        stages: const [],
        level: HikerLevel.intermediate,
      );
      expect(r.globalVerdict, FeasibilityVerdict.green);
      expect(r.limitingFactor, LimitingFactor.none);
      expect(r.hardestStageIndex, -1);
      expect(r.suggestedDays, 0);
    });
  });
}
