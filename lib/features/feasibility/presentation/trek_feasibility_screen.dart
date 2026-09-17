import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/engine/trail_engine.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../i18n/translations.g.dart';
import '../domain/feasibility_formula.dart';
import '../providers/trek_feasibility_provider.dart';

/// Ecran de faisabilite profil x trek — FORMULE V1 FEU TRICOLORE (LOT 3a,
/// decision Chris #100068).
///
/// Remplace le verdict binaire « Deconseille » par un feu tricolore : chaque
/// etape est notee VERT / ORANGE / ROUGE selon le ratio effort (km-effort =
/// distance + D+/100) sur le plafond journalier deduit du profil. Le verdict
/// global nomme l'etape la plus dure, le nombre de jours au-dessus, le facteur
/// limitant, et propose des conseils de programme (jours optimal, decoupe,
/// repos). Le questionnaire reste un fallback de dépannage. Tous textes Slang.
class TrekFeasibilityScreen extends ConsumerWidget {
  const TrekFeasibilityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assessmentAsync = ref.watch(feasibilityAssessmentProvider);
    final f = t.feasibility;

    return Scaffold(
      appBar: AppHeader(title: f.formula.title),
      body: assessmentAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _FallbackToQuestionnaire(reason: f.formula.intro),
        data: (assessment) {
          if (assessment == null) {
            // Pas d'etapes -> questionnaire de dépannage.
            return _FallbackToQuestionnaire(reason: f.sourceFallback);
          }
          return _VerdictView(assessment: assessment);
        },
      ),
    );
  }
}

class _VerdictView extends ConsumerWidget {
  const _VerdictView({required this.assessment});
  final FeasibilityAssessment assessment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final f = t.feasibility;
    final trailId = ref.watch(trailConfigProvider).id;
    final hasProfileAsync = ref.watch(hasObjectiveProfileProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(f.formula.intro, style: theme.textTheme.bodyMedium),
          const SizedBox(height: AppTheme.spacingLg),

          // Verdict global (feu tricolore).
          _VerdictBadge(verdict: assessment.globalVerdict),
          const SizedBox(height: AppTheme.spacingSm),
          Center(
            child: Text(
              f.formula.ceilingLabel(
                value: _fmt(assessment.dailyCeilingKmEffort),
                level: _levelLabel(assessment.level),
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
                color: theme.colorScheme.onSurface.withAlpha(150),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppTheme.spacingLg),

          // Synthese du verdict global : etape la plus dure, jours au-dessus,
          // facteur limitant, reco entrainement.
          _GlobalSummary(assessment: assessment),
          const SizedBox(height: AppTheme.spacingLg),

          // Feu tricolore etape par etape.
          Text(f.formula.stagesTitle, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppTheme.spacingSm),
          ...assessment.stageVerdicts.map((v) => _StageTile(verdict: v)),
          const SizedBox(height: AppTheme.spacingLg),

          // Conseils de programme (jours optimal, decoupe, repos, entrainement).
          if (assessment.advice.isNotEmpty) ...[
            Text(f.formula.adviceTitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: AppTheme.spacingSm),
            ...assessment.advice.map((a) => _AdviceTile(advice: a)),
            const SizedBox(height: AppTheme.spacingLg),
          ],

          // Pont « es-tu pret ? » -> « voila comment le devenir » : prepa
          // physique (payant), porte d'entree definie par la spec.
          AppButton(
            icon: Icons.fitness_center,
            label: t.hub.cards.training,
            onPressed: () => context.push('/training'),
          ),
          const SizedBox(height: AppTheme.spacingLg),

          // LOT 1 (retour Chris #6) : acces permanent au questionnaire.
          _ShortcutCard(
            icon: Icons.quiz_outlined,
            label: t.feasibility.openQuestionnaire,
            onTap: () => context.push('/trail/$trailId/feasibility-quiz'),
          ),
          const SizedBox(height: AppTheme.spacingLg),

          // Acces rapides pour completer / affiner le profil objectif.
          hasProfileAsync.maybeWhen(
            data: (has) => _ProfileShortcuts(trailId: trailId, complete: has),
            orElse: () => _ProfileShortcuts(trailId: trailId, complete: false),
          ),
        ],
      ),
    );
  }
}

/// Synthese textuelle du verdict global (hors tout vert).
class _GlobalSummary extends StatelessWidget {
  const _GlobalSummary({required this.assessment});
  final FeasibilityAssessment assessment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final f = t.feasibility.formula;
    final color = _verdictColor(assessment.globalVerdict);

    final lines = <Widget>[];

    // Etape la plus dure (nommee) si le trek n'est pas tout vert.
    final hardest = assessment.hardestStage;
    if (hardest != null &&
        assessment.globalVerdict != FeasibilityVerdict.green) {
      lines.add(_summaryLine(
        theme,
        Icons.trending_up,
        f.hardestStage(stage: hardest.stage.name),
        color,
      ));
    }

    // Jours au-dessus du plafond.
    lines.add(_summaryLine(
      theme,
      Icons.calendar_today,
      assessment.daysOverCapacity > 0
          ? f.daysOver(count: assessment.daysOverCapacity)
          : f.daysOverNone,
      assessment.daysOverCapacity > 0 ? color : AppTheme.vertFacile,
    ));

    // Facteur limitant nomme (si present).
    if (assessment.limitingFactor != LimitingFactor.none) {
      lines.add(_summaryLine(
        theme,
        Icons.warning_amber,
        f.limitingLabel(factor: _limitingLabel(assessment.limitingFactor)),
        color,
      ));
    }

    // Reco entrainement (si non-vert).
    if (assessment.recommendedTrainingWeeks > 0) {
      lines.add(_summaryLine(
        theme,
        Icons.event_available,
        f.trainingReco(weeks: assessment.recommendedTrainingWeeks),
        theme.colorScheme.primary,
      ));
    }

    return AppCard(
      backgroundColor: color.withAlpha(14),
      borderColor: color.withAlpha(60),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < lines.length; i++) ...[
            if (i > 0) const SizedBox(height: AppTheme.spacingSm),
            lines[i],
          ],
        ],
      ),
    );
  }

  Widget _summaryLine(
      ThemeData theme, IconData icon, String text, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: AppTheme.spacingSm),
        Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
      ],
    );
  }
}

/// Badge du verdict global (feu tricolore).
class _VerdictBadge extends StatelessWidget {
  const _VerdictBadge({required this.verdict});
  final FeasibilityVerdict verdict;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _verdictColor(verdict);
    final icon = _verdictIcon(verdict);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingLg,
        vertical: AppTheme.spacingBase,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(40),
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: color.withAlpha(90)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: AppTheme.spacingSm),
          Flexible(
            child: Text(
              _verdictLabel(verdict),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tuile d'une etape avec sa pastille tricolore + son km-effort.
class _StageTile extends StatelessWidget {
  const _StageTile({required this.verdict});
  final StageVerdict verdict;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final f = t.feasibility.formula;
    final color = _verdictColor(verdict.verdict);
    final s = verdict.stage;
    return AppCard(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      backgroundColor: color.withAlpha(14),
      borderColor: color.withAlpha(60),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pastille de couleur (feu tricolore).
          Container(
            width: 14,
            height: 14,
            margin: const EdgeInsets.only(top: 3),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.name,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  f.stageEffort(
                    distance: _fmt(s.distanceKm),
                    elevation: s.elevationGainM,
                    effort: _fmt(s.effortKm),
                  ),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppTheme.spacingSm),
          Text(
            _verdictLabel(verdict.verdict),
            style: theme.textTheme.labelMedium
                ?.copyWith(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

/// Tuile d'un conseil de programme (cle -> texte i18n resolu avec params).
class _AdviceTile extends StatelessWidget {
  const _AdviceTile({required this.advice});
  final ProgramAdvice advice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.tips_and_updates_outlined,
              color: theme.colorScheme.primary, size: 20),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: Text(_adviceText(advice), style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

/// Acces rapides vers la fiche info, le test 6 min et les 5 randos.
class _ProfileShortcuts extends StatelessWidget {
  const _ProfileShortcuts({required this.trailId, required this.complete});
  final String trailId;
  final bool complete;
  @override
  Widget build(BuildContext context) {
    final f = t.feasibility;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ShortcutCard(
          icon: Icons.badge_outlined,
          label: f.openProfile,
          onTap: () => context.push('/trail/$trailId/hiker-profile'),
        ),
        _ShortcutCard(
          icon: Icons.directions_walk,
          label: f.openWalkTest,
          onTap: () => context.push('/trail/$trailId/walk-test'),
        ),
        _ShortcutCard(
          icon: Icons.history,
          label: f.openPastHikes,
          onTap: () => context.push('/trail/$trailId/past-hikes'),
        ),
      ],
    );
  }
}

class _ShortcutCard extends StatelessWidget {
  const _ShortcutCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(width: AppTheme.spacingBase),
          Expanded(
            child: Text(label, style: theme.textTheme.titleSmall),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}

/// Vue de dépannage : pas d'etapes -> questionnaire.
class _FallbackToQuestionnaire extends ConsumerWidget {
  const _FallbackToQuestionnaire({required this.reason});
  final String reason;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final f = t.feasibility;
    final trailId = ref.watch(trailConfigProvider).id;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(reason, style: theme.textTheme.bodyMedium),
          const SizedBox(height: AppTheme.spacingLg),
          _ShortcutCard(
            icon: Icons.badge_outlined,
            label: f.openProfile,
            onTap: () => context.push('/trail/$trailId/hiker-profile'),
          ),
          _ShortcutCard(
            icon: Icons.directions_walk,
            label: f.openWalkTest,
            onTap: () => context.push('/trail/$trailId/walk-test'),
          ),
          _ShortcutCard(
            icon: Icons.history,
            label: f.openPastHikes,
            onTap: () => context.push('/trail/$trailId/past-hikes'),
          ),
          const SizedBox(height: AppTheme.spacingLg),
          AppButton(
            variant: AppButtonVariant.outline,
            icon: Icons.quiz_outlined,
            label: f.sourceFallback,
            onPressed: () => context.push('/trail/$trailId/feasibility-quiz'),
          ),
        ],
      ),
    );
  }
}

// --- Helpers de resolution enum -> i18n / couleur / icone -------------------

/// Formatte un km-effort : entier si rond, sinon une decimale.
String _fmt(double value) {
  if (value == value.roundToDouble()) return value.round().toString();
  return value.toStringAsFixed(1);
}

String _verdictLabel(FeasibilityVerdict verdict) {
  final v = t.feasibility.formula.verdicts;
  switch (verdict) {
    case FeasibilityVerdict.green:
      return v.green;
    case FeasibilityVerdict.orange:
      return v.orange;
    case FeasibilityVerdict.red:
      return v.red;
  }
}

String _levelLabel(HikerLevel level) {
  final l = t.feasibility.formula.levels;
  switch (level) {
    case HikerLevel.beginner:
      return l.beginner;
    case HikerLevel.intermediate:
      return l.intermediate;
    case HikerLevel.confirmed:
      return l.confirmed;
    case HikerLevel.expert:
      return l.expert;
  }
}

String _limitingLabel(LimitingFactor factor) {
  final lf = t.feasibility.formula.limitingFactors;
  switch (factor) {
    case LimitingFactor.distance:
      return lf.distance;
    case LimitingFactor.elevation:
      return lf.elevation;
    case LimitingFactor.chaining:
      return lf.chaining;
    case LimitingFactor.none:
      return lf.none;
  }
}

String _adviceText(ProgramAdvice advice) {
  final a = t.feasibility.formula.advice;
  switch (advice.key) {
    case 'balancedOk':
      return a.balancedOk;
    case 'balanced':
      return a.balanced;
    case 'optimalDays':
      return a.optimalDays(
        days: advice.params['days'] ?? '',
        current: advice.params['current'] ?? '',
      );
    case 'split':
      return a.split(stage: advice.params['stage'] ?? '');
    case 'rest':
      return a.rest(stages: advice.params['stages'] ?? '');
    case 'training':
      return a.training(weeks: advice.params['weeks'] ?? '');
    default:
      return '';
  }
}

Color _verdictColor(FeasibilityVerdict verdict) {
  switch (verdict) {
    case FeasibilityVerdict.red:
      return AppTheme.rougeUrgence;
    case FeasibilityVerdict.orange:
      return AppTheme.orangeDifficile;
    case FeasibilityVerdict.green:
      return AppTheme.vertFacile;
  }
}

IconData _verdictIcon(FeasibilityVerdict verdict) {
  switch (verdict) {
    case FeasibilityVerdict.red:
      return Icons.dangerous;
    case FeasibilityVerdict.orange:
      return Icons.warning;
    case FeasibilityVerdict.green:
      return Icons.check_circle;
  }
}
