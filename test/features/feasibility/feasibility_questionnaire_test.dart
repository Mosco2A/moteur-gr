import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/feasibility/data/feasibility_question_loader.dart';
import 'package:moteur_gr/features/feasibility/domain/feasibility_calculator.dart';

/// Tests du questionnaire de faisabilite configurable JSON (E3.3a).
///
/// Test 1: Score calcule correctement depuis les reponses.
/// Test 2: Profil identifie correctement selon le score.
void main() {
  // Charger le JSON de test (meme fichier que assets/data/)
  late String jsonContent;

  setUpAll(() {
    final file = File('assets/data/feasibility_questions.json');
    jsonContent = file.readAsStringSync();
  });

  group('E3.3a FeasibilityQuestionnaireScreen', () {
    test('score calcule correctement depuis les reponses JSON', () {
      // GIVEN: questions chargees depuis JSON
      final questions = FeasibilityQuestionLoader.parseQuestions(jsonContent);

      // WHEN: toutes les reponses max (score 3)
      final allMaxAnswers = <String, int>{};
      for (final q in questions) {
        allMaxAnswers[q.id] = 3;
      }
      final scoreMax = FeasibilityCalculator.calculateScore(allMaxAnswers);

      // THEN: score = 8 questions x 3 = 24
      expect(scoreMax, 24);

      // WHEN: toutes les reponses min (score 0)
      final allMinAnswers = <String, int>{};
      for (final q in questions) {
        allMinAnswers[q.id] = 0;
      }
      final scoreMin = FeasibilityCalculator.calculateScore(allMinAnswers);

      // THEN: score = 0
      expect(scoreMin, 0);

      // WHEN: reponses mixtes deterministes
      final mixedAnswers = <String, int>{};
      for (var i = 0; i < questions.length; i++) {
        mixedAnswers[questions[i].id] = i % 4; // 0, 1, 2, 3, 0, 1, 2, 3
      }
      final scoreMixed = FeasibilityCalculator.calculateScore(mixedAnswers);

      // THEN: 0+1+2+3+0+1+2+3 = 12
      expect(scoreMixed, 12);

      // Verification deterministe: memes reponses = meme score
      final scoreMixed2 = FeasibilityCalculator.calculateScore(mixedAnswers);
      expect(scoreMixed2, scoreMixed);
    });

    test('profil identifie correctement selon le score', () {
      // GIVEN: questions chargees depuis JSON
      final questions = FeasibilityQuestionLoader.parseQuestions(jsonContent);

      // WHEN: profil danger (toutes reponses 0)
      final dangerAnswers = <String, int>{};
      for (final q in questions) {
        dangerAnswers[q.id] = 0;
      }
      final dangerResult = FeasibilityCalculator.evaluate(dangerAnswers);

      // THEN: profil = danger, score = 0
      expect(dangerResult.level, 'danger');
      expect(dangerResult.score, 0);
      expect(dangerResult.weakPoints.length, 8);
      expect(dangerResult.strongPoints, isEmpty);

      // WHEN: profil excellent (toutes reponses 3)
      final excellentAnswers = <String, int>{};
      for (final q in questions) {
        excellentAnswers[q.id] = 3;
      }
      final excellentResult = FeasibilityCalculator.evaluate(excellentAnswers);

      // THEN: profil = excellent, score = 24
      expect(excellentResult.level, 'excellent');
      expect(excellentResult.score, 24);
      expect(excellentResult.weakPoints, isEmpty);
      expect(excellentResult.strongPoints.length, 8);

      // WHEN: profil caution (score 12 via reponses mixtes)
      final cautionAnswers = <String, int>{};
      for (var i = 0; i < questions.length; i++) {
        cautionAnswers[questions[i].id] = i % 4;
      }
      final cautionResult = FeasibilityCalculator.evaluate(cautionAnswers);

      // THEN: profil = caution (score 12 <= 14)
      expect(cautionResult.level, 'caution');
      expect(cautionResult.score, 12);

      // WHEN: profil good (score 16)
      final goodAnswers = <String, int>{};
      for (final q in questions) {
        goodAnswers[q.id] = 2;
      }
      final goodResult = FeasibilityCalculator.evaluate(goodAnswers);

      // THEN: profil = good (score 16 <= 19)
      expect(goodResult.level, 'good');
      expect(goodResult.score, 16);
    });
  });
}
