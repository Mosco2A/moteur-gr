import 'dart:convert';

import 'package:flutter/services.dart';

import 'feasibility_questions.dart';

/// Service de chargement des questions de faisabilite depuis JSON.
///
/// Charge le fichier assets/data/feasibility_questions.json
/// et le parse en liste de FeasibilityQuestion.
/// Permet la configuration des questions sans recompilation.
class FeasibilityQuestionLoader {
  const FeasibilityQuestionLoader._();

  /// Chemin du fichier JSON de questions
  static const String _assetPath = 'assets/data/feasibility_questions.json';

  /// Charge les questions depuis le fichier JSON embarque.
  ///
  /// Retourne la liste des questions parsees.
  /// En cas d'erreur de lecture/parsing, retourne le template
  /// hardcode comme fallback de securite.
  static Future<List<FeasibilityQuestion>> load() async {
    try {
      final jsonString = await rootBundle.loadString(_assetPath);
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
