import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/engine/trail_engine.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../i18n/translations.g.dart';
import '../../planning/providers/planning_provider.dart';
import '../domain/feasibility_formula.dart';
import '../providers/hiker_profile_provider.dart';
import '../providers/trek_feasibility_provider.dart';
import '../providers/walk_test_provider.dart';

/// Ecran de faisabilite profil x trek — FORMULE V1 FEU TRICOLORE (LOT 3a,
/// decision Chris #100068) ENVELOPPEE d'un FLUX GUIDE (LOT 4, retours R2a-d).
///
/// Parcours d'un VRAI 1er utilisateur (parite GR20 `FeasibilityQuestionnaire`) :
///   1. au 1er acces (profil objectif absent -> `hasObjectiveProfileProvider`
///      faux), on NE calcule PAS un verdict sur du vide : on presente un
///      QUESTIONNAIRE GUIDE etape par etape (fiche morpho -> test 6 min ->
///      5 randos) avec barre de progression et un bouton « Valider / Voir mon
///      resultat » qui mene TOUJOURS au verdict (R2a/R2c/R2d) ;
///   2. le TEST 6 min alimente le calcul : au retour d'une etape, on invalide
///      l'evaluation pour la recalculer (R2b) ;
///   3. la sortie reste le FEU TRICOLORE #100068 (verdict global + etapes +
///      conseils), inchange. On garde « Recommencer » (re-repondre au flux).
///
/// La formule (#100068) n'est PAS modifiee ici : on la CABLE au flux.
/// Tous les textes passent par Slang (accents FR garantis).
class TrekFeasibilityScreen extends ConsumerStatefulWidget {
  const TrekFeasibilityScreen({super.key});

  @override
  ConsumerState<TrekFeasibilityScreen> createState() =>
      _TrekFeasibilityScreenState();
}

class _TrekFeasibilityScreenState
    extends ConsumerState<TrekFeasibilityScreen> {
  /// L'utilisateur a appuye sur « Valider / Voir mon resultat » : on force
  /// l'affichage du verdict meme si le profil objectif reste partiel (le bouton
  /// mene TOUJOURS a un resultat — R2c/R2d). « Recommencer » repasse a false.
  bool _showResult = false;

  /// Recalcule l'evaluation apres qu'une etape du flux a ete remplie (fiche,
  /// test 6 min, randos) — garantit que le TEST change le verdict (R2b).
  void _refreshAssessment() {
    ref.invalidate(walkTestResultProvider);
    ref.invalidate(pastHikesProvider);
    ref.invalidate(hikerProfileProvider);
    ref.invalidate(objectiveProfileProvider);
    ref.invalidate(hikerLevelProvider);
    ref.invalidate(hasObjectiveProfileProvider);
    ref.invalidate(feasibilityAssessmentProvider);
  }

  /// Pousse un ecran de saisie puis, au retour, rafraichit l'evaluation.
  Future<void> _openStep(String route) async {
    await context.push(route);
    if (!mounted) return;
    _refreshAssessment();
  }

  @override
  Widget build(BuildContext context) {
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
          final hasProfileAsync = ref.watch(hasObjectiveProfileProvider);
          final hasProfile = hasProfileAsync.maybeWhen(
            data: (has) => has,
            orElse: () => false,
          );
          // FLUX GUIDE au 1er acces (profil objectif vide) tant que
          // l'utilisateur n'a pas demande a voir son resultat (R2a/R2c/R2d).
          if (!hasProfile && !_showResult) {
            return _FeasibilityGuidedFlow(
              onOpenStep: _openStep,
              onValidate: () => setState(() => _showResult = true),
            );
          }
          // Sinon : le verdict tricolore #100068 (avec « Recommencer »).
          return _VerdictView(
            assessment: assessment,
            onRestart: () => setState(() => _showResult = false),
          );
        },
      ),
    );
  }
}

/// FLUX GUIDE d'entree (parite GR20) : fiche -> test 6 min -> randos, barre de
/// progression, puis bouton « Valider / Voir mon resultat » (mene TOUJOURS au
/// verdict). Chaque etape ouvre l'ecran de saisie existant et se coche au
/// retour (R2a/R2c/R2d). Le test 6 min alimente le calcul (R2b).
class _FeasibilityGuidedFlow extends ConsumerWidget {
  const _FeasibilityGuidedFlow({
    required this.onOpenStep,
    required this.onValidate,
  });

  /// Ouvre un ecran de saisie (route) puis rafraichit l'evaluation au retour.
  final Future<void> Function(String route) onOpenStep;

  /// L'utilisateur valide et demande a voir son resultat.
  final VoidCallback onValidate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final f = t.feasibility;
    final trailId = ref.watch(trailConfigProvider).id;

    // Etat de completion de chaque etape (pour cocher + la barre de progression).
    final profileAsync = ref.watch(hikerProfileProvider);
    final walkTestAsync = ref.watch(walkTestResultProvider);
    final pastHikesAsync = ref.watch(pastHikesProvider);

    final profileDone =
        profileAsync.maybeWhen(data: (p) => !p.isEmpty, orElse: () => false);
    final walkTestDone = walkTestAsync.maybeWhen(
        data: (w) => w != null, orElse: () => false);
    final hikesDone = pastHikesAsync.maybeWhen(
        data: (h) => h.isNotEmpty, orElse: () => false);

    // Progression : part des 3 etapes remplies (le test reste optionnel mais
    // compte dans la barre pour encourager a le faire).
    final doneCount =
        (profileDone ? 1 : 0) + (walkTestDone ? 1 : 0) + (hikesDone ? 1 : 0);
    final progress = doneCount / 3.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Barre de progression (parite GR20 questionnaire).
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusChip),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: theme.colorScheme.onSurface.withAlpha(30),
              valueColor:
                  AlwaysStoppedAnimation(theme.colorScheme.primary),
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            f.flow.progress(done: doneCount, total: 3),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withAlpha(160),
            ),
          ),
          const SizedBox(height: AppTheme.spacingLg),

          // Intro du flux guide.
          Text(f.flow.title, style: theme.textTheme.titleLarge),
          const SizedBox(height: AppTheme.spacingSm),
          Text(f.flow.intro, style: theme.textTheme.bodyMedium),
          const SizedBox(height: AppTheme.spacingLg),

          // Etape 1 : fiche morpho (age/taille/poids).
          _FlowStepCard(
            step: 1,
            icon: Icons.badge_outlined,
            title: f.flow.stepProfile,
            subtitle: f.flow.stepProfileSub,
            done: profileDone,
            onTap: () => onOpenStep('/trail/$trailId/hiker-profile'),
          ),
          // Etape 2 : test 6 minutes (optionnel mais alimente le calcul).
          _FlowStepCard(
            step: 2,
            icon: Icons.directions_walk,
            title: f.flow.stepWalkTest,
            subtitle: f.flow.stepWalkTestSub,
            done: walkTestDone,
            optional: true,
            onTap: () => onOpenStep('/trail/$trailId/walk-test'),
          ),
          // Etape 3 : 5 dernieres randos.
          _FlowStepCard(
            step: 3,
            icon: Icons.history,
            title: f.flow.stepPastHikes,
            subtitle: f.flow.stepPastHikesSub,
            done: hikesDone,
            onTap: () => onOpenStep('/trail/$trailId/past-hikes'),
          ),
          const SizedBox(height: AppTheme.spacingLg),

          // Bouton « Valider / Voir mon resultat » : mene TOUJOURS au verdict
          // (R2c/R2d), meme si le profil reste partiel (on encourage juste a
          // completer via le sous-titre d'aide).
          AppButton(
            minHeight: 52,
            icon: Icons.check_circle_outline,
            label: f.flow.validate,
            onPressed: onValidate,
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            doneCount == 0 ? f.flow.hintEmpty : f.flow.hintPartial,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withAlpha(150),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

/// Carte d'une etape du flux guide (numero, icone, titre, etat coche).
class _FlowStepCard extends StatelessWidget {
  const _FlowStepCard({
    required this.step,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.done,
    required this.onTap,
    this.optional = false,
  });
  final int step;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool done;
  final bool optional;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final accent = done ? AppTheme.vertFacile : colors.primary;
    return AppCard(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      onTap: onTap,
      child: Row(
        children: [
          // Pastille numero -> coche verte quand l'etape est remplie.
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withAlpha(30),
              shape: BoxShape.circle,
              border: Border.all(color: accent.withAlpha(120)),
            ),
            child: done
                ? Icon(Icons.check, color: accent, size: 20)
                : Text(
                    '$step',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(color: accent, fontWeight: FontWeight.bold),
                  ),
          ),
          const SizedBox(width: AppTheme.spacingBase),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 18, color: colors.onSurface),
                    const SizedBox(width: AppTheme.spacingXs),
                    Flexible(
                      child: Text(
                        title,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    if (optional) ...[
                      const SizedBox(width: AppTheme.spacingXs),
                      Text(
                        t.feasibility.flow.optionalTag,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colors.onSurface.withAlpha(140),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}

class _VerdictView extends ConsumerWidget {
  const _VerdictView({required this.assessment, required this.onRestart});
  final FeasibilityAssessment assessment;

  /// « Recommencer » : repasse au flux guide pour re-repondre.
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final f = t.feasibility;
    final trailId = ref.watch(trailConfigProvider).id;
    final hasProfileAsync = ref.watch(hasObjectiveProfileProvider);
    final hasProfile = hasProfileAsync.maybeWhen(
      data: (has) => has,
      orElse: () => false,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(f.formula.intro, style: theme.textTheme.bodyMedium),
          const SizedBox(height: AppTheme.spacingLg),

          // Rappel si le verdict s'appuie sur un profil encore partiel : on
          // invite a completer (le resultat reste affiche — R2d).
          if (!hasProfile) ...[
            _PartialProfileNotice(),
            const SizedBox(height: AppTheme.spacingLg),
          ],

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

          // R2f (#100122 / parite GR20 `feasibility_result_screen` bouton
          // CONTINUER) : l'appli PROPOSE le planning, elle ne le demande pas.
          // Ce bouton APPLIQUE la reco de la formule (#100068 : nb de jours
          // optimal) a la SOURCE UNIQUE des jours (selectedDurationProvider),
          // puis mene au Programme deja pre-rempli et modifiable.
          _GenerateProgramButton(
            trailId: trailId,
            suggestedDays: assessment.suggestedDays,
          ),
          const SizedBox(height: AppTheme.spacingLg),

          // Pont « es-tu pret ? » -> « voila comment le devenir » : prepa
          // physique (payant), porte d'entree definie par la spec.
          AppButton(
            variant: AppButtonVariant.outline,
            icon: Icons.fitness_center,
            label: t.hub.cards.training,
            onPressed: () => context.push('/training'),
          ),
          const SizedBox(height: AppTheme.spacingLg),

          // « Recommencer » : re-repondre au questionnaire guide (R2 : garder
          // Recommencer pour refaire fiche/test/randos).
          AppButton(
            variant: AppButtonVariant.outline,
            icon: Icons.refresh,
            label: f.restart,
            onPressed: onRestart,
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
          _ProfileShortcuts(trailId: trailId, complete: hasProfile),
        ],
      ),
    );
  }
}

/// Bouton « Generer mon programme » (R2f, parite GR20 « CONTINUER »).
///
/// APPLIQUE la reco de la formule #100068 : fixe le nombre de jours de MARCHE
/// optimal ([FeasibilityAssessment.suggestedDays]) sur la SOURCE UNIQUE
/// ([selectedDurationProvider]) — borne aux durees possibles du sentier
/// ([durationBoundsProvider]) — puis mene au Programme, deja pre-rempli et
/// modifiable ([plannedDaysProvider] watch cette duree et se recompose seul, et
/// l'Itineraire suit maintenant la meme source, R3). Un message confirme la
/// duree appliquee. Le libelle indique la duree proposee pour etre explicite.
class _GenerateProgramButton extends ConsumerWidget {
  const _GenerateProgramButton({
    required this.trailId,
    required this.suggestedDays,
  });

  final String trailId;

  /// Nombre de jours de MARCHE optimal propose par la formule (#100068).
  final int suggestedDays;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final f = t.feasibility.formula;
    // Borne la reco aux durees realistes du sentier (nb d'etapes) : jamais moins
    // d'un regroupement raisonnable, jamais plus que le max de repos possible.
    final bounds = ref.watch(durationBoundsProvider(trailId));
    final target = bounds.clampDuration(suggestedDays);

    return AppButton(
      minHeight: 52,
      icon: Icons.event_available,
      label: f.generateProgram(days: target),
      onPressed: () {
        // Applique la reco a la source unique des jours (D2 / #100122).
        ref.read(selectedDurationProvider.notifier).set(target);
        // Confirmation breve (le Programme s'ouvre pre-rempli sur cette duree).
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(f.generateProgramDone(days: target))),
        );
        // Mene au Programme (parite GR20 : CONTINUER pousse vers la config).
        context.push('/trail/$trailId/planning');
      },
    );
  }
}

/// Bandeau « profil partiel » affiche au-dessus du verdict quand le profil
/// objectif n'est pas encore renseigne (le resultat reste montre — R2d).
class _PartialProfileNotice extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const color = AppTheme.orangeDifficile;
    return AppCard(
      backgroundColor: color.withAlpha(20),
      borderColor: color.withAlpha(80),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 20, color: color),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: Text(
              t.feasibility.flow.partialNotice,
              style: theme.textTheme.bodySmall,
            ),
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
