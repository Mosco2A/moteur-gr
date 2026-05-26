/// Calculateur de score de faisabilite.
///
/// Classe pure Dart, pas de dependance Flutter.
/// Evalue les reponses et produit un score + recommandation.
class FeasibilityCalculator {
  const FeasibilityCalculator._();

  /// Score maximum possible (8 questions x 3 points)
  static const int maxScore = 24;

  /// Seuils de recommandation
  static const int thresholdDanger = 8;
  static const int thresholdCaution = 14;
  static const int thresholdGood = 19;

  /// Niveaux de recommandation
  static const String levelDanger = 'danger';
  static const String levelCaution = 'caution';
  static const String levelGood = 'good';
  static const String levelExcellent = 'excellent';

  /// Calcule le score total a partir des reponses.
  ///
  /// [answers] = Map<questionId, answerScore>
  /// Retourne un score entre 0 et [maxScore].
  static int calculateScore(Map<String, int> answers) {
    return answers.values.fold(0, (sum, score) => sum + score);
  }

  /// Determine le niveau de recommandation.
  static String getLevel(int score) {
    if (score <= thresholdDanger) return levelDanger;
    if (score <= thresholdCaution) return levelCaution;
    if (score <= thresholdGood) return levelGood;
    return levelExcellent;
  }

  /// Pourcentage de faisabilite (0.0 a 1.0).
  static double getPercentage(int score) {
    return score / maxScore;
  }

  /// Identifie les points faibles (score 0 ou 1).
  ///
  /// Retourne les IDs des questions avec score <= 1.
  static List<String> getWeakPoints(Map<String, int> answers) {
    return answers.entries
        .where((e) => e.value <= 1)
        .map((e) => e.key)
        .toList();
  }

  /// Identifie les points forts (score 3).
  static List<String> getStrongPoints(Map<String, int> answers) {
    return answers.entries
        .where((e) => e.value == 3)
        .map((e) => e.key)
        .toList();
  }

  /// Resultat complet du questionnaire.
  static FeasibilityResult evaluate(Map<String, int> answers) {
    final score = calculateScore(answers);
    return FeasibilityResult(
      score: score,
      maxScore: maxScore,
      percentage: getPercentage(score),
      level: getLevel(score),
      weakPoints: getWeakPoints(answers),
      strongPoints: getStrongPoints(answers),
    );
  }
}

/// Resultat du questionnaire de faisabilite.
class FeasibilityResult {
  const FeasibilityResult({
    required this.score,
    required this.maxScore,
    required this.percentage,
    required this.level,
    required this.weakPoints,
    required this.strongPoints,
  });

  /// Score obtenu
  final int score;

  /// Score maximum possible
  final int maxScore;

  /// Pourcentage (0.0 a 1.0)
  final double percentage;

  /// Niveau de recommandation (danger, caution, good, excellent)
  final String level;

  /// IDs des questions avec score faible
  final List<String> weakPoints;

  /// IDs des questions avec score parfait
  final List<String> strongPoints;
}
