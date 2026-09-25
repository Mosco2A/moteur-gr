import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moteur_gr/core/config/test_trail_config.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/core/models/stage.dart';
import 'package:moteur_gr/core/theme/app_theme.dart';
import 'package:moteur_gr/features/feasibility/domain/feasibility_formula.dart';
import 'package:moteur_gr/features/feasibility/domain/objective_profile.dart';
import 'package:moteur_gr/features/feasibility/presentation/trek_feasibility_screen.dart';
import 'package:moteur_gr/features/feasibility/providers/trek_feasibility_provider.dart';
import 'package:moteur_gr/features/planning/models/planned_day.dart';
import 'package:moteur_gr/features/planning/presentation/trail_planning_screen.dart';
import 'package:moteur_gr/features/planning/providers/planned_days_provider.dart';
import 'package:moteur_gr/features/planning/widgets/duration_selector.dart';
import 'package:moteur_gr/features/trail/providers/stages_provider.dart'
    as trail_stages;
import 'package:moteur_gr/i18n/translations.g.dart';

/// LA FAISABILITE LIT-ELLE LE PROGRAMME REEL ? (tache 551, spec Chris #100417)
///
/// LE DEFAUT QUE CE FICHIER INTERDIT DE REFAIRE. Mot pour mot, le 25/09 :
/// « la faisabilite ne tien pas compte du nombre de jour choisi et des repos ».
/// Verifie ligne par ligne avant correction : `feasibilityAssessmentProvider`
/// lisait `stageEffortsProvider`, donc `stagesProvider`, LES ETAPES BRUTES DU
/// SENTIER. Le nombre de jours choisi et les regroupements d'etapes n'etaient
/// JAMAIS lus — mais les jours de repos, EUX, l'etaient : un demi-cablage, qui
/// donnait l'illusion que l'ecran suivait les choix du randonneur.
///
/// CE QUE CES TESTS VERROUILLENT :
///   1. une journee qui REGROUPE deux etapes pese la SOMME des deux ;
///   2. le nombre de jours de MARCHE evalue est celui du programme ;
///   3. les jours de repos sont reperes en JOURS, pas en etapes ;
///   4. le verdict REAGIT quand le nombre de jours varie, dans les deux sens ;
///   5. le repli sur les etapes brutes existe, et il est DECLARE ;
///   6. le conseil de jours ne depasse jamais le nombre d'etapes disponibles ;
///   7. l'ecran met le CONSEIL avant le VERDICT, et le jargon « X jour(s)
///      au-dessus de ton plafond » a disparu.
void main() {
  const trailId = 'test-trail';

  setUpAll(() => LocaleSettings.setLocaleRaw('fr'));

  /// Etape de reference : 12 km + 500 m D+ = 23,90 km-energie (bareme V2).
  ///
  /// Pour un randonneur CONFIRME (plafond 55,57), cela donne des scores nets et
  /// verifiables a la main : 1 etape/jour = 0,43 (VERT), 2 etapes/jour = 0,86
  /// (ORANGE, le vert s'arrete a 0,85), 3 etapes/jour = 1,29 (ROUGE).
  StageModel stage(int n) => StageModel(
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

  final etapes = [for (var n = 1; n <= 6; n++) stage(n)];

  /// Journee de marche portant les etapes [numeros] (1-based).
  PlannedDay marche(int dayNumber, List<int> numeros) => PlannedDay(
        dayNumber: dayNumber,
        stages: [for (final n in numeros) etapes[n - 1]],
      );

  /// Journee de repos.
  PlannedDay repos(int dayNumber) =>
      PlannedDay(dayNumber: dayNumber, stages: const [], isRestDay: true);

  /// Programme reparti : [etapesParJour] etapes par journee, sans repos.
  List<PlannedDay> programmeGroupe(int etapesParJour) {
    final days = <PlannedDay>[];
    var i = 0;
    while (i < etapes.length) {
      final lot = <int>[];
      for (var k = 0; k < etapesParJour && i < etapes.length; k++, i++) {
        lot.add(i + 1);
      }
      days.add(marche(days.length + 1, lot));
    }
    return days;
  }

  ProviderContainer conteneur(List<PlannedDay> days) {
    final container = ProviderContainer(
      overrides: [
        trailIdProvider.overrideWithValue(trailId),
        plannedDaysProvider(trailId)
            .overrideWith((ref) => _ProgrammeFige(ref, days)),
        // Niveau FIGE : ces tests portent sur le DECOUPAGE evalue, pas sur la
        // derivation du niveau (couverte ailleurs). Un niveau fige rend les
        // scores calculables a la main.
        hikerLevelProvider.overrideWith((ref) async => HikerLevel.confirmed),
        objectiveProfileProvider.overrideWith(
          (ref) async => const ObjectiveProfile(
            maxElevationGainPerDayDone: 1200,
            maxDistancePerDayDone: 27,
            maxConsecutiveDaysDone: 6,
            // 0 : aucun plancher demontre ne vient relever la capacite, donc le
            // plafond du niveau est bien le denominateur des scores attendus.
            maxDailyEnergyKmDone: 0,
            habitualDailyEnergyKm: null,
            fitnessLevelRank: 1,
            hasWalkTest: false,
          ),
        ),
        trekConditionsProvider.overrideWith((ref) async => TrekConditions.unknown),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  Future<FeasibilityProgram> decoupage(List<PlannedDay> days) =>
      conteneur(days).read(feasibilityProgramProvider.future);

  Future<FeasibilityAssessment?> verdict(List<PlannedDay> days) =>
      conteneur(days).read(feasibilityAssessmentProvider.future);

  group('1-3. le decoupage evalue EST le programme', () {
    test('une journee qui regroupe deux etapes pese la somme des deux',
        () async {
      final p = await decoupage([
        marche(1, [1, 2]),
        marche(2, [3]),
      ]);
      expect(p.fromProgram, isTrue, reason: 'la source doit etre le programme');
      expect(p.walkingDays, 2, reason: 'deux journees de marche, pas 3 etapes');
      expect(p.dayEfforts.first.distanceKm, 24, reason: '12 + 12');
      expect(p.dayEfforts.first.elevationGainM, 1000, reason: '500 + 500');
      expect(p.dayEfforts.first.elevationLossM, 800, reason: '400 + 400');
      expect(p.dayEfforts.first.name, 'Etape 1 + Etape 2',
          reason: 'la journee nomme ce qui se marche ce jour-la');
      expect(p.stageCount, 3, reason: 'trois etapes portees par ce decoupage');
    });

    test('le verdict est rendu sur les JOURNEES, pas sur les etapes brutes',
        () async {
      // Six etapes en trois journees de deux : le moteur doit rendre TROIS
      // verdicts de journee, chacun a 0,86 (orange), et non six a 0,43 (vert).
      final a = await verdict(programmeGroupe(2));
      expect(a!.stageVerdicts.length, 3);
      expect(a.walkingDays, 3);
      expect(a.stageVerdicts.first.score, closeTo(0.86033, 0.0005));
      expect(a.globalVerdict, FeasibilityVerdict.orange);
    });

    test('un repos apres une journee REGROUPEE est repere en JOURS', () async {
      final days = [
        marche(1, [1, 2]),
        repos(2),
        marche(3, [3]),
      ];
      // En jours : le repos suit la PREMIERE journee -> index 0.
      final p = await decoupage(days);
      expect(p.restAfterDayIndex, {0});
      // Le provider historique, lui, compte en ETAPES CONSOMMEES -> index 1.
      // Les deux coexistent : l'un sert le verdict (jours), l'autre le repli.
      expect(conteneur(days).read(restDaysAfterStageProvider), {1});
    });

    test('les repos du programme arrivent au moteur (charge nulle)', () async {
      final sans = await verdict(programmeGroupe(1));
      final avec = await verdict([
        marche(1, [1]),
        marche(2, [2]),
        repos(3),
        marche(4, [3]),
        marche(5, [4]),
        repos(6),
        marche(7, [5]),
        marche(8, [6]),
      ]);
      expect(sans!.restDaysPlanned, 0);
      expect(avec!.restDaysPlanned, 2);
      // Le chiffre du repos (C3) redescend : c'est ce que les repos changent.
      expect(avec.circuit!.rest, lessThan(sans.circuit!.rest!));
    });
  });

  group('4. le verdict REAGIT au nombre de jours (retour Chris 6b)', () {
    test('moins de jours -> le verdict se DETERIORE', () async {
      final six = await verdict(programmeGroupe(1));
      final trois = await verdict(programmeGroupe(2));
      final deux = await verdict(programmeGroupe(3));
      expect(six!.globalVerdict, FeasibilityVerdict.green);
      expect(trois!.globalVerdict, FeasibilityVerdict.orange);
      expect(deux!.globalVerdict, FeasibilityVerdict.red);
      // Monotone : regrouper ne peut qu'alourdir la journee.
      expect(trois.circuit!.score, greaterThan(six.circuit!.score));
      expect(deux.circuit!.score, greaterThan(trois.circuit!.score));
    });

    test('plus de jours -> le verdict S AMELIORE, et le rouge s en va',
        () async {
      final deux = await verdict(programmeGroupe(3));
      final six = await verdict(programmeGroupe(1));
      expect(deux!.globalVerdict, FeasibilityVerdict.red);
      // Retour Chris 6d : au bon decoupage, l'ecran cesse de dire « au-dessus
      // de tes capacites » — le verdict porte sur le decoupage, pas sur la
      // personne, et la personne n'a pas change entre ces deux lectures.
      expect(six!.globalVerdict, isNot(FeasibilityVerdict.red));
      expect(six.globalVerdict, FeasibilityVerdict.green);
      expect(six.circuit!.score, lessThan(deux.circuit!.score));
    });
  });

  group('5. repli sur les etapes brutes, et il est DECLARE', () {
    test('aucun programme -> les etapes brutes, fromProgram = false', () async {
      final container = ProviderContainer(
        overrides: [
          trailIdProvider.overrideWithValue(trailId),
          // Programme VIDE : etapes pas encore chargees, ecran jamais ouvert.
          plannedDaysProvider(trailId)
              .overrideWith((ref) => _ProgrammeFige(ref, const [])),
          stageEffortsProvider.overrideWith((ref) async => const [
                StageEffort(
                    index: 0,
                    name: 'Brute 1',
                    distanceKm: 12,
                    elevationGainM: 500),
                StageEffort(
                    index: 1,
                    name: 'Brute 2',
                    distanceKm: 12,
                    elevationGainM: 500),
              ]),
        ],
      );
      addTearDown(container.dispose);
      final p = await container.read(feasibilityProgramProvider.future);
      expect(p.fromProgram, isFalse, reason: 'le repli doit se declarer');
      expect(p.walkingDays, 2);
      expect(p.dayEfforts.first.name, 'Brute 1');
    });

    test('ni programme ni etape -> aucun verdict (jamais sur du vide)',
        () async {
      final container = ProviderContainer(
        overrides: [
          trailIdProvider.overrideWithValue(trailId),
          plannedDaysProvider(trailId)
              .overrideWith((ref) => _ProgrammeFige(ref, const [])),
          stageEffortsProvider.overrideWith((ref) async => const <StageEffort>[]),
        ],
      );
      addTearDown(container.dispose);
      expect(await container.read(feasibilityProgramProvider.future),
          isA<FeasibilityProgram>().having((p) => p.isEmpty, 'isEmpty', isTrue));
      expect(
          await container.read(feasibilityAssessmentProvider.future), isNull);
    });
  });

  group('6. le conseil reste APPLICABLE', () {
    test('jamais plus de jours de marche conseilles que d etapes', () async {
      // Une seule journee qui porte les six etapes : 143,4 km-energie pour un
      // plafond de 55,57 -> le calcul brut reclamerait beaucoup de jours, mais
      // six etapes ne font pas plus de six journees (une etape ne se coupe pas).
      final a = await verdict(programmeGroupe(6));
      expect(a!.walkingDays, 1);
      expect(a.suggestedDays, lessThanOrEqualTo(6));
      expect(a.suggestedDays, greaterThan(1),
          reason: 'etaler reste conseille quand la journee est trop lourde');
      // Et le conseil chiffre est bien emis, avec les deux nombres.
      final conseil =
          a.advice.firstWhere((c) => c.key == 'optimalDays', orElse: () => const ProgramAdvice(key: 'absent'));
      expect(conseil.key, 'optimalDays');
      expect(conseil.params['current'], 1);
    });

    test('sans plafond connu, le calcul d origine est inchange', () {
      // Garde de non-regression : maxWalkingDays = 0 (inconnu) ne borne rien.
      final a = FeasibilityFormula.evaluate(
        stages: const [
          StageEffort(
              index: 0, name: 'A', distanceKm: 40, elevationGainM: 2500),
        ],
        level: HikerLevel.beginner,
      );
      expect(a.suggestedDays, greaterThan(1));
    });
  });

  group('7. l ecran : le conseil AVANT le verdict, sans jargon', () {
    /// Evaluation ROUGE avec conseils (etape trop dure pour un intermediaire).
    FeasibilityAssessment rouge() => FeasibilityFormula.evaluate(
          stages: const [
            StageEffort(
                index: 0, name: 'Depart -> Col', distanceKm: 24, elevationGainM: 1600),
            StageEffort(
                index: 1, name: 'Col -> Refuge', distanceKm: 22, elevationGainM: 800),
            StageEffort(
                index: 2, name: 'Refuge -> Village', distanceKm: 10, elevationGainM: 200),
          ],
          level: HikerLevel.intermediate,
        );

    Future<void> pumpEcran(WidgetTester tester) async {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (_, __) => const TrekFeasibilityScreen()),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            feasibilityAssessmentProvider.overrideWith((ref) async => rouge()),
            feasibilityCriteriaProvider.overrideWith((ref) async =>
                const FeasibilityCriteria(
                    profileComplete: true,
                    hasPastHike: true,
                    hasWalkTest: true)),
            hasObjectiveProfileProvider.overrideWith((ref) async => true),
          ],
          child: MaterialApp.router(
            locale: const Locale('fr'),
            routerConfig: router,
          ),
        ),
      );
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 20));
      }
    }

    testWidgets('le bloc de conseils est AU-DESSUS du feu tricolore',
        (tester) async {
      await pumpEcran(tester);
      final conseils =
          find.byKey(const ValueKey('feasibility-advice-first'));
      expect(conseils, findsOneWidget);
      // « Plafond conseille » est la ligne collee sous le feu tricolore : si le
      // bloc de conseils est plus haut qu'elle, il est plus haut que le verdict.
      final yConseils = tester.getTopLeft(conseils).dy;
      final yFeu =
          tester.getTopLeft(find.textContaining('Plafond conseillé')).dy;
      expect(yConseils, lessThan(yFeu),
          reason: 'retour Chris 4 : conseiller AVANT de juger');
      // Le titre des conseils et le nombre de jours proposes sont bien la.
      expect(find.text(t.feasibility.formula.adviceTitle), findsOneWidget);
      expect(find.textContaining('Générer mon programme'), findsOneWidget);
    });

    testWidgets('le jargon « X jour(s) au-dessus de ton plafond » a disparu',
        (tester) async {
      await pumpEcran(tester);
      expect(find.textContaining('au-dessus de ton plafond'), findsNothing);
      expect(find.text(t.feasibility.formula.daysOverNone), findsNothing);
      // Ce qui reste : le facteur limitant, qui NOMME ce qui pese.
      expect(find.textContaining('Facteur limitant'), findsOneWidget);
    });
  });

  // ------------------------------------------------------------------------
  // 8. LE CURSEUR JOURS DU PROGRAMME PREND LA COULEUR DU VERDICT (retour 6c).
  //
  // Mot pour mot : « le curseur jour change de couleur dans programme ». Le
  // curseur se colorait au ratio etapes/jour, qui ignore le randonneur : deux
  // profils opposes voyaient la meme couleur sur le meme decoupage.
  // ------------------------------------------------------------------------
  group('8. le curseur du Programme suit le verdict', () {
    Future<DurationSelector> pumpProgramme(
      WidgetTester tester,
      FeasibilityAssessment? assessment,
    ) async {
      tester.view.physicalSize = const Size(500, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            trailConfigProvider.overrideWithValue(testTrailConfig),
            trail_stages.stagesProvider(trailId)
                .overrideWith((ref) => Future.value(etapes)),
            feasibilityAssessmentProvider.overrideWith((ref) async => assessment),
          ],
          child: MaterialApp.router(
            locale: const Locale('fr'),
            routerConfig: GoRouter(
              initialLocation: '/planning',
              routes: [
                GoRoute(
                  path: '/planning',
                  builder: (_, __) =>
                      const TrailPlanningScreen(trailId: trailId),
                ),
                GoRoute(path: '/my-treks', builder: (_, __) => const SizedBox()),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return tester.widget<DurationSelector>(find.byType(DurationSelector));
    }

    testWidgets('verdict ROUGE -> curseur rouge et pastille qui le nomme',
        (tester) async {
      final selector = await pumpProgramme(
        tester,
        FeasibilityFormula.evaluate(
          stages: const [
            StageEffort(
                index: 0, name: 'Dure', distanceKm: 30, elevationGainM: 2000),
          ],
          level: HikerLevel.beginner,
        ),
      );
      expect(selector.verdict, FeasibilityVerdict.red);
      expect(durationVerdictColor(selector.verdict!), AppTheme.rougeUrgence);
      expect(find.text(t.feasibility.formula.verdicts.red), findsOneWidget);
    });

    testWidgets('verdict VERT -> curseur vert (le randonneur voit le vert)',
        (tester) async {
      final selector = await pumpProgramme(
        tester,
        FeasibilityFormula.evaluate(
          stages: const [
            StageEffort(
                index: 0, name: 'Facile', distanceKm: 8, elevationGainM: 200),
            StageEffort(
                index: 1, name: 'Facile 2', distanceKm: 9, elevationGainM: 250),
          ],
          level: HikerLevel.confirmed,
        ),
      );
      expect(selector.verdict, FeasibilityVerdict.green);
      expect(durationVerdictColor(selector.verdict!), AppTheme.vertFacile);
      expect(find.text(t.feasibility.formula.verdicts.green), findsOneWidget);
    });

    testWidgets('aucun verdict calculable -> retour au ratio, rien d invente',
        (tester) async {
      final selector = await pumpProgramme(tester, null);
      expect(selector.verdict, isNull);
      // La pastille reprend le libelle de difficulte (ratio etapes/jour).
      expect(
        find.text(durationDifficultyLabel(
            durationDifficultyFor(selector.stageCount, selector.walkingDays))),
        findsOneWidget,
      );
    });
  });
}

/// Programme fige (evite tout le pipeline etapes / repartition).
class _ProgrammeFige extends PlannedDaysNotifier {
  _ProgrammeFige(Ref ref, List<PlannedDay> days) : super(const [], 1, ref) {
    state = days;
  }
}
