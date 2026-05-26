import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../domain/feasibility_calculator.dart';
import '../providers/feasibility_provider.dart';

/// Ecran du questionnaire de faisabilite.
///
/// Affiche une question a la fois avec progression.
/// A la fin, affiche le resultat avec recommandations.
class FeasibilityScreen extends ConsumerWidget {
  const FeasibilityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(feasibilityProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Faisabilit\u00e9'),
      ),
      body: state.isCompleted
          ? _ResultView(result: state.result!, onReset: () {
              ref.read(feasibilityProvider.notifier).reset();
            })
          : _QuestionView(
              state: state,
              onAnswer: (questionId, score) {
                ref.read(feasibilityProvider.notifier)
                    .answerQuestion(questionId, score);
              },
              onPrevious: () {
                ref.read(feasibilityProvider.notifier).previousQuestion();
              },
            ),
    );
  }
}

/// Vue question avec barre de progression.
class _QuestionView extends StatelessWidget {
  const _QuestionView({
    required this.state,
    required this.onAnswer,
    required this.onPrevious,
  });

  final FeasibilityState state;
  final void Function(String questionId, int score) onAnswer;
  final VoidCallback onPrevious;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final question = state.currentQuestion;

    return Column(
      children: [
        // Barre de progression
        LinearProgressIndicator(
          value: state.progress,
          minHeight: 6,
          backgroundColor: theme.colorScheme.onSurface.withAlpha(30),
          valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
        ),
        // Compteur
        Padding(
          padding: const EdgeInsets.all(AppTheme.spacingBase),
          child: Text(
            '${state.currentQuestionIndex + 1}/${state.totalQuestions}',
            style: theme.textTheme.bodySmall,
          ),
        ),
        // Question
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingLg,
          ),
          child: Text(
            question.questionKey,
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: AppTheme.spacingLg),
        // Reponses
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingBase,
            ),
            itemCount: question.answers.length,
            itemBuilder: (context, index) {
              final answer = question.answers[index];
              final isSelected =
                  state.answers[question.id] == answer.score;
              return Padding(
                padding: const EdgeInsets.only(
                  bottom: AppTheme.spacingSm,
                ),
                child: _AnswerCard(
                  answerKey: answer.answerKey,
                  isSelected: isSelected,
                  onTap: () => onAnswer(question.id, answer.score),
                ),
              );
            },
          ),
        ),
        // Bouton precedent
        if (state.currentQuestionIndex > 0)
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingBase),
            child: TextButton.icon(
              onPressed: onPrevious,
              icon: const Icon(Icons.arrow_back),
              label: const Text('Pr\u00e9c\u00e9dent'),
            ),
          ),
      ],
    );
  }
}

/// Carte de reponse cochable.
class _AnswerCard extends StatelessWidget {
  const _AnswerCard({
    required this.answerKey,
    required this.isSelected,
    required this.onTap,
  });

  final String answerKey;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: isSelected
          ? theme.colorScheme.primaryContainer
          : theme.colorScheme.surfaceContainerHighest,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        child: Padding(
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
                  answerKey,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isSelected
                        ? theme.colorScheme.onPrimaryContainer
                        : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Vue resultat avec score, jauge et recommandations.
class _ResultView extends StatelessWidget {
  const _ResultView({
    required this.result,
    required this.onReset,
  });

  final FeasibilityResult result;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _levelColor(result.level);
    final icon = _levelIcon(result.level);
    final label = _levelLabel(result.level);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Column(
        children: [
          // Jauge circulaire
          SizedBox(
            width: 140,
            height: 140,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: result.percentage,
                  strokeWidth: 12,
                  backgroundColor:
                      theme.colorScheme.onSurface.withAlpha(30),
                  valueColor: AlwaysStoppedAnimation(color),
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 36, color: color),
                      Text(
                        '${result.score}/${result.maxScore}',
                        style: theme.textTheme.headlineMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingLg),
          // Label recommandation
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingBase,
              vertical: AppTheme.spacingSm,
            ),
            decoration: BoxDecoration(
              color: color.withAlpha(40),
              borderRadius: BorderRadius.circular(AppTheme.radiusChip),
            ),
            child: Text(
              label,
              style: theme.textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingLg),
          // Points faibles
          if (result.weakPoints.isNotEmpty) ...[
            Text(
              'Points \u00e0 am\u00e9liorer',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: AppTheme.spacingSm),
            ...result.weakPoints.map((p) => ListTile(
                  leading: const Icon(Icons.warning_amber,
                      color: AppTheme.orangeDifficile),
                  title: Text(p),
                  dense: true,
                )),
            const SizedBox(height: AppTheme.spacingBase),
          ],
          // Points forts
          if (result.strongPoints.isNotEmpty) ...[
            Text(
              'Points forts',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: AppTheme.spacingSm),
            ...result.strongPoints.map((p) => ListTile(
                  leading: const Icon(Icons.check_circle,
                      color: AppTheme.vertFacile),
                  title: Text(p),
                  dense: true,
                )),
          ],
          const SizedBox(height: AppTheme.spacingXl),
          // Bouton recommencer
          OutlinedButton.icon(
            onPressed: onReset,
            icon: const Icon(Icons.refresh),
            label: const Text('Recommencer'),
          ),
        ],
      ),
    );
  }

  Color _levelColor(String level) {
    switch (level) {
      case FeasibilityCalculator.levelDanger:
        return AppTheme.rougeUrgence;
      case FeasibilityCalculator.levelCaution:
        return AppTheme.orangeDifficile;
      case FeasibilityCalculator.levelGood:
        return AppTheme.jauneModere;
      case FeasibilityCalculator.levelExcellent:
        return AppTheme.vertFacile;
      default:
        return AppTheme.grisGranite;
    }
  }

  IconData _levelIcon(String level) {
    switch (level) {
      case FeasibilityCalculator.levelDanger:
        return Icons.dangerous;
      case FeasibilityCalculator.levelCaution:
        return Icons.warning;
      case FeasibilityCalculator.levelGood:
        return Icons.thumb_up;
      case FeasibilityCalculator.levelExcellent:
        return Icons.star;
      default:
        return Icons.help;
    }
  }

  String _levelLabel(String level) {
    switch (level) {
      case FeasibilityCalculator.levelDanger:
        return 'D\u00e9conseill\u00e9';
      case FeasibilityCalculator.levelCaution:
        return 'Pr\u00e9paration n\u00e9cessaire';
      case FeasibilityCalculator.levelGood:
        return 'Faisable';
      case FeasibilityCalculator.levelExcellent:
        return 'Excellent';
      default:
        return '';
    }
  }
}
