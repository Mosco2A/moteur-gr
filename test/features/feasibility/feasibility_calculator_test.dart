import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/feasibility/domain/feasibility_calculator.dart';

/// Tests du calculateur de faisabilite.
void main() {
  group('FeasibilityCalculator', () {
    test('maxScore est 24 (8 questions x 3)', () {
      expect(FeasibilityCalculator.maxScore, 24);
    });

    test('calculateScore additionne les scores', () {
      final answers = {
        'fitness': 2,
        'experience': 3,
        'gear': 1,
      };
      expect(FeasibilityCalculator.calculateScore(answers), 6);
    });

    test('calculateScore retourne 0 si aucune reponse', () {
      expect(FeasibilityCalculator.calculateScore({}), 0);
    });

    test('getLevel retourne danger pour score <= 8', () {
      expect(FeasibilityCalculator.getLevel(0), 'danger');
      expect(FeasibilityCalculator.getLevel(5), 'danger');
      expect(FeasibilityCalculator.getLevel(8), 'danger');
    });

    test('getLevel retourne caution pour score 9-14', () {
      expect(FeasibilityCalculator.getLevel(9), 'caution');
      expect(FeasibilityCalculator.getLevel(12), 'caution');
      expect(FeasibilityCalculator.getLevel(14), 'caution');
    });

    test('getLevel retourne good pour score 15-19', () {
      expect(FeasibilityCalculator.getLevel(15), 'good');
      expect(FeasibilityCalculator.getLevel(17), 'good');
      expect(FeasibilityCalculator.getLevel(19), 'good');
    });

    test('getLevel retourne excellent pour score 20+', () {
      expect(FeasibilityCalculator.getLevel(20), 'excellent');
      expect(FeasibilityCalculator.getLevel(24), 'excellent');
    });

    test('getPercentage calcule le bon ratio', () {
      expect(FeasibilityCalculator.getPercentage(12), closeTo(0.5, 0.01));
      expect(FeasibilityCalculator.getPercentage(0), 0.0);
      expect(FeasibilityCalculator.getPercentage(24), 1.0);
    });

    test('getWeakPoints identifie les scores 0 et 1', () {
      final answers = {
        'fitness': 0,
        'experience': 3,
        'gear': 1,
        'weather': 2,
      };
      final weak = FeasibilityCalculator.getWeakPoints(answers);
      expect(weak, contains('fitness'));
      expect(weak, contains('gear'));
      expect(weak.length, 2);
    });

    test('getWeakPoints retourne vide si tout est >= 2', () {
      final answers = {
        'fitness': 2,
        'experience': 3,
      };
      expect(FeasibilityCalculator.getWeakPoints(answers), isEmpty);
    });

    test('getStrongPoints identifie les scores 3', () {
      final answers = {
        'fitness': 3,
        'experience': 1,
        'gear': 3,
      };
      final strong = FeasibilityCalculator.getStrongPoints(answers);
      expect(strong, contains('fitness'));
      expect(strong, contains('gear'));
      expect(strong.length, 2);
    });

    test('evaluate produit un resultat complet', () {
      final answers = {
        'fitness': 3,
        'experience': 3,
        'gear': 2,
        'weather': 2,
        'duration': 3,
        'companion': 2,
        'health': 3,
        'motivation': 3,
      };
      final result = FeasibilityCalculator.evaluate(answers);

      expect(result.score, 21);
      expect(result.maxScore, 24);
      expect(result.percentage, closeTo(0.875, 0.01));
      expect(result.level, 'excellent');
      expect(result.weakPoints, isEmpty);
      expect(result.strongPoints.length, 5);
    });

    test('evaluate avec score danger', () {
      final answers = {
        'fitness': 0,
        'experience': 0,
        'gear': 1,
        'weather': 1,
        'duration': 0,
        'companion': 1,
        'health': 0,
        'motivation': 1,
      };
      final result = FeasibilityCalculator.evaluate(answers);

      expect(result.score, 4);
      expect(result.level, 'danger');
      expect(result.weakPoints.length, greaterThan(3));
    });
  });

  group('FeasibilityResult', () {
    test('stocke tous les champs', () {
      const result = FeasibilityResult(
        score: 15,
        maxScore: 24,
        percentage: 0.625,
        level: 'good',
        weakPoints: ['gear'],
        strongPoints: ['fitness', 'motivation'],
      );

      expect(result.score, 15);
      expect(result.maxScore, 24);
      expect(result.percentage, closeTo(0.625, 0.001));
      expect(result.level, 'good');
      expect(result.weakPoints, ['gear']);
      expect(result.strongPoints.length, 2);
    });
  });
}
