import 'dart:convert';

import 'package:flutter/services.dart';

import '../../../core/config/trail_config.dart';
import 'feasibility_questions.dart';

/// Service de chargement des questions de faisabilite depuis JSON.
///
/// Resolution par sentier (finitions V8 F2) :
/// 1. version sentier `<seedAssetsBase>/feasibility_questions.json`
///    (TrailConfig) si elle existe ;
/// 2. fallback fichier commun `assets/data/feasibility_questions.json` ;
/// 3. fallback template hardcode (securite).
/// Permet a chaque sentier de definir ses propres questions sans
/// recompilation du moteur.
class FeasibilityQuestionLoader {
  const FeasibilityQuestionLoader._();

  /// Chemin du fichier JSON commun a tous les sentiers.
  static const String commonAssetPath =
      'assets/data/feasibility_questions.json';

  /// Nom du fichier de questions dans les assets d'un sentier.
  static const String trailFileName = 'feasibility_questions.json';

  /// Charge les questions du sentier [config].
  ///
  /// Sans [config] (ou sans seedAssetsBase), charge directement le
  /// fichier commun. En cas d'erreur de lecture/parsing, retourne le
  /// template hardcode comme fallback de securite.
  static Future<List<FeasibilityQuestion>> load({TrailConfig? config}) async {
    final base = config?.seedAssetsBase;
    if (base != null) {
      try {
        final jsonString = await rootBundle.loadString('$base/$trailFileName');
        return parseQuestions(jsonString);
      } catch (_) {
        // Pas de version sentier : fallback fichier commun.
      }
    }
    try {
      final jsonString = await rootBundle.loadString(commonAssetPath);
      return parseQuestions(jsonString);
    } catch (_) {
      // Fallback securite : questions hardcodees
      return feasibilityQuestions;
    }
  }

  /// Parse une chaine JSON en liste de FeasibilityQuestion.
  ///
  /// Methode pure, testable sans Flutter.
  static List<FeasibilityQuestion> parseQuestions(String jsonString) {
    final data = json.decode(jsonString) as Map<String, dynamic>;
    final questionsList = data['questions'] as List<dynamic>;

    return questionsList.map((q) {
      final questionMap = q as Map<String, dynamic>;
      final answersList = questionMap['answers'] as List<dynamic>;

      return FeasibilityQuestion(
        id: questionMap['id'] as String,
        categoryKey: questionMap['categoryKey'] as String,
        questionKey: questionMap['questionKey'] as String,
        answers: answersList.map((a) {
          final answerMap = a as Map<String, dynamic>;
          return FeasibilityAnswer(
            answerKey: answerMap['answerKey'] as String,
            score: answerMap['score'] as int,
          );
        }).toList(),
      );
    }).toList();
  }
}
