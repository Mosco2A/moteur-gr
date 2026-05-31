import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/feasibility/data/feasibility_question_loader.dart';
import 'package:moteur_gr/features/feasibility/domain/feasibility_calculator.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

/// Tests E3.3b FeasibilityResultScreen.
///
/// Test 1: Les recommandations changent selon le profil (danger/caution/good/excellent).
/// Test 2: Les textes i18n sont correctement resolus via Slang.
void main() {
  late String jsonContent;

  setUpAll(() {
    final file = File('assets/data/feasibility_questions.json');
    jsonContent = file.readAsStringSync();
  });

  group('E3.3b FeasibilityResultScreen', () {
    test('recommandations changent selon le profil', () {
      // GIVEN: questions chargees depuis JSON
      final questions = FeasibilityQuestionLoader.parseQuestions(jsonContent);

      // WHEN: profil danger (toutes reponses 0)
      final dangerAnswers = <String, int>{};
      for (final q in questions) { dangerAnswers[q.id] = 0; }
      final dangerResult = FeasibilityCalculator.evaluate(dangerAnswers);

      // THEN: niveau danger, recommandations specifiques
      expect(dangerResult.level, 'danger');
      expect(dangerResult.weakPoints.length, 8);
      expect(dangerResult.strongPoints, isEmpty);

      // WHEN: profil excellent (toutes reponses 3)
      final excellentAnswers = <String, int>{};
      for (final q in questions) { excellentAnswers[q.id] = 3; }
      final excellentResult = FeasibilityCalculator.evaluate(excellentAnswers);

      // THEN: niveau excellent, recommandations differentes
      expect(excellentResult.level, 'excellent');
      expect(excellentResult.weakPoints, isEmpty);
      expect(excellentResult.strongPoints.length, 8);

      // VERIFY: les niveaux sont bien differents
      expect(dangerResult.level, isNot(equals(excellentResult.level)));

      // WHEN: profil caution (score 12)
      final cautionAnswers = <String, int>{};
      for (var i = 0; i < questions.length; i++) { cautionAnswers[questions[i].id] = i % 4; }
      final cautionResult = FeasibilityCalculator.evaluate(cautionAnswers);

      // THEN: niveau caution, differentes recommandations
      expect(cautionResult.level, 'caution');
      expect(cautionResult.level, isNot(equals(dangerResult.level)));
      expect(cautionResult.level, isNot(equals(excellentResult.level)));

      // WHEN: profil good (score 16)
      final goodAnswers = <String, int>{};
      for (final q in questions) { goodAnswers[q.id] = 2; }
      final goodResult = FeasibilityCalculator.evaluate(goodAnswers);

      // THEN: 4 profils distincts avec recommandations differentes
      expect(goodResult.level, 'good');
      final allLevels = {dangerResult.level, cautionResult.level, goodResult.level, excellentResult.level};
      expect(allLevels.length, 4);
    });

    test('i18n fonctionne pour les recommandations', () {
      // GIVEN: Slang initialise en francais
      LocaleSettings.setLocaleRaw('fr');

      // WHEN: acces aux textes de recommandation via t[]
      final dangerTitle = t['feasibility.recommendations.danger.title'];
      final cautionTitle = t['feasibility.recommendations.caution.title'];
      final goodTitle = t['feasibility.recommendations.good.title'];
      final excellentTitle = t['feasibility.recommendations.excellent.title'];

      // THEN: les textes sont des String non vides et distincts
      expect(dangerTitle, isA<String>());
      expect(cautionTitle, isA<String>());
      expect(goodTitle, isA<String>());
      expect(excellentTitle, isA<String>());

      final titles = {dangerTitle, cautionTitle, goodTitle, excellentTitle};
      expect(titles.length, 4);

      // WHEN: acces aux tips
      final tip1 = t['feasibility.recommendations.danger.tips.tip1'];
      final tip2 = t['feasibility.recommendations.danger.tips.tip2'];
      final tip3 = t['feasibility.recommendations.danger.tips.tip3'];

      // THEN: 3 tips distincts et non vides
      expect(tip1, isA<String>());
      expect(tip2, isA<String>());
      expect(tip3, isA<String>());
      expect({tip1, tip2, tip3}.length, 3);

      // WHEN: changement de locale en anglais
      LocaleSettings.setLocaleRaw('en');
      final enTitle = t['feasibility.recommendations.danger.title'];

      // THEN: texte different du francais
      expect(enTitle, isA<String>());
      expect(enTitle, isNot(equals(dangerTitle)));

      // Retour au francais
      LocaleSettings.setLocaleRaw('fr');
    });
  });
}
