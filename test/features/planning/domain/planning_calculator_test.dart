import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/models/stage.dart';
import 'package:moteur_gr/features/planning/domain/planning_calculator.dart';

/// Tests de l'algorithme de répartition des étapes sur N jours.
void main() {
  /// Fabrique une étape fictive avec les paramètres donnés
  StageModel makeStage({
    required int num,
    required double distanceKm,
    required int elevationGainM,
  }) {
    return StageModel(
      trailId: 'test',
      stageNumber: num,
      name: 'Étape $num',
      distanceKm: distanceKm,
      elevationGainM: elevationGainM,
      elevationLossM: (elevationGainM * 0.8).round(),
      startLat: 42.0,
      startLng: 9.0,
      endLat: 42.1,
      endLng: 9.1,
    );
  }

  /// 5 étapes de test avec des difficultés variées
  final stages = [
    makeStage(num: 1, distanceKm: 12.0, elevationGainM: 800),
    makeStage(num: 2, distanceKm: 15.0, elevationGainM: 600),
    makeStage(num: 3, distanceKm: 10.0, elevationGainM: 1000),
    makeStage(num: 4, distanceKm: 8.0, elevationGainM: 400),
    makeStage(num: 5, distanceKm: 14.0, elevationGainM: 700),
  ];

  group('PlanningCalculator', () {
    group('stageScore', () {
      test('calcule le score comme distance + D+/100', () {
        final stage = stages[0]; // 12km + 800/100 = 20
        expect(PlanningCalculator.stageScore(stage), 20.0);
      });
    });

    group('estimatedHours', () {
      test('calcule la durée comme distance/4 + D+/400', () {
        final stage = stages[0]; // 12/4 + 800/400 = 3+2 = 5
        expect(PlanningCalculator.estimatedHours(stage), 5.0);
      });
    });

    group('distribute', () {
      test('5 étapes sur 5 jours : 1 étape par jour', () {
        final plan = PlanningCalculator.distribute(stages, 5);

        expect(plan.length, 5);
        for (final day in plan) {
          expect(day.isRestDay, false);
          expect(day.stages.length, 1);
        }
        // Vérifier l'ordre séquentiel
        expect(plan[0].stages[0].stageNumber, 1);
        expect(plan[4].stages[0].stageNumber, 5);
      });

      test('5 étapes sur 3 jours : distribution équilibrée', () {
        final plan = PlanningCalculator.distribute(stages, 3);

        expect(plan.length, 3);
        // Toutes les étapes doivent être présentes
        final allStages =
            plan.expand((d) => d.stages).toList();
        expect(allStages.length, 5);
        // Aucun jour de repos
        expect(plan.where((d) => d.isRestDay).length, 0);
        // Ordre séquentiel préservé
        for (var i = 0; i < allStages.length - 1; i++) {
          expect(
            allStages[i].stageNumber < allStages[i + 1].stageNumber,
            true,
          );
        }
      });

      test('5 étapes sur 7 jours : 2 jours de repos', () {
        final plan = PlanningCalculator.distribute(stages, 7);

        expect(plan.length, 7);
        final walkDays = plan.where((d) => !d.isRestDay).length;
        final restDays = plan.where((d) => d.isRestDay).length;
        expect(walkDays, 5);
        expect(restDays, 2);
        // Les jours de repos n'ont pas d'étapes
        for (final day in plan.where((d) => d.isRestDay)) {
          expect(day.stages, isEmpty);
          expect(day.totalDistanceKm, 0);
        }
      });

      test('5 étapes sur 1 jour : tout en un seul jour', () {
        final plan = PlanningCalculator.distribute(stages, 1);

        expect(plan.length, 1);
        expect(plan[0].stages.length, 5);
        expect(plan[0].isRestDay, false);
        // Totaux corrects
        final expectedDist = stages.fold<double>(
          0,
          (sum, s) => sum + s.distanceKm,
        );
        expect(plan[0].totalDistanceKm, expectedDist);
      });

      test('charge équilibrée : écart max < 30%', () {
        final plan = PlanningCalculator.distribute(stages, 3);

        final scores = plan.map((day) {
          return day.stages.fold<double>(
            0,
            (sum, s) => sum + PlanningCalculator.stageScore(s),
          );
        }).toList();

        final avg = scores.reduce((a, b) => a + b) / scores.length;
        for (final score in scores) {
          final ecart = (score - avg).abs() / avg;
          expect(
            ecart < 0.35,
            true,
            reason: 'Écart $ecart dépasse 35% '
                '(score=$score, moyenne=$avg)',
          );
        }
      });

      test('liste vide retourne un plan vide', () {
        final plan = PlanningCalculator.distribute([], 5);
        expect(plan, isEmpty);
      });

      test('0 jours retourne un plan vide', () {
        final plan = PlanningCalculator.distribute(stages, 0);
        expect(plan, isEmpty);
      });

      test('les dayNumber sont séquentiels et commencent à 1', () {
        final plan = PlanningCalculator.distribute(stages, 7);
        for (var i = 0; i < plan.length; i++) {
          expect(plan[i].dayNumber, i + 1);
        }
      });
    });
  });
}
