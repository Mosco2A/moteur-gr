import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../i18n/translations.g.dart';
import '../data/feasibility_question_loader.dart';
import '../data/feasibility_questions.dart';
import '../domain/feasibility_calculator.dart';

/// Provider qui charge les questions depuis le JSON configurable.
final questionsFromJsonProvider =
    FutureProvider<List<FeasibilityQuestion>>((ref) async {
  return FeasibilityQuestionLoader.load();
});

/// Etat du questionnaire avec questions JSON.
class QuestionnaireState {
  const QuestionnaireState({
    required this.questions, required this.currentIndex,
    required this.answers, this.result, this.isCompleted = false,
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

final questionnaireProvider = NotifierProvider<QuestionnaireNotifier, QuestionnaireState>(QuestionnaireNotifier.new);

class QuestionnaireNotifier extends Notifier<QuestionnaireState> {
  @override
  QuestionnaireState build() => const QuestionnaireState(questions: [], currentIndex: 0, answers: {});
  void initialize(List<FeasibilityQuestion> questions) {
    state = QuestionnaireState(questions: questions, currentIndex: 0, answers: {});
  }
  void answerQuestion(String questionId, int score) {
    final newAnswers = Map<String, int>.from(state.answers);
    newAnswers[questionId] = score;
    final nextIndex = state.currentIndex + 1;
    if (nextIndex >= state.questions.length) {
      final result = FeasibilityCalculator.evaluate(newAnswers);
      state = QuestionnaireState(questions: state.questions, currentIndex: nextIndex, answers: newAnswers, result: result, isCompleted: true);
    } else {
      state = QuestionnaireState(questions: state.questions, currentIndex: nextIndex, answers: newAnswers);
    }
  }
  void previousQuestion() {
    if (state.currentIndex > 0) {
      state = QuestionnaireState(questions: state.questions, currentIndex: state.currentIndex - 1, answers: state.answers);
    }
  }
  void reset() => state = QuestionnaireState(questions: state.questions, currentIndex: 0, answers: {});
}
/// Ecran du questionnaire de faisabilite (version configurable JSON).
///
/// Charge les questions depuis feasibility_questions.json au lancement.
/// Tout texte via Slang (t.feasibility.*) -- zero texte en dur.
class FeasibilityQuestionnaireScreen extends ConsumerStatefulWidget {
  const FeasibilityQuestionnaireScreen({super.key});
  @override
  ConsumerState<FeasibilityQuestionnaireScreen> createState() => _FeasibilityQuestionnaireScreenState();
}

class _FeasibilityQuestionnaireScreenState extends ConsumerState<FeasibilityQuestionnaireScreen> {
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
          if (state.questions.isEmpty) return const Center(child: CircularProgressIndicator());
          if (state.isCompleted && state.result != null) {
            return _QuestionnaireResultView(result: state.result!,
              onReset: () { ref.read(questionnaireProvider.notifier).reset(); });
          }
          return _QuestionnaireQuestionView(state: state,
            onAnswer: (qId, s) { ref.read(questionnaireProvider.notifier).answerQuestion(qId, s); },
            onPrevious: () { ref.read(questionnaireProvider.notifier).previousQuestion(); });
        },
      ),
    );
  }
}

class _QuestionnaireQuestionView extends StatelessWidget {
  const _QuestionnaireQuestionView({required this.state, required this.onAnswer, required this.onPrevious});
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
    return Column(children: [
      LinearProgressIndicator(value: state.progress, minHeight: 6,
        backgroundColor: theme.colorScheme.onSurface.withAlpha(30),
        valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary)),
      Padding(padding: const EdgeInsets.all(AppTheme.spacingBase),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(_resolveCategory(question.categoryKey),
            style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary)),
          Text(feasibilityT.progress
            .replaceAll('{current}', '${state.currentIndex + 1}')
            .replaceAll('{total}', '${state.totalQuestions}'),
            style: theme.textTheme.bodySmall),
        ])),
      Padding(padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
        child: Text(_resolveQuestion(question.questionKey),
          style: theme.textTheme.headlineSmall, textAlign: TextAlign.center)),
      const SizedBox(height: AppTheme.spacingLg),
      Expanded(child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingBase),
        itemCount: question.answers.length,
        itemBuilder: (context, index) {
          final answer = question.answers[index];
          final isSelected = state.answers[question.id] == answer.score;
          return Padding(padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
            child: _QuestionnaireAnswerCard(label: _resolveAnswer(answer.answerKey),
              isSelected: isSelected, onTap: () => onAnswer(question.id, answer.score)));
        })),
      if (state.currentIndex > 0)
        Padding(padding: const EdgeInsets.all(AppTheme.spacingBase),
          child: TextButton.icon(onPressed: onPrevious,
            icon: const Icon(Icons.arrow_back), label: Text(feasibilityT.previous))),
    ]);
  }
}
/// Carte de reponse cochable.
class _QuestionnaireAnswerCard extends StatelessWidget {
  const _QuestionnaireAnswerCard({required this.label, required this.isSelected, required this.onTap});
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: isSelected ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerHighest,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingBase),
          child: Row(children: [
            Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurface.withAlpha(150)),
            const SizedBox(width: AppTheme.spacingMd),
            Expanded(child: Text(label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isSelected ? theme.colorScheme.onPrimaryContainer : null))),
          ]),
        ),
      ),
    );
  }
}

/// Vue resultat avec score, jauge et recommandations. Zero texte en dur.
class _QuestionnaireResultView extends StatelessWidget {
  const _QuestionnaireResultView({required this.result, required this.onReset});
  final FeasibilityResult result;
  final VoidCallback onReset;

  String _resolveLevel(String level) {
    final resolved = t['feasibility.levels.$level'];
    if (resolved is String) return resolved;
    return level;
  }
  String _resolveCategory(String key) {
    final resolved = t['feasibility.categories.$key'];
    if (resolved is String) return resolved;
    return key;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final feasibilityT = t.feasibility;
    final color = _levelColor(result.level);
    final icon = _levelIcon(result.level);
    final label = _resolveLevel(result.level);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Column(children: [
        Text(feasibilityT.resultTitle, style: theme.textTheme.titleLarge),
        const SizedBox(height: AppTheme.spacingLg),
        SizedBox(width: 140, height: 140,
          child: Stack(fit: StackFit.expand, children: [
            CircularProgressIndicator(value: result.percentage, strokeWidth: 12,
              backgroundColor: theme.colorScheme.onSurface.withAlpha(30),
              valueColor: AlwaysStoppedAnimation(color)),
            Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, size: 36, color: color),
              Text('${result.score}/${result.maxScore}', style: theme.textTheme.headlineMedium),
            ])),
          ]),
        ),
        const SizedBox(height: AppTheme.spacingLg),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingBase, vertical: AppTheme.spacingSm),
          decoration: BoxDecoration(color: color.withAlpha(40), borderRadius: BorderRadius.circular(AppTheme.radiusChip)),
          child: Text(label, style: theme.textTheme.titleMedium?.copyWith(color: color, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: AppTheme.spacingLg),
        if (result.weakPoints.isNotEmpty) ...[
          Text(feasibilityT.weakPointsTitle, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppTheme.spacingSm),
          ...result.weakPoints.map((p) => ListTile(
            leading: const Icon(Icons.warning_amber, color: AppTheme.orangeDifficile),
            title: Text(_resolveCategory(p)), dense: true)),
          const SizedBox(height: AppTheme.spacingBase),
        ],
        if (result.strongPoints.isNotEmpty) ...[
          Text(feasibilityT.strongPointsTitle, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppTheme.spacingSm),
          ...result.strongPoints.map((p) => ListTile(
            leading: const Icon(Icons.check_circle, color: AppTheme.vertFacile),
            title: Text(_resolveCategory(p)), dense: true)),
        ],
        const SizedBox(height: AppTheme.spacingXl),
        OutlinedButton.icon(onPressed: onReset, icon: const Icon(Icons.refresh),
          label: Text(feasibilityT.restart)),
      ]),
    );
  }

  Color _levelColor(String level) {
    switch (level) {
      case FeasibilityCalculator.levelDanger: return AppTheme.rougeUrgence;
      case FeasibilityCalculator.levelCaution: return AppTheme.orangeDifficile;
      case FeasibilityCalculator.levelGood: return AppTheme.jauneModere;
      case FeasibilityCalculator.levelExcellent: return AppTheme.vertFacile;
      default: return AppTheme.grisGranite;
    }
  }

  IconData _levelIcon(String level) {
    switch (level) {
      case FeasibilityCalculator.levelDanger: return Icons.dangerous;
      case FeasibilityCalculator.levelCaution: return Icons.warning;
      case FeasibilityCalculator.levelGood: return Icons.thumb_up;
      case FeasibilityCalculator.levelExcellent: return Icons.star;
      default: return Icons.help;
    }
  }
}

