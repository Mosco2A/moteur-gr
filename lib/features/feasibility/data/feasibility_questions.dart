/// Questions du questionnaire de faisabilite trek.
///
/// 8 questions avec reponses a choix multiples.
/// Chaque reponse a un score (0 a 3).
/// Le score global determine la recommandation.
class FeasibilityQuestion {
  const FeasibilityQuestion({
    required this.id,
    required this.categoryKey,
    required this.questionKey,
    required this.answers,
  });

  /// Identifiant unique
  final String id;

  /// Cle i18n de la categorie
  final String categoryKey;

  /// Cle i18n de la question
  final String questionKey;

  /// Reponses possibles avec scores
  final List<FeasibilityAnswer> answers;
}

/// Reponse a une question de faisabilite.
class FeasibilityAnswer {
  const FeasibilityAnswer({
    required this.answerKey,
    required this.score,
  });

  /// Cle i18n de la reponse
  final String answerKey;

  /// Score de la reponse (0 = risque, 3 = ideal)
  final int score;
}

/// Template des questions de faisabilite.
///
/// 8 questions couvrant : condition physique, experience,
/// equipement, meteo, duree, accompagnement, sante, motivation.
const List<FeasibilityQuestion> feasibilityQuestions = [
  // Q1 — Condition physique
  FeasibilityQuestion(
    id: 'fitness',
    categoryKey: 'fitness',
    questionKey: 'fitnessQuestion',
    answers: [
      FeasibilityAnswer(answerKey: 'fitnessA', score: 0),
      FeasibilityAnswer(answerKey: 'fitnessB', score: 1),
      FeasibilityAnswer(answerKey: 'fitnessC', score: 2),
      FeasibilityAnswer(answerKey: 'fitnessD', score: 3),
    ],
  ),
  // Q2 — Experience randonnee
  FeasibilityQuestion(
    id: 'experience',
    categoryKey: 'experience',
    questionKey: 'experienceQuestion',
    answers: [
      FeasibilityAnswer(answerKey: 'experienceA', score: 0),
      FeasibilityAnswer(answerKey: 'experienceB', score: 1),
      FeasibilityAnswer(answerKey: 'experienceC', score: 2),
      FeasibilityAnswer(answerKey: 'experienceD', score: 3),
    ],
  ),
  // Q3 — Equipement
  FeasibilityQuestion(
    id: 'gear',
    categoryKey: 'gear',
    questionKey: 'gearQuestion',
    answers: [
      FeasibilityAnswer(answerKey: 'gearA', score: 0),
      FeasibilityAnswer(answerKey: 'gearB', score: 1),
      FeasibilityAnswer(answerKey: 'gearC', score: 2),
      FeasibilityAnswer(answerKey: 'gearD', score: 3),
    ],
  ),
  // Q4 — Conditions meteo
  FeasibilityQuestion(
    id: 'weather',
    categoryKey: 'weather',
    questionKey: 'weatherQuestion',
    answers: [
      FeasibilityAnswer(answerKey: 'weatherA', score: 0),
      FeasibilityAnswer(answerKey: 'weatherB', score: 1),
      FeasibilityAnswer(answerKey: 'weatherC', score: 2),
      FeasibilityAnswer(answerKey: 'weatherD', score: 3),
    ],
  ),
  // Q5 — Duree prevue
  FeasibilityQuestion(
    id: 'duration',
    categoryKey: 'duration',
    questionKey: 'durationQuestion',
    answers: [
      FeasibilityAnswer(answerKey: 'durationA', score: 0),
      FeasibilityAnswer(answerKey: 'durationB', score: 1),
      FeasibilityAnswer(answerKey: 'durationC', score: 2),
      FeasibilityAnswer(answerKey: 'durationD', score: 3),
    ],
  ),
  // Q6 — Accompagnement
  FeasibilityQuestion(
    id: 'companion',
    categoryKey: 'companion',
    questionKey: 'companionQuestion',
    answers: [
      FeasibilityAnswer(answerKey: 'companionA', score: 0),
      FeasibilityAnswer(answerKey: 'companionB', score: 1),
      FeasibilityAnswer(answerKey: 'companionC', score: 2),
      FeasibilityAnswer(answerKey: 'companionD', score: 3),
    ],
  ),
  // Q7 — Sante
  FeasibilityQuestion(
    id: 'health',
    categoryKey: 'health',
    questionKey: 'healthQuestion',
    answers: [
      FeasibilityAnswer(answerKey: 'healthA', score: 0),
      FeasibilityAnswer(answerKey: 'healthB', score: 1),
      FeasibilityAnswer(answerKey: 'healthC', score: 2),
      FeasibilityAnswer(answerKey: 'healthD', score: 3),
    ],
  ),
  // Q8 — Motivation
  FeasibilityQuestion(
    id: 'motivation',
    categoryKey: 'motivation',
    questionKey: 'motivationQuestion',
    answers: [
      FeasibilityAnswer(answerKey: 'motivationA', score: 0),
      FeasibilityAnswer(answerKey: 'motivationB', score: 1),
      FeasibilityAnswer(answerKey: 'motivationC', score: 2),
      FeasibilityAnswer(answerKey: 'motivationD', score: 3),
    ],
  ),
];
