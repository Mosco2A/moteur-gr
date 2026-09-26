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

  /// ABONNEMENTS INCONDITIONNELS, DEPENDANCES D'ABORD (tache 548).
  ///
  /// [feasibilityCriteriaProvider] etait observe A L'INTERIEUR du `data:` de
  /// [feasibilityAssessmentProvider]. Un `ref.watch` sous condition est un
  /// abonnement INTERMITTENT : Riverpod le ferme des que le build ne le
  /// traverse plus (branche `loading` apres chaque `_refreshAssessment`), le
  /// provider — auto-dispose par defaut en Riverpod 3 — est detruit, puis
  /// REMONTE en pleine phase de build au retour de la branche `data:`. Ce
  /// remontage flushe la chaine des criteres pendant le build ; la valeur
  /// change, les providers qui en derivent (dont [hasObjectiveProfileProvider])
  /// se re-invalident et reclament un rafraichissement du `ProviderScope` —
  /// un `setState()` pendant le build, que Flutter refuse (les trois
  /// assertions relevees par la campagne 547 sur `TrekFeasibilityScreen`).
  ///
  /// Les deux observations sont donc remontees en tete de build, DEPENDANCE
  /// D'ABORD : les criteres (dont derive l'evaluation) avant l'evaluation. Les
  /// abonnements sont des lors permanents pour toute la vie de l'ecran et les
  /// invalidations de `_refreshAssessment` sont traitees par l'ordonnanceur
  /// AVANT la phase de build, jamais pendant. Aucun changement d'affichage.
  @override
  Widget build(BuildContext context) {
    final criteriaAsync = ref.watch(feasibilityCriteriaProvider);
    final assessmentAsync = ref.watch(feasibilityAssessmentProvider);
    final criteria = criteriaAsync.maybeWhen(
      data: (c) => c,
      orElse: () => const FeasibilityCriteria(
        profileComplete: false,
        hasPastHike: false,
        hasWalkTest: false,
      ),
    );
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

          // LE CONSEIL AVANT LE VERDICT (retour Chris 4, #100417) : combien de
          // jours viser, combien de repos poser et ou, ou decouper — PUIS le
          // feu. Voir [_AdviceFirst] pour le pourquoi.
          _AdviceFirst(assessment: assessment, trailId: trailId),
          const SizedBox(height: AppTheme.spacingLg),

          // HIVER : LE VERDICT EST DECLARE NON VALIDE (#1-e, #8-d). Place AVANT
          // le feu — une declaration de non-validite lue apres le verdict
          // qu'elle annule arrive trop tard.
          if (!assessment.isVerdictValid) ...[
            const _WinterInvalidNotice(),
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
          const SizedBox(height: AppTheme.spacingSm),

          // LE CALCUL, LA OU LE VERDICT TOMBE (tache 569, R3). Colle sous le
          // feu : c'est la que la question se pose.
          _VerdictHowSection(assessment: assessment),
          const SizedBox(height: AppTheme.spacingBase),

          // CE QUE LE FEU NE REGARDE PAS : PLUS AUCUNE MENTION (tache 552).
          // La mention « le poids de ton sac n'entre pas dans ce feu, de 0 a
          // 45 kg de charge le verdict ne bouge pas d'un cran » est RETIREE.
          // Elle expliquait une absence SANS RIEN CHANGER au resultat affiche :
          // c'est le resultat d'un test de sensibilite interne, pas une
          // information de randonneur. Regle posee avec Chris le 25/09 : on se
          // tait sur ce qu'on n'a pas, on parle de ce que ca change — une
          // absence qui MODIFIE un resultat reste a l'ecran (c'est le cas du
          // bandeau hiver, place plus haut par la tache 551, qui invalide le
          // verdict), une simple information absente disparait. Le poids du sac
          // continue de vivre la ou il sert : dans le Sac (sac conseille +
          // alerte descente).
          //
          // ARBITRAGE D'INTEGRATION (tache 557). Ici les taches 551 et 552 se
          // croisaient : 551 remontait le bandeau hiver AVANT le feu et gardait
          // `_OutOfScopeNotice`, 552 supprimait ce widget et sa cle i18n dans
          // les cinq langues. On garde les deux intentions non contradictoires :
          // le bandeau hiver reste a sa nouvelle place (plus haut, voir
          // `_AdviceFirst`), et la mention hors-perimetre reste supprimee —
          // c'est la decision de Chris du 25/09, et son widget comme sa cle
          // n'existent plus.

          // Synthese du verdict global : journee la plus dure, facteur
          // limitant, reco entrainement.
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

          // Les conseils, le bouton « Generer mon programme » et la ligne du
          // decoupage retenu ne sont PLUS ici : ils ouvrent l'ecran
          // ([_AdviceFirst]), avant le verdict — retour Chris 4 du 25/09.

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

/// LE CONSEIL AVANT LE VERDICT (retour Chris 4 du 25/09, spec #100417).
///
/// CE QUI N'ALLAIT PAS, MOT POUR MOT : « Apres faisabilite ca me dit que c'est
/// au-dessus de mes capacites et que je suis 3 jours au-dessus du plafond, ce
/// qui 1/ ne veut rien dire 2/ je n'ai pas encore choisi le nombre de jours.
/// C'est la qu'il faut me conseiller le nombre de jours, le nombre de jours de
/// repos et la cadence des etapes, au lieu de me dire que c'est au-dessus de mes
/// capacites. »
///
/// LE DEFAUT ETAIT UN ORDRE DE LECTURE, PAS UN CALCUL MANQUANT. Le nombre de
/// jours conseille, les repos conseilles et l'etape a decouper etaient DEJA
/// calcules et traduits dans les 5 langues ([FeasibilityAssessment.advice]) —
/// mais affiches TOUT EN BAS, apres le feu, la synthese, le circuit, les
/// conditions et les seize etapes. Le randonneur lisait donc un jugement avant
/// d'avoir lu une seule proposition.
///
/// CE BLOC OUVRE DESORMAIS L'ECRAN : combien de jours viser, combien de repos
/// poser et ou, ou decouper, puis le bouton qui APPLIQUE ce decoupage et la
/// ligne qui dit ce qui est retenu. Le feu vient apres, et il porte sur le
/// decoupage — jamais sur la personne.
class _AdviceFirst extends StatelessWidget {
  const _AdviceFirst({required this.assessment, required this.trailId});

  final FeasibilityAssessment assessment;
  final String trailId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final f = t.feasibility.formula;
    return Column(
      key: const ValueKey('feasibility-advice-first'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (assessment.advice.isNotEmpty) ...[
          Text(f.adviceTitle, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppTheme.spacingSm),
          ...assessment.advice.map((a) => _AdviceTile(advice: a)),
        ],
        // R2f (#100122 / parite GR20 `feasibility_result_screen` bouton
        // CONTINUER) : l'appli PROPOSE le planning, elle ne le demande pas. Ce
        // bouton APPLIQUE le nombre de jours conseille a la SOURCE UNIQUE des
        // jours (selectedDurationProvider), puis mene au Programme pre-rempli.
        //
        // TACHE 569 (R1-c) : PAS DE BOUTON QUAND IL N'Y A RIEN A CONSEILLER. La
        // recherche a essaye toutes les valeurs du curseur et aucune ne fait
        // mieux que rouge : un bouton « Generer mon programme (N jours) »
        // appliquerait alors une valeur que l'ecran declare mauvaise trois
        // lignes plus haut. Le conseil franc ([advice.noViableDuration]) le dit
        // a sa place.
        if (assessment.isDurationAdvised) ...[
          _GenerateProgramButton(
            trailId: trailId,
            suggestedTotalDays: assessment.suggestedTotalDays,
          ),
          const SizedBox(height: AppTheme.spacingSm),
        ],
        // D2 (#100293) — CE QUI A ETE RETENU, ECRIT NOIR SUR BLANC. Sans cette
        // ligne, choisir un decoupage ne laissait aucune trace a l'ecran : le
        // bouton etait indistinguable d'un bouton mort.
        const _RetainedPlanLine(),
      ],
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
    // La duree par defaut annoncee est celle qui S'APPLIQUE REELLEMENT : celle
    // du sentier, REPOS CONSEILLES COMPRIS (GO-61). Annoncer la duree nue
    // pendant que le programme en pose une autre serait un troisieme chiffre
    // qui ment.
    final fallback = ref.watch(
        defaultDurationWithRestProvider(ref.watch(trailIdProvider)));
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
/// APPLIQUE la duree CONSEILLEE sur la SOURCE UNIQUE des jours
/// ([selectedDurationProvider]), puis mene au Programme, deja pre-rempli et
/// modifiable ([plannedDaysProvider] watch cette duree et se recompose seul, et
/// l'Itineraire suit la meme source, R3). Un message confirme la duree
/// appliquee, et le libelle l'annonce dans SON UNITE.
///
/// TACHE 569 — LE BOUTON N'ADDITIONNE PLUS RIEN, ET C'EST TOUT L'INTERET.
/// Avant, il calculait sa cible lui-meme : `suggestedDays + recommendedRestDays`
/// borne aux durees possibles. Trois grandeurs combinees ICI, dans la couche
/// d'affichage, alors que le verdict se calcule ailleurs — c'est exactement par
/// la que le conseil et le verdict pouvaient se contredire. Il applique
/// desormais [FeasibilityAssessment.suggestedTotalDays], une valeur qui A ETE
/// ESSAYEE par la recherche : son verdict est vert ou orange, jamais rouge. Et
/// comme le curseur s'ouvre deja sur elle (R1-a), appuyer sur ce bouton ne
/// deplace plus rien tant que le randonneur n'a pas bouge le curseur lui-meme —
/// il retient le choix, ce qui est son autre role (D2).
///
/// D2 (#100293) : le choix est RETENU DURABLEMENT ([retainedDurationProvider] ->
/// SharedPreferences). Avant, il ne vivait qu'en memoire : la relance de
/// l'application le perdait, et rien a l'ecran ne disait qu'un decoupage avait
/// ete choisi.
class _GenerateProgramButton extends ConsumerWidget {
  const _GenerateProgramButton({
    required this.trailId,
    required this.suggestedTotalDays,
  });

  final String trailId;

  /// Jours TOTAUX (marche + repos) du programme conseille — l'unite du curseur.
  final int suggestedTotalDays;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final f = t.feasibility.formula;
    // La reco est deja cherchee DANS les bornes du curseur ; le clamp ne reste
    // que comme garde-fou pour les etats transitoires (etapes qui arrivent).
    final bounds = ref.watch(durationBoundsProvider(trailId));
    final target = bounds.clampDuration(suggestedTotalDays);

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

// L'ancien `_OutOfScopeNotice` a ete SUPPRIME (tache 552), avec sa cle
// `feasibility.formula.outOfScopeNotice` dans les cinq langues. Il disait que le
// poids du sac n'entrait pas dans le feu — une absence qui ne change RIEN au
// resultat affiche, donc du jargon interne a l'ecran. La regle qui l'emporte
// (Chris, 25/09) : on se tait sur ce qu'on n'a pas, on parle de ce que ca change.
// Le test `test/features/feasibility/feasibilite_hors_perimetre_test.dart`, qui
// verrouillait sa PRESENCE, verrouille desormais son ABSENCE.

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

/// LE CALCUL, MONTRE LA OU LE VERDICT TOMBE (tache 569, R3).
///
/// CE QUE CHRIS A ECRIT, MOT POUR MOT : « Le verdict c'est du blabla d'IA, tu
/// mexplique comment c'est calcule au moment ou ca le fait? » et « score 1,30
/// sans echelle ca ne veut rien dire ».
///
/// IL N'Y A AUCUNE IA DANS CETTE APPLICATION — zero dependance, verifie — et
/// c'est precisement le probleme : le moteur est une formule deterministe et
/// sourcee, mais l'ecran affichait un verdict et un score nu, ce qui se lit
/// exactement comme une boite noire. Un chiffre sans son echelle n'informe de
/// rien : 1,30 peut etre bon ou catastrophique selon ou tombe le seuil.
///
/// CE BLOC MONTRE LA DIVISION, AVEC LES CHIFFRES REELS DU RANDONNEUR : la
/// journee la plus dure et sa geometrie, sa conversion en km-energie (distance +
/// D+ / 42, Minetti 2002), le plafond du jour du randonneur, le rapport des deux,
/// et l'echelle qui dit ou tombent le vert et l'orange. Il ne dit JAMAIS « ce
/// n'est pas une IA » — on ne se defend pas d'une accusation, on montre le
/// calcul et on nomme les travaux qui le nourrissent.
class _VerdictHowSection extends StatelessWidget {
  const _VerdictHowSection({required this.assessment});
  final FeasibilityAssessment assessment;

  @override
  Widget build(BuildContext context) {
    final hardest = assessment.hardestStage;
    if (hardest == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final f = t.feasibility.formula;
    const thresholds = FeasibilityThresholds.median;

    // Les memes chiffres que ceux qui ont produit la couleur, formates une
    // seule fois : deux arrondis differents dans une division affichee se
    // liraient comme une erreur de calcul.
    final distance = _fmt(hardest.stage.distanceKm);
    final energy = _fmt(hardest.energyKm);
    final capacity = _fmt(hardest.capacityKm);

    final lines = <String>[
      f.verdictHowStage(
        stage: hardest.stage.name,
        distance: distance,
        elevation: hardest.stage.elevationGainM,
      ),
      f.verdictHowEnergy(
        distance: distance,
        elevation: hardest.stage.elevationGainM,
        energy: energy,
      ),
      f.verdictHowCeiling(
        capacity: capacity,
        level: _levelLabel(assessment.level),
      ),
      f.verdictHowRatio(
        energy: energy,
        capacity: capacity,
        score: _fmt2(hardest.score),
        green: _fmt2(thresholds.green),
        orange: _fmt2(thresholds.orange),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(f.verdictHowTitle, style: theme.textTheme.titleMedium),
        const SizedBox(height: AppTheme.spacingSm),
        AppCard(
          key: const ValueKey('feasibility-verdict-how'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final line in lines) ...[
                Text(line, style: theme.textTheme.bodySmall),
                const SizedBox(height: AppTheme.spacingXs),
              ],
              Text(
                f.verdictHowNoBlackBox,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: theme.colorScheme.onSurface.withAlpha(150),
                ),
              ),
            ],
          ),
        ),
      ],
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

    // LE SCORE NE S'AFFICHE PLUS JAMAIS NU (tache 569, R3). Chris : « score 1,30
    // sans echelle ca ne veut rien dire ». Il porte desormais ses deux seuils,
    // au meme endroit et dans la meme phrase.
    lines.add(Text(
      f.circuitScore(
        value: _fmt2(circuit.score),
        green: _fmt2(FeasibilityThresholds.median.green),
        orange: _fmt2(FeasibilityThresholds.median.orange),
      ),
      style: theme.textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: color,
      ),
    ));
    lines.add(const SizedBox(height: AppTheme.spacingXs));
    // CE QUI DECIDE, DIT EN CLAIR. Le verdict du circuit est celui de sa pire
    // journee, et rien d'autre ne peut le durcir : la phrase le dit, pour que
    // le randonneur sache ou regarder quand il veut le faire bouger.
    lines.add(Text(
      f.circuitIsWorstStage,
      key: const ValueKey('feasibility-circuit-is-worst-stage'),
      style: theme.textTheme.bodySmall,
    ));

    // --- CE QUI S'AFFICHE ET NE DECIDE PAS ---------------------------------
    final infoStyle = theme.textTheme.bodySmall?.copyWith(
      fontStyle: FontStyle.italic,
      color: theme.colorScheme.onSurface.withAlpha(150),
    );

    // C3, LE REPOS : sa fenetre, son chiffre, le conseil qui va avec — ou sa
    // NON-APPLICABILITE declaree (#10-e).
    //
    // IL A CHANGE DE STATUT (GO-61) : il etait la seule grandeur extrapolee du
    // modele autorisee a mettre au rouge, il rejoint C2 et C4 dans ce qui
    // s'affiche et ne decide pas. Ce qui reste — et qui compte — c'est le
    // CONSEIL : combien de jours de repos, et apres quelles etapes.
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
      // LE LIEN ENTRE LE PROGRAMME ET CE CHIFFRE, ECRIT. Sans cette ligne, le
      // randonneur ne voit pas que c'est SON decoupage qui le produit, ni que
      // changer le decoupage le fait bouger.
      lines.add(const SizedBox(height: 2));
      lines.add(Text(
        assessment.restDaysPlanned > 0
            ? f.restDaysCounted(count: assessment.restDaysPlanned)
            : f.restDaysNone,
        key: const ValueKey('feasibility-rest-days-counted'),
        style: theme.textTheme.bodySmall,
      ));
      if (assessment.isRestAdvised) {
        lines.add(const SizedBox(height: 2));
        lines.add(Text(
          f.restAdvisedLine(days: assessment.recommendedRestDays),
          key: const ValueKey('feasibility-rest-advised'),
          style: theme.textTheme.bodySmall
              ?.copyWith(fontWeight: FontWeight.w600),
        ));
        lines.add(const SizedBox(height: 2));
        lines.add(Text(f.restTwoDays, style: theme.textTheme.bodySmall));
      }
      // Le transfert du seuil de Foster des athletes aux randonneurs est une
      // extrapolation DECLAREE (#M08), et c'est elle qui lui a coute le droit
      // de decider. On la dit la ou le chiffre est montre.
      lines.add(const SizedBox(height: 2));
      lines.add(Text(f.restNotDecisive, style: infoStyle));
      lines.add(const SizedBox(height: 2));
      lines.add(Text(f.restExtrapolation, style: infoStyle));
    }

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

    // LE JARGON « X JOUR(S) AU-DESSUS DE TON PLAFOND » EST PARTI (retour Chris
    // 4 du 25/09). Mot pour mot : « je suis 3 jours au-dessus du plafond, ce qui
    // ne veut rien dire ». Ce comptage est une grandeur INTERNE du moteur
    // ([FeasibilityAssessment.daysOverCapacity], qui sert a nommer le facteur
    // limitant quand plusieurs journees dures s'enchainent) : elle a sa place
    // dans le calcul, aucune a l'ecran. Ce que le randonneur doit lire a la
    // place, c'est le nombre de jours a viser — il est desormais EN TETE
    // d'ecran ([_AdviceFirst]).

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

    // Plus une ligne a dire (verdict vert, aucun facteur limitant, aucune reco)
    // -> aucune carte vide : un encart sans contenu n'informe de rien.
    if (lines.isEmpty) return const SizedBox.shrink();

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

String _adviceText(ProgramAdvice advice) {
  final a = t.feasibility.formula.advice;
  switch (advice.key) {
    case 'balancedOk':
      return a.balancedOk;
    case 'balanced':
      return a.balanced;
    // TACHE 569 (R2) : le conseil de duree porte SES TROIS NOMBRES — jours de
    // marche, jours de repos, total — et ne dit « au lieu de » que si le
    // randonneur a reellement choisi un decoupage.
    case 'optimalDays':
      return a.optimalDays(
        days: advice.params['days'] ?? '',
        walk: advice.params['walk'] ?? '',
        rest: advice.params['rest'] ?? '',
        current: advice.params['current'] ?? '',
      );
    case 'optimalDaysNoChoice':
      return a.optimalDaysNoChoice(
        days: advice.params['days'] ?? '',
        walk: advice.params['walk'] ?? '',
        rest: advice.params['rest'] ?? '',
        current: advice.params['current'] ?? '',
      );
    // TACHE 569 (R4) : les cles `split` et `splitImpossible` ont DISPARU. On ne
    // conseille plus de couper une etape en deux — une etape se termine la ou il
    // y a un toit. Il reste l'alerte sur la journee, et l'entrainement.
    case 'hardStageAlert':
      return a.hardStageAlert(stage: advice.params['stage'] ?? '');
    // TACHE 569 (R1-c) : aucune valeur du curseur ne fait mieux que rouge. On
    // n'en conseille aucune, et on le dit.
    case 'noViableDuration':
      return a.noViableDuration(stage: advice.params['stage'] ?? '');
    case 'rest':
      return a.rest(stages: advice.params['stages'] ?? '');
    case 'restReference':
      return a.restReference(stages: advice.params['stages'] ?? '');
    case 'restAdvised':
      return a.restAdvised(
        days: advice.params['days'] ?? '',
        stages: advice.params['stages'] ?? '',
      );
    case 'restAdvisedReference':
      return a.restAdvisedReference(
        days: advice.params['days'] ?? '',
        stages: advice.params['stages'] ?? '',
      );
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
