import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../i18n/translations.g.dart';
import '../data/feasibility_question_loader.dart';
import '../data/feasibility_questions.dart';
import '../domain/feasibility_calculator.dart';
import 'feasibility_result_screen.dart';

/// Provider qui charge les questions depuis le JSON configurable.
final questionsFromJsonProvider = FutureProvider<List<FeasibilityQuestion>>((
  ref,
) async {
  return FeasibilityQuestionLoader.load();
});

/// Etat du questionnaire avec questions JSON.
class QuestionnaireState {
  const QuestionnaireState({
    required this.questions,
    required this.currentIndex,
    required this.answers,
    this.result,
    this.isCompleted = false,
  });
  final List<FeasibilityQuestion> questions;
  final int currentIndex;
  final Map<String, int> answers;
  final FeasibilityResult? result;
  final bool isCompleted;
  FeasibilityQuestion get currentQuestion => questions[currentIndex];
  int get totalQuestions => questions.length;
  double get progress => currentIndex / totalQuestions;
  String get profile => result != null ? result!.level : '';
}

final questionnaireProvider =
    NotifierProvider<QuestionnaireNotifier, QuestionnaireState>(
      QuestionnaireNotifier.new,
    );

class QuestionnaireNotifier extends Notifier<QuestionnaireState> {
  @override
  QuestionnaireState build() =>
      const QuestionnaireState(questions: [], currentIndex: 0, answers: {});
  void initialize(List<FeasibilityQuestion> questions) {
    state = QuestionnaireState(
      questions: questions,
      currentIndex: 0,
      answers: {},
    );
  }

  void answerQuestion(String questionId, int score) {
    final newAnswers = Map<String, int>.from(state.answers);
    newAnswers[questionId] = score;
    final nextIndex = state.currentIndex + 1;
    if (nextIndex >= state.questions.length) {
      final result = FeasibilityCalculator.evaluate(newAnswers);
      state = QuestionnaireState(
        questions: state.questions,
        currentIndex: nextIndex,
        answers: newAnswers,
        result: result,
        isCompleted: true,
      );
    } else {
      state = QuestionnaireState(
        questions: state.questions,
        currentIndex: nextIndex,
        answers: newAnswers,
      );
    }
  }

  void previousQuestion() {
    if (state.currentIndex > 0) {
      state = QuestionnaireState(
        questions: state.questions,
        currentIndex: state.currentIndex - 1,
        answers: state.answers,
      );
    }
  }

  void reset() => state = QuestionnaireState(
    questions: state.questions,
    currentIndex: 0,
    answers: {},
  );
}

/// Ecran du questionnaire de faisabilite (version configurable JSON).
///
/// Charge les questions depuis feasibility_questions.json au lancement.
/// Tout texte via Slang (t.feasibility.*) -- zero texte en dur.
class FeasibilityQuestionnaireScreen extends ConsumerStatefulWidget {
  const FeasibilityQuestionnaireScreen({super.key});
  @override
  ConsumerState<FeasibilityQuestionnaireScreen> createState() =>
      _FeasibilityQuestionnaireScreenState();
}

class _FeasibilityQuestionnaireScreenState
    extends ConsumerState<FeasibilityQuestionnaireScreen> {
  bool _initialized = false;
  @override
  Widget build(BuildContext context) {
    final questionsAsync = ref.watch(questionsFromJsonProvider);
    final feasibilityT = t.feasibility;
    return Scaffold(
      appBar: AppBar(title: Text(feasibilityT.title)),
      body: questionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(child: Text(feasibilityT.title)),
        data: (questions) {
          if (!_initialized) {
            _initialized = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref.read(questionnaireProvider.notifier).initialize(questions);
            });
          }
          final state = ref.watch(questionnaireProvider);
          if (state.questions.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.isCompleted && state.result != null) {
            // PARITE GR20 (#99460) : la vue resultat/verdict reutilise l'ecran
            // resultat riche (badge verdict + jauge + carte recommandation avec
            // conseils + points faibles/forts + « Recommencer »), embarque sans
            // Scaffold pour rester sous l'AppBar du questionnaire. Pas de
            // duplication : une seule implementation du resultat (#99460).
            return FeasibilityResultScreen(
              result: state.result!,
              embedded: true,
              onReset: () {
                ref.read(questionnaireProvider.notifier).reset();
              },
            );
          }
          return _QuestionnaireQuestionView(
            state: state,
            onAnswer: (qId, s) {
              ref.read(questionnaireProvider.notifier).answerQuestion(qId, s);
            },
            onPrevious: () {
              ref.read(questionnaireProvider.notifier).previousQuestion();
            },
          );
        },
      ),
    );
  }
}

class _QuestionnaireQuestionView extends StatelessWidget {
  const _QuestionnaireQuestionView({
    required this.state,
    required this.onAnswer,
    required this.onPrevious,
  });
  final QuestionnaireState state;
  final void Function(String questionId, int score) onAnswer;
  final VoidCallback onPrevious;

  String _resolveQuestion(String key) {
    final resolved = t['feasibility.questions.$key'];
    if (resolved is String) return resolved;
    return key;
  }

  String _resolveAnswer(String key) {
    final resolved = t['feasibility.answers.$key'];
    if (resolved is String) return resolved;
    return key;
  }

  String _resolveCategory(String key) {
    final resolved = t['feasibility.categories.$key'];
    if (resolved is String) return resolved;
    return key;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final question = state.currentQuestion;
    final feasibilityT = t.feasibility;
    return Column(
      children: [
        LinearProgressIndicator(
          value: state.progress,
          minHeight: 6,
          backgroundColor: theme.colorScheme.onSurface.withAlpha(30),
          valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
        ),
        Padding(
          padding: const EdgeInsets.all(AppTheme.spacingBase),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _resolveCategory(question.categoryKey),
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              Text(
                feasibilityT.progress
                    .replaceAll('{current}', '${state.currentIndex + 1}')
                    .replaceAll('{total}', '${state.totalQuestions}'),
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
          child: Text(
            _resolveQuestion(question.questionKey),
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: AppTheme.spacingLg),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingBase,
            ),
            itemCount: question.answers.length,
            itemBuilder: (context, index) {
              final answer = question.answers[index];
              final isSelected = state.answers[question.id] == answer.score;
              return Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
                child: _QuestionnaireAnswerCard(
                  label: _resolveAnswer(answer.answerKey),
                  isSelected: isSelected,
                  onTap: () => onAnswer(question.id, answer.score),
                ),
              );
            },
          ),
        ),
        if (state.currentIndex > 0)
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingBase),
            child: TextButton.icon(
              onPressed: onPrevious,
              icon: const Icon(Icons.arrow_back),
              label: Text(feasibilityT.previous),
            ),
          ),
      ],
    );
  }
}

/// Carte de reponse cochable.
class _QuestionnaireAnswerCard extends StatelessWidget {
  const _QuestionnaireAnswerCard({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // SW-SKIN-L3e : Card+InkWell -> AppCard. onTap + InkWell fournis par
    // AppCard (borne au rayon carte) ; fond de selection via backgroundColor ;
    // padding interne repris (iso-rendu de la tuile de reponse).
    return AppCard(
      backgroundColor: isSelected
          ? theme.colorScheme.primaryContainer
          : theme.colorScheme.surfaceContainerHighest,
      onTap: onTap,
      padding: const EdgeInsets.all(AppTheme.spacingBase),
      child: Row(
        children: [
          Icon(
            isSelected
                ? Icons.radio_button_checked
                : Icons.radio_button_unchecked,
            color: isSelected
                ? theme.colorScheme.onPrimaryContainer
                : theme.colorScheme.onSurface.withAlpha(150),
          ),
          const SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isSelected ? theme.colorScheme.onPrimaryContainer : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
