import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/ui/error_view.dart';
import '../../../../core/ui/loading_view.dart';
import '../../domain/models/feasibility_profile.dart';

// ---------------------------------------------------------------------------
// Modeles locaux pour les questions configurables
// ---------------------------------------------------------------------------

/// Type de question supporte par le questionnaire.
enum QuestionType { singleChoice, slider, boolean }

/// Option de choix unique pour une question [singleChoice].
class QuestionOption {
  const QuestionOption({
    required this.value,
    required this.labelFr,
    required this.labelEn,
    this.icon,
    this.maxKmPerDay,
    this.maxHoursPerDay,
  });

  final String value;
  final String labelFr;
  final String labelEn;
  final String? icon;
  final double? maxKmPerDay;
  final double? maxHoursPerDay;

  factory QuestionOption.fromJson(Map<String, dynamic> json) {
    return QuestionOption(
      value: json['value'] as String,
      labelFr: json['labelFr'] as String,
      labelEn: json['labelEn'] as String,
      icon: json['icon'] as String?,
      maxKmPerDay: (json['maxKmPerDay'] as num?)?.toDouble(),
      maxHoursPerDay: (json['maxHoursPerDay'] as num?)?.toDouble(),
    );
  }
}

/// Definition d'une question de faisabilite chargee depuis le JSON.
class FeasibilityQuestion {
  const FeasibilityQuestion({
    required this.id,
    required this.field,
    required this.labelFr,
    required this.labelEn,
    required this.type,
    this.options = const [],
    this.min,
    this.max,
    this.divisions,
    this.defaultValue,
    this.unit,
  });

  final String id;
  final String field;
  final String labelFr;
  final String labelEn;
  final QuestionType type;
  final List<QuestionOption> options;
  final double? min;
  final double? max;
  final int? divisions;
  final dynamic defaultValue;
  final String? unit;

  factory FeasibilityQuestion.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String;
    final type = switch (typeStr) {
      'single_choice' => QuestionType.singleChoice,
      'slider' => QuestionType.slider,
      'boolean' => QuestionType.boolean,
      _ => QuestionType.singleChoice,
    };

    return FeasibilityQuestion(
      id: json['id'] as String,
      field: json['field'] as String,
      labelFr: json['labelFr'] as String,
      labelEn: json['labelEn'] as String,
      type: type,
      options: (json['options'] as List<dynamic>?)
              ?.map((o) =>
                  QuestionOption.fromJson(o as Map<String, dynamic>))
              .toList() ??
          [],
      min: (json['min'] as num?)?.toDouble(),
      max: (json['max'] as num?)?.toDouble(),
      divisions: json['divisions'] as int?,
      defaultValue: json['defaultValue'],
      unit: json['unit'] as String?,
    );
  }
}

// ---------------------------------------------------------------------------
// Provider : profil de faisabilite du randonneur
// ---------------------------------------------------------------------------

/// Provider pour le profil de faisabilite du randonneur.
///
/// Profil par defaut : forme moyenne, experience intermediaire.
/// Mis a jour par le questionnaire de faisabilite.
/// Overridable en tests ou depuis un ecran de profil utilisateur.
final feasibilityProfileProvider = StateProvider<FeasibilityProfile>((ref) {
  return const FeasibilityProfile(
    fitnessLevel: 'average',
    experience: 'intermediate',
    maxKmPerDay: 20.0,
    maxHoursPerDay: 8.0,
  );
});

// ---------------------------------------------------------------------------
// Provider : charge les questions depuis le JSON asset
// ---------------------------------------------------------------------------

/// Provider qui charge les questions de faisabilite depuis
/// `assets/data/feasibility_questions.json`.
///
/// Le JSON est configurable par sentier : il suffit de fournir un fichier
/// different dans les assets pour adapter les questions.
final feasibilityQuestionsProvider =
    FutureProvider<List<FeasibilityQuestion>>((ref) async {
  final jsonStr = await rootBundle.loadString(
    'assets/data/feasibility_questions.json',
  );
  final data = json.decode(jsonStr) as Map<String, dynamic>;
  final questions = (data['questions'] as List<dynamic>)
      .map((q) =>
          FeasibilityQuestion.fromJson(q as Map<String, dynamic>))
      .toList();
  return questions;
});

// ---------------------------------------------------------------------------
// Ecran questionnaire de faisabilite
// ---------------------------------------------------------------------------

/// Ecran questionnaire de faisabilite.
///
/// Charge les questions depuis le JSON configurable par sentier
/// et les affiche une par une dans un PageView.
/// A la fin, construit un [FeasibilityProfile] et met a jour
/// [feasibilityProfileProvider].
///
/// Types de questions supportes :
/// - [singleChoice] : grille de boutons avec icones
/// - [slider] : curseur avec min/max/divisions
/// - [boolean] : switch oui/non
///
/// Route GoRouter : /feasibility
class FeasibilityQuestionnaireScreen extends ConsumerStatefulWidget {
  const FeasibilityQuestionnaireScreen({super.key});

  @override
  ConsumerState<FeasibilityQuestionnaireScreen> createState() =>
      _FeasibilityQuestionnaireScreenState();
}

class _FeasibilityQuestionnaireScreenState
    extends ConsumerState<FeasibilityQuestionnaireScreen> {
  final _pageController = PageController();
  final Map<String, dynamic> _answers = {};
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final questionsAsync = ref.watch(feasibilityQuestionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Votre profil'),
      ),
      body: questionsAsync.when(
        loading: () =>
            const LoadingView(message: 'Chargement du questionnaire...'),
        error: (error, _) => ErrorView(
          error: error,
          onRetry: () => ref.invalidate(feasibilityQuestionsProvider),
        ),
        data: (questions) => _buildQuestionnaire(questions),
      ),
    );
  }

  Widget _buildQuestionnaire(List<FeasibilityQuestion> questions) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Indicateur de progression
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingBase,
            vertical: AppTheme.spacingSm,
          ),
          child: LinearProgressIndicator(
            value: questions.isEmpty
                ? 0
                : (_currentPage + 1) / questions.length,
            backgroundColor: AppTheme.grisClair.withAlpha(40),
            minHeight: 4,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingBase,
          ),
          child: Text(
            '${_currentPage + 1} / ${questions.length}',
            style: theme.textTheme.bodySmall,
          ),
        ),
        const SizedBox(height: AppTheme.spacingSm),

        // Pages de questions
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: questions.length,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemBuilder: (context, index) {
              return _QuestionPage(
                question: questions[index],
                currentAnswer: _answers[questions[index].field],
                onAnswerChanged: (value) {
                  setState(() {
                    _answers[questions[index].field] = value;

                    // Si la question fitness_level a des suggestions
                    // de km/h, on les applique comme defauts
                    if (questions[index].field == 'fitnessLevel') {
                      final option = questions[index]
                          .options
                          .where((o) => o.value == value)
                          .firstOrNull;
                      if (option != null) {
                        _answers['maxKmPerDay'] ??=
                            option.maxKmPerDay;
                        _answers['maxHoursPerDay'] ??=
                            option.maxHoursPerDay;
                      }
                    }
                  });
                },
              );
            },
          ),
        ),

        // Boutons navigation
        Padding(
          padding: const EdgeInsets.all(AppTheme.spacingBase),
          child: Row(
            children: [
              if (_currentPage > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: _goBack,
                    child: const Text('Precedent'),
                  ),
                ),
              if (_currentPage > 0)
                const SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: ElevatedButton(
                  onPressed: _canGoNext(questions)
                      ? () => _goNext(questions)
                      : null,
                  child: Text(
                    _currentPage == questions.length - 1
                        ? 'Valider'
                        : 'Suivant',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  bool _canGoNext(List<FeasibilityQuestion> questions) {
    if (questions.isEmpty) return false;
    final q = questions[_currentPage];
    // Les sliders et booleans ont toujours une valeur par defaut
    if (q.type == QuestionType.slider ||
        q.type == QuestionType.boolean) {
      return true;
    }
    return _answers.containsKey(q.field);
  }

  void _goBack() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _goNext(List<FeasibilityQuestion> questions) {
    if (_currentPage < questions.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _submitProfile();
    }
  }

  void _submitProfile() {
    final profile = FeasibilityProfile(
      fitnessLevel:
          (_answers['fitnessLevel'] as String?) ?? 'average',
      experience:
          (_answers['experience'] as String?) ?? 'intermediate',
      maxKmPerDay:
          (_answers['maxKmPerDay'] as double?) ?? 20.0,
      maxHoursPerDay:
          (_answers['maxHoursPerDay'] as double?) ?? 8.0,
      groupMode: (_answers['groupMode'] as bool?) ?? false,
    );

    ref.read(feasibilityProfileProvider.notifier).state = profile;

    if (mounted) {
      Navigator.of(context).pop(profile);
    }
  }
}

// ---------------------------------------------------------------------------
// Widget question individuelle
// ---------------------------------------------------------------------------

/// Affiche une question selon son type : choix unique, slider ou boolean.
class _QuestionPage extends StatelessWidget {
  const _QuestionPage({
    required this.question,
    required this.currentAnswer,
    required this.onAnswerChanged,
  });

  final FeasibilityQuestion question;
  final dynamic currentAnswer;
  final ValueChanged<dynamic> onAnswerChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingBase,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppTheme.spacingLg),
          Text(
            question.labelFr,
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: AppTheme.spacingLg),
          Expanded(
            child: switch (question.type) {
              QuestionType.singleChoice =>
                _buildSingleChoice(context),
              QuestionType.slider => _buildSlider(context),
              QuestionType.boolean => _buildBoolean(context),
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSingleChoice(BuildContext context) {
    final theme = Theme.of(context);
    final selected = currentAnswer as String?;

    return ListView.separated(
      itemCount: question.options.length,
      separatorBuilder: (_, __) =>
          const SizedBox(height: AppTheme.spacingSm),
      itemBuilder: (context, index) {
        final option = question.options[index];
        final isSelected = selected == option.value;
        final icon = _iconFromName(option.icon);

        return Card(
          color: isSelected
              ? theme.colorScheme.primaryContainer
              : null,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(AppTheme.radiusCard),
            side: isSelected
                ? BorderSide(
                    color: theme.colorScheme.primary,
                    width: 2,
                  )
                : BorderSide.none,
          ),
          child: ListTile(
            leading: Icon(
              icon,
              color: isSelected
                  ? theme.colorScheme.onPrimaryContainer
                  : theme.colorScheme.onSurface,
            ),
            title: Text(
              option.labelFr,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight:
                    isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? theme.colorScheme.onPrimaryContainer
                    : null,
              ),
            ),
            onTap: () => onAnswerChanged(option.value),
          ),
        );
      },
    );
  }

  Widget _buildSlider(BuildContext context) {
    final theme = Theme.of(context);
    final value = (currentAnswer as double?) ??
        (question.defaultValue as num?)?.toDouble() ??
        question.min ??
        0;
    final minVal = question.min ?? 0;
    final maxVal = question.max ?? 100;
    final clampedValue = value.clamp(minVal, maxVal);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${clampedValue.toStringAsFixed(clampedValue.truncateToDouble() == clampedValue ? 0 : 1)}'
            ' ${question.unit ?? ''}',
            style: theme.textTheme.displayLarge?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: AppTheme.spacingLg),
          Slider(
            value: clampedValue,
            min: minVal,
            max: maxVal,
            divisions: question.divisions,
            label: '${clampedValue.toStringAsFixed(0)} ${question.unit ?? ''}',
            onChanged: (v) => onAnswerChanged(v),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingBase,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${minVal.toStringAsFixed(0)} ${question.unit ?? ''}',
                  style: theme.textTheme.bodySmall,
                ),
                Text(
                  '${maxVal.toStringAsFixed(0)} ${question.unit ?? ''}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoolean(BuildContext context) {
    final theme = Theme.of(context);
    final value = (currentAnswer as bool?) ??
        (question.defaultValue as bool?) ??
        false;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            value ? Icons.group : Icons.person,
            size: 64,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: AppTheme.spacingLg),
          Text(
            value ? 'Oui' : 'Non',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: AppTheme.spacingBase),
          Switch.adaptive(
            value: value,
            onChanged: (v) => onAnswerChanged(v),
          ),
        ],
      ),
    );
  }

  /// Convertit un nom d'icone Material en IconData.
  ///
  /// Supporte un sous-ensemble d'icones courantes.
  /// Retourne [Icons.help_outline] si le nom est inconnu.
  static IconData _iconFromName(String? name) {
    return switch (name) {
      'airline_seat_recline_normal' => Icons.airline_seat_recline_normal,
      'directions_walk' => Icons.directions_walk,
      'hiking' => Icons.hiking,
      'fitness_center' => Icons.fitness_center,
      'school' => Icons.school,
      'terrain' => Icons.terrain,
      'landscape' => Icons.landscape,
      'military_tech' => Icons.military_tech,
      'group' => Icons.group,
      'person' => Icons.person,
      _ => Icons.help_outline,
    };
  }
}
