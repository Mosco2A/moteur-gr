/// Le verdict lui-meme : la reponse, et le volet qui montre le
/// calcul derriere elle.
///
/// Bibliotheque de l'ecran `trek_feasibility_screen.dart` (lot 645-06b).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/engine/trail_engine.dart';
import '../../../core/services/session_demo.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../i18n/translations.g.dart';
import '../../../domain/feasibility_formula.dart';
import '../providers/trek_feasibility_provider.dart';
import '../../../core/branding/stepways_icons.dart';
import 'feasibility_advice.dart';
import 'feasibility_demo_inputs.dart';
import 'feasibility_labels.dart';
import 'feasibility_summary.dart';
import 'feasibility_tiles.dart';
import 'feasibility_verdict_sections.dart';

/// Le verdict tricolore complet, avec le geste « Recommencer ».
class FeasibilityVerdictView extends ConsumerWidget {
  const FeasibilityVerdictView({
    super.key,
    required this.assessment,
    required this.onRestart,
  });
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
          // EN DEMO, LA COLLECTE SE VOIT AVANT LE VERDICT (tache 638, bug 5a —
          // DEM-260930-1012), verbatim de Christophe : « demo : on part sur le
          // resultat de faisabilite directement, sans avoir de vision des
          // informations collectees pour le faire ».
          //
          // POURQUOI UNE SECTION DE DEMO ET PAS UNE REFONTE DE L'ECRAN. La regle
          // du lot 634, posee par Christophe lui-meme le 29/09 (« Il y a trop
          // d'explication confuse »), est LA REPONSE D'ABORD : elle vaut toujours
          // pour le randonneur qui vient chercher un verdict. Mais la DEMO a un
          // autre but — « montrer comment marche l appli de A a Z » — et pour cela
          // il faut voir sur quoi le verdict repose. La section n'existe donc
          // qu'en demo, et elle passe AVANT la reponse.
          //
          // La FORMULATION du verdict (bug 5b, « pas possible » trop clivant)
          // n'est PAS traitee ici : c'est le lot #639.
          if (ref.watch(enDemoProvider)) ...[
            FeasibilityDemoInputs(assessment: assessment),
            const SizedBox(height: AppTheme.spacingLg),
          ],

          // LA REPONSE D'ABORD (tache 634, DEM-260929-1134). Retour de
          // Christophe du 29/09 11:34 : « Il y a trop d'explication confuse, ce
          // n'est pas fluide la faisabilite ». Ce que le randonneur vient
          // chercher, c'est SI il peut le faire et EN COMBIEN DE JOURS — pas
          // comment le moteur a calcule. Voir [_LaReponse].
          _LaReponse(assessment: assessment),
          const SizedBox(height: AppTheme.spacingLg),

          // Rappel si le verdict s'appuie sur un profil encore partiel : on
          // invite a completer (le resultat reste affiche — R2d). RESTE
          // VISIBLE : ce n'est pas une explication, c'est une reserve sur la
          // reponse elle-meme.
          if (!hasProfile) ...[
            PartialProfileNotice(),
            const SizedBox(height: AppTheme.spacingLg),
          ],

          // HIVER : LE VERDICT EST DECLARE NON VALIDE (#1-e, #8-d). RESTE
          // VISIBLE pour la meme raison : une declaration de non-validite qui
          // se replierait sous un volet annulerait un verdict que personne
          // n'aurait lu.
          if (!assessment.isVerdictValid) ...[
            const WinterInvalidNotice(),
            const SizedBox(height: AppTheme.spacingLg),
          ],

          // LE CONSEIL (retour Chris 4, #100417) : combien de jours viser,
          // combien de repos poser et ou, et le bouton qui applique.
          FeasibilityAdviceFirst(assessment: assessment, trailId: trailId),
          const SizedBox(height: AppTheme.spacingLg),

          // Feu tricolore etape par etape : concret, et c'est ce qui dit QUELLE
          // journee coince. Reste a l'ecran.
          Text(f.formula.stagesTitle, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppTheme.spacingSm),
          ...assessment.stageVerdicts.map(
            (v) => FeasibilityStageTile(verdict: v),
          ),
          const SizedBox(height: AppTheme.spacingLg),

          // TOUT LE CALCUL SOUS UN SEUL VOLET, REPLIE (tache 634, DEM-1134).
          //
          // CE QUI ETAIT IMPOSE AVANT. L'ecran empilait, sans qu'aucun geste ne
          // puisse les ecarter : un paragraphe d'introduction, la ligne du
          // plafond, les cinq lignes du detail de calcul, jusqu'a trois lignes
          // de synthese, deux a treize lignes de score de circuit, et quatre a
          // six puces de conditions — avant meme la liste des journees. Mesure
          // faite sur le fichier : AUCUN `ExpansionTile`, aucun repli, aucun
          // `showDialog`. Tout etait a lire, toujours.
          //
          // CE QUI CHANGE. Rien n'est supprime — les explications restent
          // DISPONIBLES, entieres, dans l'ordre. Elles ne sont simplement plus
          // IMPOSEES : un seul volet, ferme au depart, qu'on ouvre si on veut
          // savoir comment le moteur a conclu.
          _VoletDuCalcul(assessment: assessment),
          const SizedBox(height: AppTheme.spacingLg),

          // Pont « es-tu pret ? » -> « voila comment le devenir » : prepa
          // physique (payant), porte d'entree definie par la spec.
          AppButton(
            variant: AppButtonVariant.outline,
            icon: StepwaysIcons.preparationPhysique,
            label: t.hub.cards.training,
            onPressed: () => context.push('/training'),
          ),
          const SizedBox(height: AppTheme.spacingLg),

          // « Recommencer » : re-repondre au questionnaire guide (R2 : garder
          // Recommencer pour refaire fiche/test/randos).
          AppButton(
            variant: AppButtonVariant.outline,
            icon: StepwaysIcons.rafraichir,
            label: f.restart,
            onPressed: onRestart,
          ),
          const SizedBox(height: AppTheme.spacingLg),

          // Acces rapides pour completer / affiner le profil objectif.
          FeasibilityProfileShortcuts(trailId: trailId, complete: hasProfile),
        ],
      ),
    );
  }
}

/// LA REPONSE, EN TETE ET EN UNE PHRASE (tache 634, DEM-260929-1134).
///
/// Retour de Christophe du 29/09 11:34, verbatim : « Il y a trop d'explication
/// confuse, ce n'est pas fluide la faisabilite ».
///
/// CE BLOC REPOND AUX DEUX QUESTIONS QU'ON VIENT POSER, DANS CET ORDRE :
/// est-ce faisable pour moi, et en combien de jours. Le feu tricolore, la
/// phrase, et le rappel que le nombre de jours annonce est LE DECOUPAGE DU
/// SENTIER — pas un plan invente par l'application (DEM-260929-1132).
///
/// Le plafond en km-energie, le detail du calcul, le score de circuit et les
/// conditions ne sont pas ici : ce sont des explications, et elles vivent
/// desormais sous un volet qu'on ouvre ([_VoletDuCalcul]).
class _LaReponse extends StatelessWidget {
  const _LaReponse({required this.assessment});

  final FeasibilityAssessment assessment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final f = t.feasibility.formula;
    // LA DUREE ANNONCEE EST CELLE DU SENTIER (DEM-260930-1238).
    //
    // Cette ligne lisait `suggestedTotalDays` — marche PLUS repos — donc le Mare a
    // Mare Centre, sept etapes, s'annoncait « a votre portee en 9 jours ».
    // Verbatim de Christophe le 30/09 a 12:37 : « Si c est 7 jours c est 7 jours ».
    // Le repos reste dit, juste en dessous, comme un CONSEIL.
    final jours = assessment.suggestedPlanDays;
    final conseille = assessment.isDurationAdvised;
    final rouge = assessment.globalVerdict == FeasibilityVerdict.red;

    // La phrase suit le VERDICT, la seule base de calcul de l'ecran. Un verdict
    // vert ou orange sans duree conseillee ne peut pas annoncer de nombre de
    // jours : on retombe alors sur la formulation sans chiffre.
    final String phrase;
    if (rouge || !conseille) {
      phrase = f.answerRed;
    } else if (assessment.globalVerdict == FeasibilityVerdict.orange) {
      phrase = f.answerOrange(days: jours);
    } else {
      phrase = f.answerGreen(days: jours);
    }

    return Column(
      key: const ValueKey('feasibility-answer'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(f.answerTitle, style: theme.textTheme.titleMedium),
        const SizedBox(height: AppTheme.spacingSm),
        FeasibilityVerdictBadge(verdict: assessment.globalVerdict),
        const SizedBox(height: AppTheme.spacingSm),
        Text(
          phrase,
          key: const ValueKey('feasibility-answer-sentence'),
          style: theme.textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
        // D'OU VIENT LE NOMBRE DE JOURS. Le dire ici ferme la porte au reproche
        // de Christophe sur le plan a 4 jours : l'application annonce le
        // programme du sentier, elle n'en propose pas un autre.
        if (conseille && !rouge) ...[
          const SizedBox(height: AppTheme.spacingXs),
          Text(
            assessment.suggestedRestDays > 0
                ? f.answerDaysNote(
                    walking: assessment.suggestedDays,
                    rest: assessment.suggestedRestDays,
                  )
                : f.answerNoRest(walking: assessment.suggestedDays),
            key: const ValueKey('feasibility-answer-days-note'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withAlpha(150),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

/// LE VOLET DES EXPLICATIONS (tache 634, DEM-260929-1134).
///
/// Il porte, DANS LEUR ORDRE D'ORIGINE et sans rien perdre, tout ce que l'ecran
/// imposait avant la reponse : l'introduction, le plafond conseille, le detail
/// du calcul du verdict, la synthese, le score de circuit et la liste de ce qui
/// est entre — ou non — dans le verdict.
///
/// FERME AU DEPART, ET C'EST LE POINT. « Les explications doivent etre
/// disponibles, jamais imposees. »
class _VoletDuCalcul extends StatelessWidget {
  const _VoletDuCalcul({required this.assessment});

  final FeasibilityAssessment assessment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final f = t.feasibility.formula;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        key: const ValueKey('feasibility-explain-toggle'),
        initiallyExpanded: false,
        leading: StepIcon(StepwaysIcons.info, color: theme.colorScheme.primary),
        title: Text(f.explainToggle, style: theme.textTheme.titleSmall),
        childrenPadding: const EdgeInsets.fromLTRB(
          AppTheme.spacingBase,
          0,
          AppTheme.spacingBase,
          AppTheme.spacingBase,
        ),
        expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(f.intro, style: theme.textTheme.bodyMedium),
          const SizedBox(height: AppTheme.spacingBase),

          // Le plafond : c'est une explication du verdict, pas le verdict.
          Text(
            f.ceilingLabel(
              value: formatEnergyKm(assessment.dailyCapacityEnergyKm),
              level: hikerLevelLabel(assessment.level),
            ),
            style: theme.textTheme.bodySmall?.copyWith(
              fontStyle: FontStyle.italic,
              color: theme.colorScheme.onSurface.withAlpha(150),
            ),
          ),
          const SizedBox(height: AppTheme.spacingBase),

          // LE CALCUL, LA OU LE VERDICT TOMBE (tache 569, R3).
          FeasibilityVerdictHowSection(assessment: assessment),
          const SizedBox(height: AppTheme.spacingBase),

          // Synthese du verdict global : journee la plus dure, facteur
          // limitant, reco entrainement.
          FeasibilityGlobalSummary(assessment: assessment),
          const SizedBox(height: AppTheme.spacingBase),

          // SCORE DE CIRCUIT (#2-m a #2-t) + explication OBLIGATOIRE quand le
          // circuit est plus severe que toutes ses etapes (#2-s).
          FeasibilityCircuitSection(assessment: assessment),
          const SizedBox(height: AppTheme.spacingBase),

          // CE QUI EST ENTRE DANS CE VERDICT, ET CE QUI N'Y EST PAS ENTRE —
          // AVEC LA RAISON (#8-b). Une dimension neutre faute de DONNEE n'a pas
          // le meme statut qu'une dimension neutre faute de SOURCE.
          //
          // CE QUE LE FEU NE REGARDE PAS : PLUS AUCUNE MENTION (tache 552). La
          // mention « le poids de ton sac n'entre pas dans ce feu » est RETIREE
          // depuis cette tache-la, et elle le reste : on se tait sur ce qu'on
          // n'a pas, on parle de ce que ca change.
          FeasibilityConditionsSection(assessment: assessment),
        ],
      ),
    );
  }
}
