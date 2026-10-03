/// Les conseils qui viennent AVANT le detail, et le geste qui
/// genere le programme.
///
/// Morceau de `trek_feasibility_screen.dart` (lot 645-06, vague 2) : meme
/// bibliotheque, donc aucune visibilite, aucun identifiant et
/// aucun site d appel ne changent.
part of 'trek_feasibility_screen.dart';

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
/// jours conseille et les repos conseilles etaient DEJA
/// calcules et traduits dans les 5 langues ([FeasibilityAssessment.advice]) —
/// mais affiches TOUT EN BAS, apres le feu, la synthese, le circuit, les
/// conditions et les seize etapes. Le randonneur lisait donc un jugement avant
/// d'avoir lu une seule proposition.
///
/// CE BLOC OUVRE DESORMAIS L'ECRAN : combien de jours viser, combien de repos
/// poser et ou, puis le bouton qui APPLIQUE ce programme et la ligne qui dit ce
/// qui est retenu. Le feu vient apres, et il porte sur le RYTHME du jour — jamais
/// sur la personne.
///
/// TACHE 639 : ce commentaire annoncait encore « ou decouper » et un feu qui
/// portait sur « le decoupage ». Le lot 634 avait retire la mecanique, la tache
/// 639 retire le mot — verbatim de Christophe (30/09 10:12) : « je ne veux pas
/// qu on decoupe les etapes ! ».
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
            suggestedPlanDays: assessment.suggestedPlanDays,
          ),
          const SizedBox(height: AppTheme.spacingSm),
        ],
        // D2 (#100293) — CE QUI A ETE RETENU, ECRIT NOIR SUR BLANC. Sans cette
        // ligne, choisir un programme ne laissait aucune trace a l'ecran : le
        // bouton etait indistinguable d'un bouton mort.
        const _RetainedPlanLine(),
      ],
    );
  }
}

/// Ligne « programme retenu » (D2, mandat #100293).
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
      defaultDurationWithRestProvider(ref.watch(trailIdProvider)),
    );
    final retainedPlan = retained != null;
    final color = retainedPlan
        ? AppTheme.vertFacile
        : theme.colorScheme.onSurface.withAlpha(160);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StepIcon(
          retainedPlan ? StepwaysIcons.coche : StepwaysIcons.radio,
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
/// desormais [FeasibilityAssessment.suggestedPlanDays], une valeur qui A ETE
/// ESSAYEE par la recherche : son verdict est vert ou orange, jamais rouge. Et
/// comme le curseur s'ouvre deja sur elle (R1-a), appuyer sur ce bouton ne
/// deplace plus rien tant que le randonneur n'a pas bouge le curseur lui-meme —
/// il retient le choix, ce qui est son autre role (D2).
///
/// D2 (#100293) : le choix est RETENU DURABLEMENT ([retainedDurationProvider] ->
/// SharedPreferences). Avant, il ne vivait qu'en memoire : la relance de
/// l'application le perdait, et rien a l'ecran ne disait qu'un programme avait
/// ete choisi.
class _GenerateProgramButton extends ConsumerWidget {
  const _GenerateProgramButton({
    required this.trailId,
    required this.suggestedPlanDays,
  });

  final String trailId;

  /// LA DUREE DU PLAN conseille : les jours de MARCHE (DEM-260930-1238).
  ///
  /// Ce parametre s'appelait `suggestedTotalDays` et portait marche PLUS repos :
  /// le bouton appliquait donc au curseur une duree gonflee par le repos, et
  /// l'annoncait dans son libelle. « Si c est 7 jours c est 7 jours ».
  final int suggestedPlanDays;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final f = t.feasibility.formula;
    // La reco est deja cherchee DANS les bornes du curseur ; le clamp ne reste
    // que comme garde-fou pour les etats transitoires (etapes qui arrivent).
    final bounds = ref.watch(durationBoundsProvider(trailId));
    final target = bounds.clampDuration(suggestedPlanDays);

    return AppButton(
      minHeight: 52,
      icon: StepwaysIcons.calendrier,
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
    const color = AppTheme.emergencyRed;
    return AppCard(
      key: const ValueKey('feasibility-winter-invalid'),
      backgroundColor: color.withAlpha(20),
      borderColor: color.withAlpha(90),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StepIcon(StepwaysIcons.neige, size: 20, color: color),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: Text(
              t.feasibility.formula.winterInvalid,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
