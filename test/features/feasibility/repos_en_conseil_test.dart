import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/config/trail_config.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/core/models/stage.dart';
import 'package:moteur_gr/features/feasibility/domain/feasibility_formula.dart';
import 'package:moteur_gr/features/feasibility/providers/trek_feasibility_provider.dart';
import 'package:moteur_gr/features/planning/domain/planning_calculator.dart';
import 'package:moteur_gr/features/planning/providers/planned_days_provider.dart';
import 'package:moteur_gr/features/planning/providers/planning_provider.dart';
import 'package:moteur_gr/features/trail/providers/stages_provider.dart';

/// LE REPOS EN CONSEIL, ET LE PROGRAMME PAR DEFAUT QUI LE POSE (GO-61, 22/09).
///
/// CE QUE CE FICHIER PROUVE, ET POURQUOI IL EXISTE. GO-61 a change deux choses
/// d'un coup, et elles ne tiennent que si elles sont d'accord entre elles :
///
///   1. le repos ne DECIDE plus (`S_circuit = C1`), il CONSEILLE ;
///   2. le programme par defaut POSE les repos conseilles.
///
/// Si le moteur conseille deux repos apres les etapes 2 et 5 pendant que le
/// planificateur les pose ailleurs, le randonneur lit un conseil qu'il croit
/// appliquer et voit un chiffre qui ne bouge pas. Les deux conventions sont
/// donc verrouillees l'une sur l'autre ici — c'est la garde principale de ce
/// fichier, et elle sait dire non : changer le placement d'un seul cote la
/// fait rougir.
void main() {
  /// Seed de PRODUCTION Mare a Mare Centre (7 etapes), celui sur lequel
  /// l'arbitrage a ete rendu.
  const seedProduction = <(double, int)>[
    (15.0, 850),
    (12.0, 600),
    (10.0, 400),
    (11.0, 550),
    (14.0, 650),
    (12.0, 500),
    (10.0, 200),
  ];

  List<StageEffort> effortsDe(List<(double, int)> seed) => [
        for (var i = 0; i < seed.length; i++)
          StageEffort(
            index: i,
            name: 'E${i + 1}',
            distanceKm: seed[i].$1,
            elevationGainM: seed[i].$2,
          ),
      ];

  List<double> energiesDe(List<(double, int)> seed) => [
        for (final s in seed)
          FeasibilityScale.v2.energyOf(distanceKm: s.$1, elevationGainM: s.$2),
      ];

  StageModel stageModel(int n, double km, int gain) => StageModel(
        trailId: 'test-trail',
        stageNumber: n,
        name: 'Etape $n',
        distanceKm: km,
        elevationGainM: gain,
        elevationLossM: gain,
        startLat: 42.0,
        startLng: 9.0,
        endLat: 42.1,
        endLng: 9.1,
      );

  group('LE MIROIR PLANIFICATEUR / MOTEUR — la garde principale', () {
    test(
        'pour tout sentier et tout nombre de repos, les deux conventions '
        'designent LE MEME JOUR', () {
      // Le planificateur raisonne en « repos AVANT l etape i », le moteur en
      // « repos APRES l etape i-1 ». Une inversion d un cran passerait
      // inapercue a l oeil et donnerait un conseil inapplicable.
      final ecarts = <String>[];
      for (var n = 2; n <= 12; n++) {
        final stages = [
          for (var i = 1; i <= n; i++) stageModel(i, 10 + i.toDouble(), 300 + i),
        ];
        for (var r = 0; r < n; r++) {
          final duMoteur = FeasibilityFormula.restAfterStageIndexFor(
            stageCount: n,
            restDays: r,
          );
          // Ce que le PLANIFICATEUR produit reellement, relu comme le fait le
          // provider : on compte les etapes marchees avant chaque repos.
          final jours = PlanningCalculator.distribute(stages, n + r);
          final duPlan = <int>{};
          var marchees = 0;
          for (final j in jours) {
            if (j.isRestDay || j.stages.isEmpty) {
              if (marchees > 0 && marchees < n) duPlan.add(marchees - 1);
              continue;
            }
            marchees += j.stages.length;
          }
          if (!_memeEnsemble(duMoteur, duPlan)) {
            ecarts.add('n=$n r=$r : moteur $duMoteur, planificateur $duPlan');
          }
        }
      }
      expect(ecarts, isEmpty, reason: ecarts.take(10).join('\n'));
    });

    test('un repos avant la premiere etape ne repose de rien', () {
      // Le moteur l ignore ; le miroir doit l ignorer aussi, sinon il
      // compterait un jour de charge nulle que la monotonie ne voit pas.
      expect(
        FeasibilityFormula.restAfterStageIndexFor(stageCount: 1, restDays: 1),
        isEmpty,
      );
      expect(
        FeasibilityFormula.restAfterStageIndexFor(stageCount: 5, restDays: 0),
        isEmpty,
      );
    });
  });

  group('LE CONSEIL DE REPOS — minimal, source, et jamais invente', () {
    test('sentier de production : 2 repos, apres les etapes 2 et 5', () {
      final conseil =
          FeasibilityFormula.recommendedRestAfterStageIndex(
              energiesDe(seedProduction));
      expect(conseil, {1, 4});
    });

    test('le conseil est le PLUS PETIT qui ramene la monotonie sous le seuil',
        () {
      // Propriete, pas anecdote : on verifie que le nombre conseille SUFFIT et
      // que le nombre juste en dessous NE SUFFIT PAS. Un conseil qui ne serait
      // pas minimal ferait poser des repos inutiles ; un conseil insuffisant
      // laisserait le chiffre au-dessus de son seuil apres application.
      final energies = energiesDe(seedProduction);
      final conseil =
          FeasibilityFormula.recommendedRestAfterStageIndex(energies);
      expect(conseil, isNotEmpty);

      double? monotonieAvec(int repos) => FeasibilityFormula.worstMonotonyWindow(
            FeasibilityFormula.dailyLoads(
              stageEnergies: energies,
              restAfterStageIndex: FeasibilityFormula.restAfterStageIndexFor(
                stageCount: energies.length,
                restDays: repos,
              ),
            ),
          ).monotony;

      expect(monotonieAvec(conseil.length),
          lessThanOrEqualTo(FeasibilityFormula.monotonyThreshold));
      expect(monotonieAvec(conseil.length - 1),
          greaterThan(FeasibilityFormula.monotonyThreshold));
    });

    test('appliquer le conseil fait passer le chiffre du repos sous 1', () {
      final efforts = effortsDe(seedProduction);
      final sans = FeasibilityFormula.evaluate(
        stages: efforts,
        level: HikerLevel.intermediate,
      );
      expect(sans.circuit!.rest, greaterThan(1.0));
      expect(sans.isRestAdvised, isTrue);

      final avec = FeasibilityFormula.evaluate(
        stages: efforts,
        level: HikerLevel.intermediate,
        restAfterStageIndex: sans.recommendedRestAfterStageIndex,
      );
      expect(avec.circuit!.rest, lessThan(1.0));
      expect(avec.isRestAdvised, isFalse);
      // Et le verdict n a pas bouge : le repos conseille, il ne decide pas.
      expect(avec.globalVerdict, sans.globalVerdict);
    });

    test('aucun conseil quand le chiffre n existe pas (sentier d UNE etape)',
        () {
      final a = FeasibilityFormula.evaluate(
        stages: effortsDe(const [(15.0, 850)]),
        level: HikerLevel.beginner,
      );
      expect(a.circuit!.isRestApplicable, isFalse);
      expect(a.recommendedRestDays, 0);
      expect(a.isRestAdvised, isFalse);
      expect(a.advice.map((c) => c.key), isNot(contains('restAdvised')));
    });

    test('aucun conseil quand la monotonie est deja sous son seuil', () {
      // Des charges tres inegales creusent l ecart-type : le rythme est sain,
      // on ne conseille rien. On ne pose pas des repos « au cas ou ».
      final energies = energiesDe(const [
        (30.0, 1000),
        (5.0, 100),
        (30.0, 1000),
        (5.0, 100),
      ]);
      expect(FeasibilityFormula.recommendedRestAfterStageIndex(energies),
          isEmpty);
    });

    test('les chiffres de la spec #2-t sont ceux du conseil', () {
      // « Sur des etapes de meme taille, un jour de repos par semaine ne suffit
      // pas, il en faut deux » (#2-t). Le conseil doit dire exactement cela sur
      // une semaine d etapes quasi identiques — sinon il aurait invente son
      // propre seuil au lieu de servir celui de la spec.
      final conseil = FeasibilityFormula.recommendedRestAfterStageIndex(
          const [30.0, 30.1, 29.9, 30.05, 29.95, 30.02]);
      expect(conseil.length, 2);
    });

    test(
        'charges STRICTEMENT egales : rien n est calculable, donc rien n est '
        'conseille — et c est le comportement voulu', () {
      // TROU CONNU ET DECLARE (#10-e). Avec des charges toutes identiques et
      // aucun repos, l ecart-type vaut zero : la monotonie DIVERGE, elle n est
      // pas calculable. Le moteur declare la contrainte non applicable plutot
      // que de la remplacer par un chiffre, et le conseil suit la meme regle.
      // C est un cas de laboratoire — deux etapes reelles n ont jamais
      // exactement la meme energie — mais il doit etre DIT, pas decouvert.
      expect(
        FeasibilityFormula.monotonyOf(List<double>.filled(6, 30)),
        isNull,
      );
      expect(
        FeasibilityFormula.recommendedRestAfterStageIndex(
            List<double>.filled(6, 30)),
        isEmpty,
      );
    });
  });

  group('LE PROGRAMME PAR DEFAUT POSE LES REPOS CONSEILLES', () {
    /// Sentier de production simule : 7 etapes, duree par defaut 7 jours.
    const config = TrailConfig(
      id: 'test-trail',
      name: 'Mare a Mare Centre (test)',
      displayName: 'Mare a Mare',
      tagline: 'test',
      totalStages: 7,
      totalDistanceKm: 84,
      totalElevationGain: 3750,
      region: 'Corse',
      country: 'France',
      primaryColorValue: 0xFF8B4513,
      secondaryColorValue: 0xFFD2691E,
      gpxAssetPath: 'assets/gpx/test_trail.gpx',
      directions: ['NS', 'SN'],
      availableDurations: [7],
      defaultDuration: 7,
    );

    final stages = [
      for (var i = 0; i < seedProduction.length; i++)
        stageModel(i + 1, seedProduction[i].$1, seedProduction[i].$2),
    ];

    ProviderContainer conteneur() {
      final container = ProviderContainer(
        overrides: [
          trailConfigProvider.overrideWithValue(config),
          stagesProvider('test-trail')
              .overrideWith((ref) => Future.value(stages)),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    test(
        'bout en bout : le programme par defaut porte les repos conseilles, '
        'aux memes places que le moteur', () async {
      final c = conteneur();
      // Les etapes arrivent d abord (avant, on ne conseille rien : on ne
      // devine pas un repos sur un sentier qu on n a pas lu).
      await c.read(stagesProvider('test-trail').future);

      expect(c.read(recommendedRestDaysProvider('test-trail')), 2);
      expect(c.read(defaultDurationWithRestProvider('test-trail')), 9);
      expect(c.read(selectedDurationProvider), 9);

      final jours = c.read(plannedDaysProvider('test-trail'));
      expect(jours.length, 9);
      expect(jours.where((j) => j.isRestDay).length, 2);

      // LA JONCTION : ce que le programme pose, relu par le provider qui
      // alimente le moteur, est EXACTEMENT ce que le moteur conseille.
      expect(c.read(restDaysAfterStageProvider), {1, 4});
      expect(
        c.read(restDaysAfterStageProvider),
        FeasibilityFormula.recommendedRestAfterStageIndex(
            energiesDe(seedProduction)),
      );
    });

    test('le randonneur reprend la main : un decoupage retenu prime', () async {
      final c = conteneur();
      await c.read(stagesProvider('test-trail').future);
      expect(c.read(selectedDurationProvider), 9);

      // C est une valeur PAR DEFAUT, pas une contrainte : choisir 7 jours
      // retire les repos, et rien ne les remet.
      c.read(selectedDurationProvider.notifier).set(7);
      expect(c.read(selectedDurationProvider), 7);
      final jours = c.read(plannedDaysProvider('test-trail'));
      expect(jours.length, 7);
      expect(jours.where((j) => j.isRestDay), isEmpty);
      expect(c.read(restDaysAfterStageProvider), isEmpty);
    });
  });
}

bool _memeEnsemble(Set<int> a, Set<int> b) =>
    a.length == b.length && a.every(b.contains);
