import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../../../core/engine/trail_engine.dart';
import '../data/feasibility_question_loader.dart';
import '../data/feasibility_questions.dart';
import '../domain/feasibility_calculator.dart';

/// Etat du questionnaire de faisabilite.
class FeasibilityState {
  const FeasibilityState({
    required this.currentQuestionIndex,
    required this.answers,
    this.questions = feasibilityQuestions,
    this.result,
    this.isCompleted = false,
  });

  /// Index de la question courante (0-based)
  final int currentQuestionIndex;

  /// Reponses donnees (questionId -> score)
  final Map<String, int> answers;

  /// Questions du sentier actif (finitions V8 F2) — chargees par
  /// trailId via FeasibilityQuestionLoader, template hardcode en
  /// attendant le chargement.
  final List<FeasibilityQuestion> questions;

  /// Resultat du questionnaire (null si pas termine)
  final FeasibilityResult? result;

  /// Questionnaire termine
  final bool isCompleted;

  /// Question courante
  FeasibilityQuestion get currentQuestion =>
      questions[currentQuestionIndex];

  /// Nombre total de questions
  int get totalQuestions => questions.length;

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
    NotifierProvider<FeasibilityNotifier, FeasibilityState>(
        FeasibilityNotifier.new);

/// Notifier du questionnaire de faisabilite.
class FeasibilityNotifier extends Notifier<FeasibilityState> {
  static const _prefsKey = 'feasibility_result';

  @override
  FeasibilityState build() {
    _loadQuestions();
    _loadSavedResult();
    return FeasibilityState.empty;
  }

  /// Charge les questions du sentier actif (version sentier via
  /// TrailConfig, fallback fichier commun — finitions V8 F2).
  Future<void> _loadQuestions() async {
    try {
      final config = ref.read(trailConfigProvider);
      final questions = await FeasibilityQuestionLoader.load(config: config);
      // `ref.mounted` apres le gap async : provider dispose pendant l'attente
      // (ex. container detruit tot en test) -> on n'ecrit pas `state` (sinon
      // Riverpod 3 leve « Ref used after dispose »).
      if (!ref.mounted) return;
      state = FeasibilityState(
        currentQuestionIndex: state.currentQuestionIndex,
        answers: state.answers,
        questions: questions,
        result: state.result,
        isCompleted: state.isCompleted,
      );
    } catch (_) {
      // trailConfigProvider non disponible (ex: tests) : questions
      // template conservees.
    }
  }

  /// Charge un resultat precedent depuis SharedPreferences.
  Future<void> _loadSavedResult() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // `ref.mounted` apres le gap async : provider dispose pendant l'attente
      // (ex. container detruit tot en test) -> on n'ecrit pas `state` (sinon
      // Riverpod 3 leve « Ref used after dispose »).
      if (!ref.mounted) return;
      final saved = prefs.getString(_prefsKey);
      if (saved != null) {
        final data = json.decode(saved) as Map<String, dynamic>;
        final answers = (data['answers'] as Map<String, dynamic>)
            .map((k, v) => MapEntry(k, v as int));
        final result = FeasibilityCalculator.evaluate(answers);
        state = FeasibilityState(
          currentQuestionIndex: state.questions.length,
          answers: answers,
          questions: state.questions,
          result: result,
          isCompleted: true,
        );
      }
    } catch (_) {
      // Pas de resultat sauvegarde - etat initial
    }
  }

  /// Repond a la question courante et avance.
  void answerQuestion(String questionId, int score) {
    final newAnswers = Map<String, int>.from(state.answers);
    newAnswers[questionId] = score;

    final nextIndex = state.currentQuestionIndex + 1;
    final isComplete = nextIndex >= state.questions.length;

    if (isComplete) {
      final result = FeasibilityCalculator.evaluate(newAnswers);
      state = FeasibilityState(
        currentQuestionIndex: nextIndex,
        answers: newAnswers,
        questions: state.questions,
        result: result,
        isCompleted: true,
      );
      _saveResult(newAnswers);
    } else {
      state = FeasibilityState(
        currentQuestionIndex: nextIndex,
        answers: newAnswers,
        questions: state.questions,
      );
    }
  }

  /// Revient a la question precedente.
  void previousQuestion() {
    if (state.currentQuestionIndex > 0) {
      state = FeasibilityState(
        currentQuestionIndex: state.currentQuestionIndex - 1,
        answers: state.answers,
        questions: state.questions,
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
      // Echec sauvegarde - non bloquant
    }
  }
}
