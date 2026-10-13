import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/core/models/stage_row.dart';
import 'package:moteur_gr/domain/feasibility_formula.dart';
import 'package:moteur_gr/domain/feasibility_program_rules.dart';
import 'package:moteur_gr/features/feasibility/domain/objective_profile.dart';
import 'package:moteur_gr/features/feasibility/providers/trek_feasibility_provider.dart';
import 'package:moteur_gr/features/planning/providers/planned_days_provider.dart';
import 'package:moteur_gr/features/planning/providers/planning_provider.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

/// ON NE COMPARE RIEN TANT QUE RIEN N'A ETE CHOISI (tache 750).
///
/// LE DEFAUT QUE CE FICHIER INTERDIT DE REFAIRE. Verbatim, Christophe le 09/10
/// a 09:49 : « La faisabilite dit : vise 7 jours de marches au lieu des 7 jours
/// d'aujourd'hui ... et on a encore rien selectionne en plus. Ton circuit
/// faisabilite est tout pourri ».
///
/// DEUX DEFAUTS PRODUISAIENT CETTE SEULE PHRASE, ET IL FALLAIT LES DEUX :
///
///   1. LE DRAPEAU MENTAIT. `feasibilityProgramProvider` tenait « la liste des
///      jours n'est pas vide » pour « le randonneur a choisi ». Or
///      `PlannedDaysNotifier` AMORCE son etat avec une repartition calculee des
///      que les etapes arrivent : la liste est pleine avant le moindre geste.
///      `fromProgram` partait donc a vrai, l'ecran prenait la formulation de
///      COMPARAISON, et les trois libelles ecrits pour le cas « rien choisi »
///      (`optimalDaysNoChoice`, `restReference`, `restAdvisedReference`)
///      etaient inatteignables — dont deux qui disent « tu n'as pas encore
///      choisi le tien ».
///
///   2. LES DEUX NOMBRES COMPARES N'AVAIENT PAS LA MEME UNITE. La phrase dit
///      « ${walk} jours de marche, au lieu des ${current} jours d'aujourd'hui »
///      : les deux moities parlent de MARCHE. On passait `currentTotalDays`,
///      marche ET repos confondus. Un conseil a 7 jours de marche + 1 repos
///      face a un programme de 7 jours de marche verifiait donc « 8 > 7 » et
///      s'ecrivait « vise 7 au lieu de 7 ».
///
/// CE QUE CES TESTS VERROUILLENT :
///   A. la garde : aucune cle de [comparisonAdviceKeys] ne sort sans choix ;
///   B. l'unite : `current` compte des jours de MARCHE, jamais le total ;
///   C. jamais deux nombres egaux dans une phrase de comparaison ;
///   D. le cablage REEL : sans duree retenue ni edition a la main, le verdict
///      se declare « programme de reference », et il se declare « programme du
///      randonneur » des que l'un des deux gestes a eu lieu.
void main() {
  const trailId = 'test-trail';

  setUpAll(() => LocaleSettings.setLocaleRaw('fr'));

  // ==========================================================================
  // A, B, C — LA REGLE, AU NIVEAU DU MOTEUR
  // ==========================================================================

  /// Sept journees identiques et LOURDES : 20 km + 900 m D+ = 41,43 km-energie
  /// pour un plafond intermediaire de 38,67 -> score 1,07, donc ROUGE. Il faut
  /// un verdict hors du vert, sinon le moteur sort par `balancedOk` et aucun
  /// conseil de duree n'est emis : le test ne prouverait rien.
  const sept = [
    StageEffort(index: 0, name: 'A', distanceKm: 20, elevationGainM: 900),
    StageEffort(index: 1, name: 'B', distanceKm: 20, elevationGainM: 900),
    StageEffort(index: 2, name: 'C', distanceKm: 20, elevationGainM: 900),
    StageEffort(index: 3, name: 'D', distanceKm: 20, elevationGainM: 900),
    StageEffort(index: 4, name: 'E', distanceKm: 20, elevationGainM: 900),
    StageEffort(index: 5, name: 'F', distanceKm: 20, elevationGainM: 900),
    StageEffort(index: 6, name: 'G', distanceKm: 20, elevationGainM: 900),
  ];

  FeasibilityAssessment evaluer({
    required bool fromProgram,
    required int walkingDays,
    required int restDays,
    Set<int> restAfterStageIndex = const {},
  }) => FeasibilityFormula.evaluate(
    stages: sept,
    level: HikerLevel.intermediate,
    fromProgram: fromProgram,
    restAfterStageIndex: restAfterStageIndex,
    durationAdvice: ProgramDurationAdvice(
      walkingDays: walkingDays,
      restDays: restDays,
    ),
  );

  group('A. la garde : rien de choisi, rien de compare', () {
    test('sans choix, AUCUNE phrase de comparaison ne sort', () {
      final cles = evaluer(
        fromProgram: false,
        walkingDays: 9,
        restDays: 2,
      ).advice.map((a) => a.key).toSet();

      expect(
        cles.intersection(comparisonAdviceKeys),
        isEmpty,
        reason:
            'une phrase qui oppose deux nombres suppose que le second est un '
            'CHOIX ; sans choix, il vaut le programme de reference du sentier '
            'et la phrase compare le sentier a lui-meme',
      );
    });

    test('sans choix, la variante de reference prend le relais', () {
      final cles = evaluer(
        fromProgram: false,
        walkingDays: 9,
        restDays: 2,
      ).advice.map((a) => a.key).toList();

      expect(cles, contains('optimalDaysNoChoice'));
      expect(cles, isNot(contains('optimalDays')));
    });

    test(
      'sans choix, la phrase de reference ne porte meme pas de valeur courante',
      () {
        final conseil = evaluer(
          fromProgram: false,
          walkingDays: 9,
          restDays: 2,
        ).advice.firstWhere((a) => a.key == 'optimalDaysNoChoice');

        expect(
          conseil.params.containsKey('current'),
          isFalse,
          reason:
              'transporter une valeur courante dans une phrase qui ne compare '
              'rien, c est la laisser revenir a la premiere retouche de texte',
        );
      },
    );

    test('la garde nomme bien la phrase fautive du 09/10', () {
      expect(
        comparisonAdviceKeys,
        contains('optimalDays'),
        reason:
            'c est LA phrase que Christophe a vue ; si elle sort de la liste, '
            'la garde ne garde plus rien',
      );
    });
  });

  group('B. l unite : `current` compte des jours de MARCHE', () {
    test('avec des repos poses, la comparaison ignore le total', () {
      // Programme courant : 7 journees de marche ET 2 repos = 9 jours au total.
      // Conseil : 9 journees de marche. La phrase doit opposer 9 a 7 — les
      // jours de MARCHE — et jamais 9 a 9, qui serait le total.
      final conseil = evaluer(
        fromProgram: true,
        walkingDays: 9,
        restDays: 2,
        restAfterStageIndex: const {1, 3},
      ).advice.firstWhere((a) => a.key == 'optimalDays');

      expect(
        conseil.params['current'],
        7,
        reason:
            'la phrase dit « jours de marche ... jours d aujourd hui » : les '
            'deux moities sont dans la meme unite',
      );
      expect(
        conseil.params['current'],
        isNot(9),
        reason: 'ce 9 serait le total marche + repos, l unite de l autre bout',
      );
    });
  });

  group('C. jamais deux nombres egaux dans une comparaison', () {
    test('LE CAS DU 09/10 : 7 jours de marche conseilles sur 7 deja poses, '
        'seuls des repos s ajoutent -> on ne compare plus', () {
      // C'est exactement la situation vue par Christophe : le conseil ne
      // change PAS le nombre de journees de marche, il ajoute un repos. Le
      // total progresse (8 > 7), la condition d emission etait donc vraie,
      // et la phrase s ecrivait « vise 7 au lieu de 7 ».
      final cles = evaluer(
        fromProgram: true,
        walkingDays: 7,
        restDays: 1,
      ).advice.map((a) => a.key).toList();

      expect(
        cles,
        isNot(contains('optimalDays')),
        reason: 'sept contre sept n est pas une comparaison, c est un bug',
      );
    });

    test('quand elle sort, ses deux nombres DIFFERENT toujours', () {
      // Balayage : tout conseil de duree, avec ou sans repos, sur un programme
      // avec ou sans repos. La phrase de comparaison ne doit jamais opposer un
      // nombre a lui-meme.
      for (var walk = 1; walk <= 10; walk++) {
        for (var rest = 0; rest <= 3; rest++) {
          for (final poses in [
            const <int>{},
            const {1},
            const {1, 3},
          ]) {
            final conseils = evaluer(
              fromProgram: true,
              walkingDays: walk,
              restDays: rest,
              restAfterStageIndex: poses,
            ).advice.where((a) => a.key == 'optimalDays');
            for (final c in conseils) {
              expect(
                c.params['walk'],
                isNot(c.params['current']),
                reason:
                    'walk=$walk rest=$rest repos=$poses : la phrase oppose '
                    '${c.params['walk']} a ${c.params['current']}',
              );
            }
          }
        }
      }
    });
  });

  // ==========================================================================
  // D — LE CABLAGE REEL : D'OU VIENT « LE RANDONNEUR A CHOISI »
  // ==========================================================================

  group('D. le verdict lit le choix REEL, il ne le devine plus', () {
    StageModel etape(int n) => StageModel(
      trailId: trailId,
      stageNumber: n,
      name: 'Etape $n',
      distanceKm: 12,
      elevationGainM: 500,
      elevationLossM: 400,
      startLat: 0,
      startLng: 0,
      endLat: 0,
      endLng: 0,
    );

    final etapes = [for (var n = 1; n <= 6; n++) etape(n)];

    /// Conteneur bati sur le VRAI [PlannedDaysNotifier], amorce comme en
    /// production : une repartition calculee, aucun geste du randonneur. C'est
    /// le seul moyen de prouver le defaut — un double qui pose `state` a la
    /// main court-circuiterait justement ce qu'on teste.
    ProviderContainer conteneur({int? dureeRetenue}) {
      final container = ProviderContainer(
        overrides: [
          trailIdProvider.overrideWithValue(trailId),
          plannedDaysProvider(
            trailId,
          ).overrideWith((ref) => PlannedDaysNotifier(etapes, 6, ref)),
          retainedDurationProvider.overrideWith(
            () => _DureeRetenue(dureeRetenue),
          ),
          hikerLevelProvider.overrideWith((ref) async => HikerLevel.confirmed),
          objectiveProfileProvider.overrideWith(
            (ref) async => const ObjectiveProfile(
              maxElevationGainPerDayDone: 1200,
              maxDistancePerDayDone: 27,
              maxConsecutiveDaysDone: 6,
              maxDailyEnergyKmDone: 0,
              habitualDailyEnergyKm: null,
              fitnessLevelRank: 1,
              hasWalkTest: false,
            ),
          ),
          trekConditionsProvider.overrideWith(
            (ref) async => TrekConditions.unknown,
          ),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    test(
      'LE DEFAUT : programme amorce, aucun geste -> ce n est PAS un choix',
      () async {
        final c = conteneur();
        final programme = await c.read(feasibilityProgramProvider.future);

        expect(
          programme.isEmpty,
          isFalse,
          reason:
              'la liste est bien pleine — c est tout le piege : le provider en '
              'deduisait un choix',
        );
        expect(
          programme.fromProgram,
          isFalse,
          reason:
              'personne n a retenu de duree ni touche au programme : le '
              'decoupage affiche reste celui du sentier',
        );
      },
    );

    test('une duree RETENUE est un choix', () async {
      final c = conteneur(dureeRetenue: 8);
      final programme = await c.read(feasibilityProgramProvider.future);

      expect(
        programme.fromProgram,
        isTrue,
        reason:
            'retenir une duree est une decision, d ou qu elle vienne — curseur '
            'du Programme ou reco de la faisabilite',
      );
    });

    test('une EDITION A LA MAIN du programme est un choix', () async {
      final c = conteneur();
      // Rien de retenu, mais le randonneur pose un jour de repos : le
      // programme affiche est desormais le SIEN.
      c.read(plannedDaysProvider(trailId).notifier).addRestDay(0);

      final programme = await c.read(feasibilityProgramProvider.future);
      expect(
        programme.fromProgram,
        isTrue,
        reason:
            'poser un repos est un geste d edition : le programme evalue n est '
            'plus celui du topo',
      );
    });

    test(
      'et sans choix, le conseil rendu est bien la variante de reference',
      () async {
        final verdict = await conteneur().read(
          feasibilityAssessmentProvider.future,
        );
        final cles = verdict!.advice.map((a) => a.key).toSet();

        expect(
          cles.intersection(comparisonAdviceKeys),
          isEmpty,
          reason:
              'bout en bout, du provider jusqu aux cles i18n : aucune '
              'comparaison ne doit atteindre l ecran',
        );
      },
    );
  });
}

/// Duree retenue FIGEE : `null` = le randonneur n'a rien retenu, c'est l'etat
/// de depart reel de l'application.
class _DureeRetenue extends RetainedDurationNotifier {
  _DureeRetenue(this._jours);

  final int? _jours;

  @override
  int? build() => _jours;
}
