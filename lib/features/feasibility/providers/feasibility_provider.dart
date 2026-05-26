import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../data/feasibility_questions.dart';
import '../domain/feasibility_calculator.dart';

/// Etat du questionnaire de faisabilite.
class FeasibilityState {
  const FeasibilityState({
    required this.currentQuestionIndex,
    required this.answers,
    this.result,
    this.isCompleted = false,
  });

  /// Index de la question courante (0-based)
  final int currentQuestionIndex;

  /// Reponses donnees (questionId -> score)
  final Map<String, int> answers;

  /// Resultat du questionnaire (null si pas termine)
  final FeasibilityResult? result;

  /// Questionnaire termine
  final bool isCompleted;

  /// Question courante
  FeasibilityQuestion get currentQuestion =>
      feasibilityQuestions[currentQuestionIndex];

  /// Nombre total de questions
  int get totalQuestions => feasibilityQuestions.length;

  /// Progression (0.0 a 1.0)
  double get progress => currentQuestionIndex / totalQuestions;

  /// A-t-on repondu a la question courante ?
  bool get hasAnsweredCurrent =>
      answers.containsKey(currentQuestion.id);

  /// Etat initial
  static const empty = FeasibilityState(
    currentQuestionIndex: 0,
    answers: {},
  );
}

/// Provider du questionnaire de faisabilite.
///
/// Gere la navigation entre questions, le scoring et
/// la persistance du resultat dans SharedPreferences.
final feasibilityProvider =
    StateNotifierProvider<FeasibilityNotifier, FeasibilityState>((ref) {
  return FeasibilityNotifier();
});

/// Notifier du questionnaire de faisabilite.
class FeasibilityNotifier extends StateNotifier<FeasibilityState> {
  FeasibilityNotifier() : super(FeasibilityState.empty) {
    _loadSavedResult();
  }

  static const _prefsKey = 'feasibility_result';

  /// Charge un resultat precedent depuis SharedPreferences.
  Future<void> _loadSavedResult() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefsKey);
      if (saved != null) {
        final data = json.decode(saved) as Map<String, dynamic>;
        final answers = (data['answers'] as Map<String, dynamic>)
            .map((k, v) => MapEntry(k, v as int));
        final result = FeasibilityCalculator.evaluate(answers);
        state = FeasibilityState(
          currentQuestionIndex: feasibilityQuestions.length,
          answers: answers,
          result: result,
          isCompleted: true,
        );
      }
    } catch (_) {
      // Pas de resultat sauvegarde — etat initial
    }
  }

  /// Repond a la question courante et avance.
  void answerQuestion(String questionId, int score) {
    final newAnswers = Map<String, int>.from(state.answers);
    newAnswers[questionId] = score;

    final nextIndex = state.currentQuestionIndex + 1;
    final isComplete = nextIndex >= feasibilityQuestions.length;

    if (isComplete) {
      final result = FeasibilityCalculator.evaluate(newAnswers);
      state = FeasibilityState(
        currentQuestionIndex: nextIndex,
        answers: newAnswers,
        result: result,
        isCompleted: true,
      );
      _saveResult(newAnswers);
    } else {
      state = FeasibilityState(
        currentQuestionIndex: nextIndex,
        answers: newAnswers,
      );
    }
  }

  /// Revient a la question precedente.
  void previousQuestion() {
    if (state.currentQuestionIndex > 0) {
      state = FeasibilityState(
        currentQuestionIndex: state.currentQuestionIndex - 1,
        answers: state.answers,
      );
    }
  }

  /// Reinitialise le questionnaire.
  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
    state = FeasibilityState.empty;
  }

  /// Sauvegarde le resultat dans SharedPreferences.
  Future<void> _saveResult(Map<String, int> answers) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, json.encode({'answers': answers}));
    } catch (_) {
      // Echec sauvegarde — non bloquant
    }
  }
}
