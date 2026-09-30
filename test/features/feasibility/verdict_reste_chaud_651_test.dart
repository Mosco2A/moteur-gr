import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/config/test_trail_config.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/features/feasibility/domain/feasibility_formula.dart';
import 'package:moteur_gr/features/feasibility/domain/hiker_profile.dart';
import 'package:moteur_gr/features/feasibility/domain/objective_profile.dart';
import 'package:moteur_gr/features/feasibility/providers/hiker_profile_provider.dart';
import 'package:moteur_gr/features/feasibility/providers/trek_feasibility_provider.dart';
import 'package:moteur_gr/features/training/providers/training_plan_providers.dart';

/// NON-REGRESSION — TACHE 651 : LE VERDICT RESTE CHAUD ENTRE DEUX ECRANS.
///
/// CE TEST EST NE D UNE HYPOTHESE QUI S EST REVELEE FAUSSE, ET IL RESTE POUR
/// CA. En cherchant pourquoi le rappel de prudence de MAJEUR-4 manquait a
/// l ecran Preparation physique (defaut B, campagne 650), j ai soupconne la
/// chaine du verdict d etre DETRUITE en quittant l ecran Faisabilite — les
/// providers generes sont auto-dispose par defaut en Riverpod 3 — et donc
/// RECALCULEE de zero a chaque ecran : relecture des etapes, des randos, des
/// conditions du trek (trace GPX), plus la recherche de duree qui reevalue la
/// formule pour chaque duree du curseur. Cela aurait explique un bandeau qui
/// arrive des secondes trop tard.
///
/// LA MESURE DIT NON : les providers declares a la main de cette chaine ne sont
/// PAS auto-dispose, le verdict survit a la fermeture du dernier abonnement, et
/// l ecran suivant le lit sans le repayer. La vraie cause du defaut B etait
/// ailleurs (l essai bride de la demo n affichait aucun rappel) et elle est
/// corrigee a sa place.
///
/// CE QUE CE TEST GARDE. L invariant vaut d etre verrouille pour lui-meme : un
/// verdict est une fonction pure d entrees PERSISTEES, et l ecran Faisabilite
/// l invalide LUI-MEME apres chaque saisie (`_refreshAssessment`). S il devenait
/// un jour auto-dispose — un `.autoDispose`, une migration, un passage au
/// codegen — tout ce qui en derive (le rappel de prudence, le bouton « Generer
/// mon programme ») se mettrait a arriver en retard, et personne ne le verrait
/// venir. Le second test verrouille l autre moitie : garder chaud ne doit PAS
/// empecher un verdict de repartir sur une saisie neuve.
void main() {
  const stages = <StageEffort>[
    StageEffort(
      index: 0,
      name: 'Depart -> Col',
      distanceKm: 14,
      elevationGainM: 1000,
    ),
    StageEffort(
      index: 1,
      name: 'Col -> Refuge',
      distanceKm: 12,
      elevationGainM: 600,
    ),
  ];

  /// Conteneur cable sur la chaine REELLE, avec un COMPTEUR sur la donnee la
  /// plus en amont : chaque recalcul du verdict la relit.
  ({ProviderContainer c, List<int> lectures}) conteneur() {
    final lectures = <int>[0];
    final container = ProviderContainer(
      overrides: [
        trailConfigProvider.overrideWithValue(testTrailConfig),
        stageEffortsProvider.overrideWith((ref) async {
          lectures[0]++;
          return stages;
        }),
        objectiveProfileProvider.overrideWith(
          (ref) async => _objectifDebutante,
        ),
        hikerProfileProvider.overrideWith(() => _FicheFigee(_fiche)),
        restDaysAfterStageProvider.overrideWithValue(const {0}),
        trekConditionsProvider.overrideWith(
          (ref) async => TrekConditions.unknown,
        ),
      ],
    );
    addTearDown(container.dispose);
    return (c: container, lectures: lectures);
  }

  test('quitter l ecran Faisabilite NE detruit PAS le verdict : l ecran suivant '
      'le lit sans le repayer', () async {
    final (c: container, lectures: lectures) = conteneur();

    // 1. L'ecran Faisabilite s'abonne au verdict et l'affiche.
    final abonnement = container.listen(
      feasibilityAssessmentProvider,
      (_, __) {},
    );
    final verdict = await container.read(feasibilityAssessmentProvider.future);
    expect(verdict, isNotNull);
    expect(lectures[0], 1, reason: 'un seul calcul pour le premier ecran');

    // 2. L'ecran est QUITTE : son abonnement se ferme. LA DESTRUCTION EST
    //    DIFFEREE (Riverpod la programme pour la fin de la tache en cours) :
    //    on laisse donc la boucle tourner, sinon le test mesurerait un cache
    //    qui n'a simplement pas encore eu le temps d'etre vide — et passerait
    //    au vert sans rien prouver.
    abonnement.close();
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    // 3. L'ecran suivant (Preparation physique) lit le MEME verdict pour son
    //    rappel de prudence.
    final perso = await container.read(trainingPersonalizationProvider.future);
    expect(perso.verdict, verdict!.globalVerdict);
    expect(perso.needsCaution, isTrue);

    expect(
      lectures[0],
      1,
      reason:
          'le verdict doit etre reste CHAUD. Sans cela, la chaine entiere '
          'est recalculee (etapes, randos, conditions via la trace GPX, et la '
          'recherche de duree par essais) : le rappel de prudence et le bouton '
          '« Generer mon programme » n arrivent que des secondes plus tard, '
          'voire jamais a l ecran (mesure 651 sur emulateur)',
    );
  });

  test(
    'une invalidation explicite RECALCULE bien (garder chaud ne fige rien)',
    () async {
      final (c: container, lectures: lectures) = conteneur();

      await container.read(feasibilityAssessmentProvider.future);
      expect(lectures[0], 1);

      // C'est ce que fait `_refreshAssessment` apres chaque saisie du parcours
      // guide : le verdict chaud doit repartir de zero quand on le lui demande.
      container.invalidate(stageEffortsProvider);
      container.invalidate(feasibilityAssessmentProvider);
      await container.read(feasibilityAssessmentProvider.future);

      expect(
        lectures[0],
        2,
        reason:
            'garder le verdict chaud ne doit PAS l empecher de repartir sur '
            'une saisie neuve : sinon un randonneur corrigerait sa fiche sans '
            'que son feu change',
      );
    },
  );
}

/// La debutante de la campagne : une sortie modeste -> feu non vert.
final _objectifDebutante = ObjectiveProfile(
  maxElevationGainPerDayDone: 200,
  maxDistancePerDayDone: 10,
  maxConsecutiveDaysDone: 1,
  maxDailyEnergyKmDone: FeasibilityScale.v2.energyOf(
    distanceKm: 10,
    elevationGainM: 200,
  ),
  habitualDailyEnergyKm: FeasibilityScale.v2.energyOf(
    distanceKm: 10,
    elevationGainM: 200,
  ),
  fitnessLevelRank: 1,
  hasWalkTest: false,
);

const _fiche = HikerProfile(age: 32, heightCm: 170, weightKg: 62);

class _FicheFigee extends HikerProfileNotifier {
  _FicheFigee(this._profile);
  final HikerProfile _profile;

  @override
  Future<HikerProfile> build() async => _profile;
}
