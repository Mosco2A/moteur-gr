import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/feasibility/data/feasibility_questions.dart';

/// Tests du template de questions de faisabilite.
void main() {
  group('feasibilityQuestions', () {
    test('contient 8 questions', () {
      expect(feasibilityQuestions.length, 8);
    });

    test('tous les ids sont uniques', () {
      final ids = feasibilityQuestions.map((q) => q.id).toSet();
      expect(ids.length, feasibilityQuestions.length);
    });

    test('chaque question a 4 reponses', () {
      for (final question in feasibilityQuestions) {
        expect(
          question.answers.length,
          4,
          reason: 'Question ${question.id} doit avoir 4 reponses',
        );
      }
    });

    test('les scores vont de 0 a 3 pour chaque question', () {
      for (final question in feasibilityQuestions) {
        final scores = question.answers.map((a) => a.score).toSet();
        expect(scores, containsAll([0, 1, 2, 3]),
            reason: 'Question ${question.id} doit avoir les scores 0-3');
      }
    });

    test('les questions couvrent les categories attendues', () {
      final categories =
          feasibilityQuestions.map((q) => q.categoryKey).toSet();
      expect(categories, contains('fitness'));
      expect(categories, contains('experience'));
      expect(categories, contains('gear'));
      expect(categories, contains('weather'));
      expect(categories, contains('duration'));
      expect(categories, contains('companion'));
      expect(categories, contains('health'));
      expect(categories, contains('motivation'));
    });
  });

  group('FeasibilityQuestion', () {
    test('constructor initialise les champs', () {
      const q = FeasibilityQuestion(
        id: 'test',
        categoryKey: 'cat',
        questionKey: 'qKey',
        answers: [],
      );
      expect(q.id, 'test');
      expect(q.categoryKey, 'cat');
      expect(q.questionKey, 'qKey');
      expect(q.answers, isEmpty);
    });
  });

  group('FeasibilityAnswer', () {
    test('constructor initialise les champs', () {
      const a = FeasibilityAnswer(
        answerKey: 'aKey',
        score: 2,
      );
      expect(a.answerKey, 'aKey');
      expect(a.score, 2);
    });
  });
}
