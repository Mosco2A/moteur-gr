/// Ce que la demo collecte, ligne par ligne.
///
/// Morceau de `trek_feasibility_screen.dart` (lot 645-06, vague 2) : meme
/// bibliotheque, donc aucune visibilite, aucun identifiant et
/// aucun site d appel ne changent.
part of 'trek_feasibility_screen.dart';

/// CE SUR QUOI REPOSE LA REPONSE — VISIBLE UNIQUEMENT EN DEMO (tache 638,
/// bug 5a, DEM-260930-1012).
///
/// CE QUI EXISTAIT, MESURE. L'ecran portait bien une section « Ce qui est entre
/// dans ce verdict » ([_ConditionsSection]), mais elle enonce les REGLES
/// (altitude, saison, masse, age) et son propre commentaire le disait : « La
/// ligne est STATIQUE… elle enonce la regle, pas la valeur de ce randonneur ».
/// AUCUN ecran n'affichait les VALEURS. Et le parcours guide
/// ([_FeasibilityGuidedFlow]), qui montre trois cases a cocher, disparait des que
/// les criteres sont complets — donc precisement quand il y a une valeur a
/// montrer.
///
/// CE QUE CETTE SECTION MONTRE : les six entrees du calcul, avec leur VALEUR, et
/// « non renseigne » quand il n'y en a pas. Rien n'est recalcule ici : chaque
/// ligne lit le provider qui alimente DEJA le moteur, pour qu'une valeur affichee
/// ne puisse pas diverger de la valeur utilisee.
class _CollecteDeLaDemo extends ConsumerWidget {
  const _CollecteDeLaDemo({required this.assessment});

  final FeasibilityAssessment assessment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final absent = t.demo.collecteAbsent;

    final profil = ref.watch(hikerProfileProvider).value ?? HikerProfile.empty;
    final test = ref.watch(walkTestResultProvider).value;
    final randos = ref.watch(pastHikesProvider).value ?? const [];
    final trail = ref.watch(trailConfigProvider);

    String valeurProfil() {
      final morceaux = <String>[
        if (profil.age > 0) '${profil.age}',
        if (profil.heightCm > 0) '${profil.heightCm} cm',
        if (profil.weightKg > 0) '${profil.weightKg.toStringAsFixed(0)} kg',
      ];
      return morceaux.isEmpty ? absent : morceaux.join(' · ');
    }

    String valeurForme() {
      if (test == null) return absent;
      return '${test.distanceMeters.toStringAsFixed(0)} m'
          ' · ${_levelLabel(assessment.level)}';
    }

    String valeurSaison() {
      switch (assessment.conditions.season) {
        case FeasibilitySeason.winter:
          return t.checklist.seasons.winter;
        case FeasibilitySeason.spring:
          return t.checklist.seasons.spring;
        case FeasibilitySeason.summer:
          return t.checklist.seasons.summer;
        case FeasibilitySeason.autumn:
          return t.checklist.seasons.autumn;
        default:
          return absent;
      }
    }

    return AppCard(
      key: const ValueKey('demo-collecte-faisabilite'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const StepIcon(StepwaysIcons.eprouvette, size: 18),
              const SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: Text(
                  t.demo.collecteTitre,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingXs),
          Text(t.demo.collecteIntro, style: theme.textTheme.bodySmall),
          const SizedBox(height: AppTheme.spacingSm),
          _LigneDeCollecte(
            libelle: t.demo.collecteProfil,
            valeur: valeurProfil(),
          ),
          _LigneDeCollecte(
            libelle: t.demo.collecteForme,
            valeur: valeurForme(),
          ),
          _LigneDeCollecte(
            libelle: t.demo.collecteExperience,
            valeur: randos.isEmpty ? absent : '${randos.length}',
          ),
          _LigneDeCollecte(
            libelle: t.demo.collecteSaison,
            valeur: valeurSaison(),
          ),
          _LigneDeCollecte(
            libelle: t.demo.collecteSentier,
            valeur:
                '${trail.displayName} · ${trail.totalStages}'
                ' · ${trail.totalDistanceKm.toStringAsFixed(0)} km'
                ' · ${trail.totalElevationGain} m D+',
          ),
          _LigneDeCollecte(
            libelle: t.demo.collecteJours,
            valeur: assessment.suggestedTotalDays > 0
                ? '${assessment.suggestedTotalDays}'
                : absent,
          ),
        ],
      ),
    );
  }
}

/// Une ligne du recapitulatif de collecte : le libelle, puis la valeur.
class _LigneDeCollecte extends StatelessWidget {
  const _LigneDeCollecte({required this.libelle, required this.valeur});

  final String libelle;
  final String valeur;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              libelle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.grisTexteSecondaire,
              ),
            ),
          ),
          Expanded(
            flex: 6,
            child: Text(
              valeur,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
