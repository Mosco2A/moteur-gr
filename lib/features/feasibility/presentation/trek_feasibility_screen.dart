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
/// decision Chris #100068) ENVELOPPEE d'un PARCOURS GUIDE (LOT 4, retours
/// R2a-d), dont la regle de declenchement a ete corrigee par le correctif N2
/// (D1, mandat #100293).
///
/// Parcours d'un VRAI 1er utilisateur (parite GR20 `FeasibilityQuestionnaire`) :
///   1. tant que les criteres OBLIGATOIRES ne sont pas tous fournis
///      ([feasibilityCriteriaProvider]), l'ecran ne rend AUCUN verdict : il
///      presente le parcours guide (fiche morpho -> test 6 min -> 5 randos) et
///      NOMME ce qui manque encore. C'est le comportement GR20, ou
///      `_submitQuestionnaire` n'ouvre le resultat que `if (answers.isComplete)` ;
///   2. le TEST 6 min alimente le calcul : au retour d'une etape, on invalide
///      l'evaluation pour la recalculer (R2b) ;
///   3. au complet : le FEU TRICOLORE #100068 (verdict global + etapes +
///      conseils), inchange. « Recommencer » ramene au parcours guide.
///
/// AVANT LE CORRECTIF N2, l'ecran rendait un verdict des qu'une seule saisie
/// existait — la morphologie suffisait, alors qu'elle n'entre pas dans le
/// niveau. Le retour R2d (« Valider mene TOUJOURS a un resultat ») est
/// explicitement REMPLACE par la regle de Chris du 22/09 : pas de verdict tant
/// que les criteres necessaires ne sont pas tous la.
///
/// La formule (#100068) n'est PAS modifiee ici : on la CABLE au parcours.
/// Tous les textes passent par Slang (accents FR garantis).
class TrekFeasibilityScreen extends ConsumerStatefulWidget {
  const TrekFeasibilityScreen({super.key});

  @override
  ConsumerState<TrekFeasibilityScreen> createState() =>
      _TrekFeasibilityScreenState();
}

class _TrekFeasibilityScreenState
    extends ConsumerState<TrekFeasibilityScreen> {
  /// « Recommencer » : l'utilisateur veut re-repondre au parcours guide alors
  /// que ses criteres sont deja complets. Le bouton « Valider » du parcours le
  /// ramene au verdict. Ce drapeau ne permet JAMAIS de contourner la regle : un
  /// profil incomplet reste bloque sur le parcours, quoi qu'il vaille.
  bool _replayFlow = false;

  /// Recalcule l'evaluation apres qu'une etape du parcours a ete remplie
  /// (fiche, test 6 min, randos) — garantit que le TEST change le verdict (R2b)
  /// et que les criteres remplis sont vus immediatement (D1).
  void _refreshAssessment() {
    ref.invalidate(walkTestResultProvider);
    ref.invalidate(pastHikesProvider);
    ref.invalidate(hikerProfileProvider);
    ref.invalidate(objectiveProfileProvider);
    ref.invalidate(hikerLevelProvider);
    ref.invalidate(feasibilityCriteriaProvider);
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
          final criteriaAsync = ref.watch(feasibilityCriteriaProvider);
          final criteria = criteriaAsync.maybeWhen(
            data: (c) => c,
            orElse: () => const FeasibilityCriteria(
              profileComplete: false,
              hasPastHike: false,
              hasWalkTest: false,
            ),
          );
          // D1 — AUCUN VERDICT tant que les criteres obligatoires manquent.
          if (!criteria.isComplete || _replayFlow) {
            return _FeasibilityGuidedFlow(
              criteria: criteria,
              onOpenStep: _openStep,
              // Le bouton n'est actif QUE si les criteres sont complets.
              onValidate: criteria.isComplete
                  ? () => setState(() => _replayFlow = false)
                  : null,
            );
          }
          // Sinon : le verdict tricolore #100068 (avec « Recommencer »).
          return _VerdictView(
            assessment: assessment,
            onRestart: () => setState(() => _replayFlow = true),
          );
        },
      ),
    );
  }
}

/// PARCOURS GUIDE d'entree (parite GR20) : fiche -> test 6 min -> randos,
/// barre de progression, puis bouton « Valider / Voir mon resultat ».
///
/// D1 (#100293) : ce bouton ne mene au verdict QUE si les criteres
/// obligatoires sont tous fournis. Sinon il est DESACTIVE et un encart nomme
/// ce qui manque — l'ecran ne rend aucun verdict et ne laisse pas croire
/// qu'il pourrait en rendre un. Chaque etape ouvre l'ecran de saisie existant
/// et se coche au retour. Le test 6 min alimente le calcul (R2b).
class _FeasibilityGuidedFlow extends ConsumerWidget {
  const _FeasibilityGuidedFlow({
    required this.criteria,
    required this.onOpenStep,
    required this.onValidate,
  });

  /// Completude des criteres qui conditionnent le verdict.
  final FeasibilityCriteria criteria;

  /// Ouvre un ecran de saisie (route) puis rafraichit l'evaluation au retour.
  final Future<void> Function(String route) onOpenStep;

  /// Voir le resultat — `null` tant que les criteres ne sont pas complets
  /// (bouton desactive : aucune porte vers un verdict pose sur du vide).
  final VoidCallback? onValidate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final f = t.feasibility;
    final trailId = ref.watch(trailConfigProvider).id;

    // Progression : les 3 etapes du parcours (le test reste optionnel mais
    // compte dans la barre pour encourager a le faire).
    final doneCount = criteria.doneCount;
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

          // Intro du parcours guide.
          Text(f.flow.title, style: theme.textTheme.titleLarge),
          const SizedBox(height: AppTheme.spacingSm),
          Text(f.flow.intro, style: theme.textTheme.bodyMedium),
          const SizedBox(height: AppTheme.spacingLg),

          // CE QUI MANQUE ENCORE (D1) : tant qu'un critere obligatoire n'est
          // pas la, on ne rend pas de verdict — on dit lequel manque.
          if (!criteria.isComplete) ...[
            _MissingCriteriaNotice(criteria: criteria),
            const SizedBox(height: AppTheme.spacingLg),
          ],

          // Etape 1 : fiche morpho (age/taille/poids).
          _FlowStepCard(
            step: 1,
            icon: Icons.badge_outlined,
            title: f.flow.stepProfile,
            subtitle: f.flow.stepProfileSub,
            done: criteria.profileComplete,
            onTap: () => onOpenStep('/trail/$trailId/hiker-profile'),
          ),
          // Etape 2 : test 6 minutes (optionnel mais alimente le calcul).
          _FlowStepCard(
            step: 2,
            icon: Icons.directions_walk,
            title: f.flow.stepWalkTest,
            subtitle: f.flow.stepWalkTestSub,
            done: criteria.hasWalkTest,
            optional: true,
            onTap: () => onOpenStep('/trail/$trailId/walk-test'),
          ),
          // Etape 3 : 5 dernieres randos.
          _FlowStepCard(
            step: 3,
            icon: Icons.history,
            title: f.flow.stepPastHikes,
            subtitle: f.flow.stepPastHikesSub,
            done: criteria.hasPastHike,
            onTap: () => onOpenStep('/trail/$trailId/past-hikes'),
          ),
          const SizedBox(height: AppTheme.spacingLg),

          // « Valider / Voir mon resultat » — actif SEULEMENT au complet (D1).
          AppButton(
            minHeight: 52,
            icon: Icons.check_circle_outline,
            label: f.flow.validate,
            onPressed: onValidate,
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            criteria.isComplete ? f.flow.hintReady : f.flow.hintBlocked,
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

/// Encart « il manque encore ceci » (D1, mandat #100293).
///
/// Remplace le verdict tant qu'un critere OBLIGATOIRE manque. GR20 se
/// contentait de ne rien faire quand le questionnaire etait incomplet ; ici on
/// nomme ce qui bloque, et on rappelle que le test 6 min, lui, reste optionnel
/// — sans quoi le randonneur ne saurait pas pourquoi il n'obtient rien.
class _MissingCriteriaNotice extends StatelessWidget {
  const _MissingCriteriaNotice({required this.criteria});

  final FeasibilityCriteria criteria;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final f = t.feasibility.flow;
    const color = AppTheme.orangeDifficile;

    final missing = <String>[
      if (!criteria.profileComplete) f.missingProfile,
      if (!criteria.hasPastHike) f.missingPastHikes,
    ];

    return AppCard(
      backgroundColor: color.withAlpha(20),
      borderColor: color.withAlpha(80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.pending_actions, size: 20, color: color),
              const SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: Text(
                  f.missingTitle,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(f.missingIntro, style: theme.textTheme.bodySmall),
          const SizedBox(height: AppTheme.spacingSm),
          for (final item in missing)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.radio_button_unchecked,
                      size: 14, color: color),
                  const SizedBox(width: AppTheme.spacingSm),
                  Expanded(
                    child: Text(item, style: theme.textTheme.bodyMedium),
                  ),
                ],
              ),
            ),
          if (!criteria.hasWalkTest) ...[
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              f.missingWalkTestNote,
              style: theme.textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
                color: theme.colorScheme.onSurface.withAlpha(160),
              ),
            ),
          ],
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
                value: _fmt(assessment.dailyCapacityEnergyKm),
                level: _levelLabel(assessment.level),
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
                color: theme.colorScheme.onSurface.withAlpha(150),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppTheme.spacingBase),

          // HIVER : LE VERDICT EST DECLARE NON VALIDE (#1-e, #8-d). Place
          // AVANT tout le reste — une declaration de non-validite lue apres le
          // detail arrive trop tard. On ne durcit pas le chiffre, on dit qu'il
          // ne s'applique pas.
          if (!assessment.isVerdictValid) ...[
            const _WinterInvalidNotice(),
            const SizedBox(height: AppTheme.spacingLg),
          ],

          // CE QUE LE FEU NE REGARDE PAS (#8-a). La mention s'est COUPEE EN
          // DEUX le 22/09 : la moitie « saison » est partie, puisque la saison
          // entre desormais dans le calcul ; la moitie « sac » est devenue
          // PERMANENTE, avec la mesure qui la fonde — de 0 a 45 kg de charge,
          // le verdict ne bouge pas d'un cran. Croire qu'un sac de 20 kg a ete
          // pris en compte dans un feu vert est un risque reel.
          const _OutOfScopeNotice(),
          const SizedBox(height: AppTheme.spacingLg),

          // Synthese du verdict global : etape la plus dure, jours au-dessus,
          // facteur limitant, reco entrainement.
          _GlobalSummary(assessment: assessment),
          const SizedBox(height: AppTheme.spacingLg),

          // SCORE DE CIRCUIT (#2-m a #2-t) + explication OBLIGATOIRE quand le
          // circuit est plus severe que toutes ses etapes (#2-s).
          _CircuitSection(assessment: assessment),
          const SizedBox(height: AppTheme.spacingLg),

          // CE QUI EST ENTRE DANS CE VERDICT, ET CE QUI N'Y EST PAS ENTRE —
          // AVEC LA RAISON (#8-b). Une dimension neutre faute de DONNEE n'a
          // pas le meme statut qu'une dimension neutre faute de SOURCE.
          _ConditionsSection(assessment: assessment),
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
          const SizedBox(height: AppTheme.spacingSm),
          // D2 (#100293) — CE QUI A ETE RETENU, ECRIT NOIR SUR BLANC. Sans
          // cette ligne, choisir un decoupage ne laissait aucune trace a
          // l'ecran : le bouton etait indistinguable d'un bouton mort.
          const _RetainedPlanLine(),
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

          // Acces rapides pour completer / affiner le profil objectif.
          _ProfileShortcuts(trailId: trailId, complete: hasProfile),
        ],
      ),
    );
  }
}

/// Ligne « decoupage retenu » (D2, mandat #100293).
///
/// Dit ce que le randonneur a RETENU : soit le nombre de jours qu'il a choisi
/// (et qui est desormais le plan de toute sa preparation — Programme,
/// Itineraire, Calendrier, Resume), soit, s'il n'a rien choisi, que le sentier
/// en reste a sa duree par defaut. C'est la trace visible qui manquait : avant,
/// appuyer sur « Generer mon programme » ne changeait rien de visible sur
/// l'ecran d'ou l'on venait, et le choix s'evaporait a la relance.
class _RetainedPlanLine extends ConsumerWidget {
  const _RetainedPlanLine();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final f = t.feasibility.formula;
    final retained = ref.watch(retainedDurationProvider);
    final fallback =
        ref.watch(trailConfigProvider.select((c) => c.defaultDuration));
    final retainedPlan = retained != null;
    final color = retainedPlan
        ? AppTheme.vertFacile
        : theme.colorScheme.onSurface.withAlpha(160);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          retainedPlan ? Icons.task_alt : Icons.radio_button_unchecked,
          size: 18,
          color: color,
        ),
        const SizedBox(width: AppTheme.spacingSm),
        Expanded(
          child: Text(
            retainedPlan
                ? f.retainedPlan(days: retained)
                : f.retainedPlanNone(days: fallback),
            style: theme.textTheme.bodySmall?.copyWith(
              color: retainedPlan ? color : null,
              fontWeight: retainedPlan ? FontWeight.w600 : null,
            ),
          ),
        ),
      ],
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
///
/// D2 (#100293) : le choix est desormais RETENU DURABLEMENT
/// ([retainedDurationProvider] -> SharedPreferences). Avant, il ne vivait
/// qu'en memoire : la relance de l'application le perdait, et rien a l'ecran
/// ne disait qu'un decoupage avait ete choisi.
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
/// CE QUE LE VERDICT NE REGARDE PAS — decision Chris #100279 (21/09).
///
/// Le poids du sac et la saison n'entrent PAS dans le calcul : mesure faite sur
/// l'appareil pendant la campagne personas, de 0 a 45 kg de charge (58 % du
/// poids du corps) ni le verdict ni le plafond ne bougent. Ils seront cables
/// dans une version dediee, avec des coefficients SOURCES — on n'invente pas un
/// coefficient d'effort au juge sur un sujet de securite en montagne.
///
/// En attendant, l'ecran le DIT. Laisser un randonneur croire que son sac de
/// 20 kg a ete pris en compte dans un feu vert, c'est lui faire courir un risque
/// reel. Place juste sous le feu tricolore : c'est la que la mention compte.
class _OutOfScopeNotice extends StatelessWidget {
  const _OutOfScopeNotice();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurface;
    return AppCard(
      backgroundColor: color.withAlpha(14),
      borderColor: color.withAlpha(60),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.visibility_off_outlined,
              size: 20, color: color.withAlpha(180)),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: Text(
              t.feasibility.formula.outOfScopeNotice,
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

/// HIVER — LE VERDICT EST DECLARE NON VALIDE (#1-e, #2-j, #8-d).
///
/// POURQUOI UNE DECLARATION ET NON UN COEFFICIENT. Les cotations officielles de
/// sentier ne valent qu'« par bon temps, terrain sec et enneigement adapte »
/// (#S11-a). Hors de ces conditions, il n'existe aucune mesure publiee pour
/// durcir un verdict d'un montant justifiable : inventer un coefficient
/// d'hiver, ce serait produire un chiffre qui a l'air d'une mesure et n'en est
/// pas. On dit donc que le verdict ne tient plus — ce qui est vrai, verifiable,
/// et bien plus utile qu'un faux chiffre.
class _WinterInvalidNotice extends StatelessWidget {
  const _WinterInvalidNotice();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const color = AppTheme.rougeUrgence;
    return AppCard(
      key: const ValueKey('feasibility-winter-invalid'),
      backgroundColor: color.withAlpha(20),
      borderColor: color.withAlpha(90),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.ac_unit, size: 20, color: color),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: Text(
              t.feasibility.formula.winterInvalid,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// LE SCORE DE CIRCUIT (#2-m a #2-t) — les quatre contraintes, celle qui mord,
/// et l'explication OBLIGATOIRE d'ARB-004.
///
/// CE QUE CETTE SECTION EVITE. Le verdict global n'est plus la pire etape : il
/// est le maximum de trois contraintes normalisees, dont deux ne se voient dans
/// AUCUNE etape prise isolement. Sans cette section, un randonneur verrait sept
/// etapes vertes surmontees d'un circuit rouge et conclurait a un bug — c'est
/// exactement pour cela que la spec rend l'explication obligatoire.
class _CircuitSection extends StatelessWidget {
  const _CircuitSection({required this.assessment});
  final FeasibilityAssessment assessment;

  @override
  Widget build(BuildContext context) {
    final circuit = assessment.circuit;
    if (circuit == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final f = t.feasibility.formula;
    final color = _verdictColor(circuit.verdict);

    final lines = <Widget>[];

    lines.add(Text(
      f.circuitScore(value: _fmt2(circuit.score)),
      style: theme.textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: color,
      ),
    ));
    lines.add(const SizedBox(height: AppTheme.spacingXs));
    lines.add(Text(
      f.circuitDominant(constraint: _constraintLabel(circuit.dominant)),
      style: theme.textTheme.bodySmall,
    ));

    // ARB-004 : OBLIGATION d'expliquer quand le circuit est plus severe que
    // toutes ses etapes. Le texte nomme la contrainte responsable.
    if (assessment.isCircuitHarsherThanStages) {
      lines.add(const SizedBox(height: AppTheme.spacingSm));
      lines.add(Text(
        f.circuitHarsherIntro,
        key: const ValueKey('feasibility-circuit-harsher'),
        style: theme.textTheme.bodySmall
            ?.copyWith(fontWeight: FontWeight.w600, color: color),
      ));
      final why = switch (circuit.dominant) {
        CircuitConstraint.rest => f.circuitHarsherByRest,
        CircuitConstraint.averageLoad => f.circuitHarsherByAverage,
        _ => null,
      };
      if (why != null) {
        lines.add(const SizedBox(height: 2));
        lines.add(Text(why, style: theme.textTheme.bodySmall));
      }
    }

    // C3, le repos : sa fenetre, ou sa NON-APPLICABILITE declaree (#10-e).
    lines.add(const SizedBox(height: AppTheme.spacingSm));
    if (!circuit.isRestApplicable) {
      lines.add(Text(
        f.restNotApplicable,
        key: const ValueKey('feasibility-rest-not-applicable'),
        style: theme.textTheme.bodySmall,
      ));
    } else {
      lines.add(Text(
        circuit.monotonyCoversWholeTrek
            ? f.restWindowWhole(days: circuit.totalDays)
            : f.restWindowSlice(
                start: circuit.monotonyWindowStartDay ?? 1,
                end: circuit.monotonyWindowEndDay ?? circuit.totalDays,
              ),
        style: theme.textTheme.bodySmall,
      ));
      // LE LIEN ENTRE LE PROGRAMME ET LE VERDICT, ECRIT. Sans cette ligne, un
      // circuit rouge par manque de repos est illisible : le randonneur ne
      // voit pas que c'est SON decoupage qui le produit, ni que changer le
      // decoupage change le chiffre.
      lines.add(const SizedBox(height: 2));
      lines.add(Text(
        assessment.restDaysPlanned > 0
            ? f.restDaysCounted(count: assessment.restDaysPlanned)
            : f.restDaysNone,
        key: const ValueKey('feasibility-rest-days-counted'),
        style: theme.textTheme.bodySmall?.copyWith(
          fontWeight: assessment.restDaysPlanned > 0
              ? FontWeight.normal
              : FontWeight.w600,
        ),
      ));
      if (circuit.dominant == CircuitConstraint.rest) {
        lines.add(const SizedBox(height: 2));
        lines.add(Text(f.restTwoDays, style: theme.textTheme.bodySmall));
      }
      // Le transfert du seuil de Foster des athletes aux randonneurs est une
      // extrapolation DECLAREE (#M08). On la dit la ou le chiffre est montre.
      lines.add(const SizedBox(height: 2));
      lines.add(Text(
        f.restExtrapolation,
        style: theme.textTheme.bodySmall?.copyWith(
          fontStyle: FontStyle.italic,
          color: theme.colorScheme.onSurface.withAlpha(150),
        ),
      ));
    }

    // --- CE QUI S'AFFICHE ET NE DECIDE PAS ---------------------------------
    final infoStyle = theme.textTheme.bodySmall?.copyWith(
      fontStyle: FontStyle.italic,
      color: theme.colorScheme.onSurface.withAlpha(150),
    );

    // C2, la charge moyenne : sortie du maximum (elle est la moyenne d'une
    // serie dont C1 est le maximum, donc elle ne pouvait rien decider), mais
    // elle informe reellement — lue AVEC C1, elle distingue « une journee
    // dure » de « dur tous les jours ».
    if (circuit.averageLoad.isFinite) {
      lines.add(const SizedBox(height: AppTheme.spacingSm));
      lines.add(Text(
        f.averageLoad(
          value: _fmt2(circuit.averageLoad),
          worst: _fmt2(circuit.worstStage),
        ),
        key: const ValueKey('feasibility-average-load'),
        style: theme.textTheme.bodySmall,
      ));
      lines.add(const SizedBox(height: 2));
      lines.add(Text(f.averageLoadInfo, style: infoStyle));
    }

    // C4, l'ecart a l'habitude : AFFICHE, JAMAIS DECISIF (#2-q).
    final habit = circuit.habitGap;
    if (habit != null && habit.isFinite) {
      lines.add(const SizedBox(height: AppTheme.spacingSm));
      lines.add(Text(
        f.habitGap(value: _fmt2(habit)),
        style: theme.textTheme.bodySmall,
      ));
      lines.add(const SizedBox(height: 2));
      lines.add(Text(f.habitGapNotDecisive, style: infoStyle));
    }

    // LA DUREE, ENONCEE. Le modele ne la capte nulle part : C3 mesure une
    // REGULARITE, pas une LONGUEUR, et rend le meme chiffre pour trois jours et
    // pour dix-sept. Aucun seuil publie n'existe pour la scorer, donc on
    // n'invente rien — on dit le fait et le randonneur juge.
    if (assessment.hasDurationStatement) {
      lines.add(const SizedBox(height: AppTheme.spacingSm));
      lines.add(Text(
        f.durationStatement(
          days: assessment.walkingDays,
          done: assessment.longestConsecutiveDaysDone,
        ),
        key: const ValueKey('feasibility-duration-statement'),
        style: theme.textTheme.bodySmall,
      ));
      lines.add(const SizedBox(height: 2));
      lines.add(Text(f.durationStatementInfo, style: infoStyle));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(f.circuitTitle, style: theme.textTheme.titleMedium),
        const SizedBox(height: AppTheme.spacingSm),
        AppCard(
          backgroundColor: color.withAlpha(14),
          borderColor: color.withAlpha(60),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: lines,
          ),
        ),
      ],
    );
  }
}

/// CE QUI EST ENTRE DANS CE VERDICT, ET CE QUI N'Y EST PAS ENTRE (#8-b).
///
/// LA DISTINCTION QUE CETTE SECTION PORTE. « L'altitude ne change rien ici »
/// peut vouloir dire deux choses opposees : que le sentier culmine sous le
/// seuil ou QUE LA TRACE N'EN PORTE PAS. Dans le premier cas le verdict est
/// complet, dans le second il est aveugle sur une dimension. Une application de
/// securite en montagne doit dire laquelle des deux.
class _ConditionsSection extends StatelessWidget {
  const _ConditionsSection({required this.assessment});
  final FeasibilityAssessment assessment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final f = t.feasibility.formula;
    final conditions = assessment.conditions;
    final lines = <String>[];

    // 1. L'unite d'energie, dite une fois : le chiffre affiche partout en
    // decoule, et 42 n'est pas un nombre qu'on devine.
    lines.add(f.energyUnitNotice);

    // 2. Le plancher demontre, quand il a REELLEMENT releve la capacite.
    if (assessment.isDemonstratedFloorActive) {
      lines.add(f.floorActive(
        value: _fmt(assessment.demonstratedFloorEnergyKm),
      ));
    }

    // 3. L'altitude : appliquee, sous le seuil, ou absente de la trace.
    final altitude = conditions.maxAltitudeM;
    switch (conditions.altitudeNeutralReason) {
      case NeutralReason.missingData:
        lines.add(f.altitudeMissing);
        break;
      case NeutralReason.belowThreshold:
        lines.add(f.altitudeBelowThreshold(value: altitude!.round()));
        break;
      default:
        lines.add(f.altitudeApplied(
          value: (altitude ?? 0).round(),
          pct: _fmt((1 - conditions.altitudeFactor) * 100),
        ));
    }

    // 4. La saison : ete chiffre, printemps/automne sans source, ou pas de
    // date de depart posee. L'hiver est deja declare plus haut.
    if (!conditions.isWinterDeparture) {
      switch (conditions.seasonNeutralReason) {
        case NeutralReason.missingData:
          lines.add(f.seasonMissing);
          break;
        case NeutralReason.noPublishedSource:
          lines.add(f.seasonNoSource);
          break;
        default:
          lines.add(f.heatApplied);
      }
    }

    // 5. La masse : hors du verdict, ET C'EST UNE PROPRIETE ASSUMEE (#3-d).
    lines.add(f.massNotCounted);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(f.conditionsTitle, style: theme.textTheme.titleMedium),
        const SizedBox(height: AppTheme.spacingSm),
        AppCard(
          key: const ValueKey('feasibility-conditions'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final line in lines) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Icon(Icons.circle,
                          size: 6,
                          color: theme.colorScheme.onSurface.withAlpha(120)),
                    ),
                    const SizedBox(width: AppTheme.spacingSm),
                    Expanded(
                      child: Text(line, style: theme.textTheme.bodySmall),
                    ),
                  ],
                ),
                if (line != lines.last)
                  const SizedBox(height: AppTheme.spacingXs),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

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
                    effort: _fmt(verdict.energyKm),
                  ),
                  style: theme.textTheme.bodySmall,
                ),
                // #2-l : l'etape NOMME son facteur dominant. Sans cela, un
                // randonneur qui voit deux etapes oranges ne sait pas laquelle
                // est orange a cause de l'altitude et laquelle l'est a cause
                // du denivele — donc ne sait pas quoi changer.
                if (verdict.isOverCapacity) ...[
                  const SizedBox(height: 2),
                  Text(
                    // Libelle DISTINCT de celui du verdict global : deux
                    // phrases identiques a deux niveaux de lecture differents
                    // laisseraient croire a la meme affirmation.
                    f.stageDominantFactor(
                      factor: _limitingLabel(verdict.dominantFactor),
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: color,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
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
        ],
      ),
    );
  }
}

// --- Helpers de resolution enum -> i18n / couleur / icone -------------------

/// Formatte un km-energie : entier si rond, sinon une decimale.
String _fmt(double value) {
  if (!value.isFinite) return '—';
  if (value == value.roundToDouble()) return value.round().toString();
  return value.toStringAsFixed(1);
}

/// Formatte un SCORE (sans unite) a deux decimales : a une seule, 1,04 et 1,10
/// s'afficheraient tous deux « 1,1 » alors qu'ils tombent de part et d'autre du
/// seuil rouge.
String _fmt2(double value) {
  if (!value.isFinite) return '—';
  return value.toStringAsFixed(2);
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
    case LimitingFactor.altitude:
      return lf.altitude;
    case LimitingFactor.heat:
      return lf.heat;
    case LimitingFactor.chaining:
      return lf.chaining;
    case LimitingFactor.none:
      return lf.none;
  }
}

String _constraintLabel(CircuitConstraint constraint) {
  final c = t.feasibility.formula.circuitConstraints;
  switch (constraint) {
    case CircuitConstraint.worstStage:
      return c.worstStage;
    case CircuitConstraint.averageLoad:
      return c.averageLoad;
    case CircuitConstraint.rest:
      return c.rest;
    case CircuitConstraint.habitGap:
      return c.habitGap;
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
    case 'restDominant':
      return a.restDominant;
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
