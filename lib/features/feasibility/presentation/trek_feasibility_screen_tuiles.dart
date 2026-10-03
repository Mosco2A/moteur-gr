/// Les tuiles d etape et de conseil, et les raccourcis vers le
/// profil du randonneur.
///
/// Morceau de `trek_feasibility_screen.dart` (lot 645-06, vague 2) : meme
/// bibliotheque, donc aucune visibilite, aucun identifiant et
/// aucun site d appel ne changent.
part of 'trek_feasibility_screen.dart';

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
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
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
            style: theme.textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
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
          StepIcon(
            StepwaysIcons.ficheConseil,
            color: theme.colorScheme.primary,
            size: 20,
          ),
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
        // GRISES EN DEMO (tache 638, bug 14) : ces trois ecrans SAISISSENT des
        // donnees de personne (age, taille, poids, test de marche, randonnees
        // passees) et les ecrivent dans le profil protege et en base. On ne
        // remplit pas la fiche de quelqu'un pendant une demonstration. Ce que la
        // demo montre a la place, c'est la COLLECTE deja faite, recapitulee
        // au-dessus du verdict (bug 5a, `_CollecteDeLaDemo`).
        GriseEnDemo(
          child: _ShortcutCard(
            icon: StepwaysIcons.myAccount,
            label: f.openProfile,
            onTap: () => context.push('/trail/$trailId/hiker-profile'),
          ),
        ),
        GriseEnDemo(
          child: _ShortcutCard(
            icon: StepwaysIcons.pas,
            label: f.openWalkTest,
            onTap: () => context.push('/trail/$trailId/walk-test'),
          ),
        ),
        GriseEnDemo(
          child: _ShortcutCard(
            icon: StepwaysIcons.historique,
            label: f.openPastHikes,
            onTap: () => context.push('/trail/$trailId/past-hikes'),
          ),
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
  final String icon;
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
          StepIcon(icon, color: theme.colorScheme.primary),
          const SizedBox(width: AppTheme.spacingBase),
          Expanded(child: Text(label, style: theme.textTheme.titleSmall)),
          const StepIcon(StepwaysIcons.chevronDroite),
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
            icon: StepwaysIcons.myAccount,
            label: f.openProfile,
            onTap: () => context.push('/trail/$trailId/hiker-profile'),
          ),
          _ShortcutCard(
            icon: StepwaysIcons.pas,
            label: f.openWalkTest,
            onTap: () => context.push('/trail/$trailId/walk-test'),
          ),
          _ShortcutCard(
            icon: StepwaysIcons.historique,
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
    // TACHE 569 (R2) : le conseil de duree porte ses nombres — jours de marche et
    // jours de repos — et ne dit « au lieu de » que si le randonneur a reellement
    // choisi un programme.
    //
    // TACHE 639 (DEM-260930-1238) : LE TOTAL A DISPARU DU LIBELLE. Il annoncait
    // « Vise 9 jours au total : 7 de marche et 2 de repos » pour un sentier de
    // sept etapes. Verbatim de Christophe : « Si c est 7 jours c est 7 jours ». Le
    // conseil vise donc les jours de MARCHE, et le repos se lit comme un conseil
    // en plus. Le parametre `days` (le total) n'est plus employe ; il reste dans
    // les parametres du conseil parce que le moteur le calcule, et il ne coute
    // rien.
    case 'optimalDays':
      return a.optimalDays(
        walk: advice.params['walk'] ?? '',
        rest: advice.params['rest'] ?? '',
        current: advice.params['current'] ?? '',
      );
    case 'optimalDaysNoChoice':
      return a.optimalDaysNoChoice(
        walk: advice.params['walk'] ?? '',
        rest: advice.params['rest'] ?? '',
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
      return AppTheme.emergencyRed;
    case FeasibilityVerdict.orange:
      return AppTheme.orangeDifficile;
    case FeasibilityVerdict.green:
      return AppTheme.vertFacile;
  }
}

String _verdictIcon(FeasibilityVerdict verdict) {
  switch (verdict) {
    case FeasibilityVerdict.red:
      return StepwaysIcons.refuser;
    case FeasibilityVerdict.orange:
      return StepwaysIcons.danger;
    case FeasibilityVerdict.green:
      return StepwaysIcons.cochePleine;
  }
}
