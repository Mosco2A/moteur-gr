/// Le feu tricolore, enveloppe d'un parcours guide : tant que les criteres
/// obligatoires manquent, aucun verdict n'est annonce.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/screen_entry.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../i18n/translations.g.dart';
import '../providers/hiker_profile_provider.dart';
import '../providers/trek_feasibility_provider.dart';
import '../providers/walk_test_provider.dart';
import 'feasibility_guided_flow.dart';
import 'feasibility_tiles.dart';
import 'feasibility_verdict_view.dart';

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

class _TrekFeasibilityScreenState extends ConsumerState<TrekFeasibilityScreen> {
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
  void initState() {
    super.initState();
    observeScreenEntry(ref, ScreenBreadcrumb.trekFeasibility);
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
        error: (_, __) =>
            FeasibilityQuestionnaireFallback(reason: f.formula.intro),
        data: (assessment) {
          if (assessment == null) {
            // Pas d'etapes -> questionnaire de dépannage.
            return FeasibilityQuestionnaireFallback(reason: f.sourceFallback);
          }
          // D1 — AUCUN VERDICT tant que les criteres obligatoires manquent.
          if (!criteria.isComplete || _replayFlow) {
            return FeasibilityGuidedFlow(
              criteria: criteria,
              onOpenStep: _openStep,
              // Le bouton n'est actif QUE si les criteres sont complets.
              onValidate: criteria.isComplete
                  ? () => setState(() => _replayFlow = false)
                  : null,
            );
          }
          // Sinon : le verdict tricolore #100068 (avec « Recommencer »).
          return FeasibilityVerdictView(
            assessment: assessment,
            onRestart: () => setState(() => _replayFlow = true),
          );
        },
      ),
    );
  }
}
