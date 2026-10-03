import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moteur_gr/core/config/test_trail_config.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/core/models/stage_row.dart';
import 'package:moteur_gr/domain/feasibility_formula.dart';
import 'package:moteur_gr/features/feasibility/presentation/trek_feasibility_screen.dart';
import 'package:moteur_gr/features/feasibility/providers/trek_feasibility_provider.dart';
import 'package:moteur_gr/features/planning/providers/planning_provider.dart';
import 'package:moteur_gr/features/trail/providers/stages_provider.dart';
import 'package:moteur_gr/i18n/translations.g.dart';
import 'package:moteur_gr/core/branding/stepways_icons.dart';
import '../../outillage/volet_du_calcul.dart';

/// Test WIDGET de l'ecran de faisabilite FEU TRICOLORE (LOT 3a, #100068).
///
/// Verifie que le verdict global, les pastilles par etape (vert/orange/rouge),
/// le facteur limitant et les conseils de programme s'affichent avec les
/// libelles Slang FR (accents). L'evaluation est injectee via override du
/// provider (calcul deja teste a l'unite dans feasibility_formula_test.dart).
void main() {
  setUpAll(() => LocaleSettings.setLocaleRaw('fr'));

  StageEffort stage(int i, String name, double dist, int elev) =>
      StageEffort(index: i, name: name, distanceKm: dist, elevationGainM: elev);

  /// Evaluation MIXTE : rouge global, avec au moins une etape orange et une
  /// verte, un facteur limitant et des conseils.
  FeasibilityAssessment mixedAssessment() {
    return FeasibilityFormula.evaluate(
      stages: [
        stage(0, 'Depart -> Col', 24, 1600), // rouge
        stage(1, 'Col -> Refuge', 22, 800), // orange
        stage(2, 'Refuge -> Village', 10, 200), // vert
      ],
      level: HikerLevel.intermediate,
    );
  }

  /// Monte l'ecran avec l'evaluation injectee + un routeur minimal (l'ecran
  /// utilise `context.push` et `trailConfigProvider`).
  Future<void> pumpScreen(
    WidgetTester tester,
    FeasibilityAssessment? assessment,
  ) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (_, __) => const TrekFeasibilityScreen()),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          feasibilityAssessmentProvider.overrideWith((ref) async => assessment),
          // Correctif N2 / D1 : le verdict n'apparait qu'avec les criteres au
          // complet. Ces tests portent sur le CONTENU du verdict, pas sur sa
          // regle de declenchement (couverte par
          // faisabilite_correction_n2_test.dart) : on part donc au complet.
          feasibilityCriteriaProvider.overrideWith(
            (ref) async => const FeasibilityCriteria(
              profileComplete: true,
              hasPastHike: true,
              hasWalkTest: true,
            ),
          ),
          hasObjectiveProfileProvider.overrideWith((ref) async => true),
        ],
        child: MaterialApp.router(
          locale: const Locale('fr'),
          routerConfig: router,
        ),
      ),
    );
    // Resout les FutureProviders (bornes, l'ecran a un spinner de chargement).
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }
  }

  testWidgets('affiche le verdict global tricolore + le plafond', (
    tester,
  ) async {
    await pumpScreen(tester, mixedAssessment());
    // Verdict global rouge (etape la plus dure) : il ouvre l'ecran.
    expect(find.text(t.feasibility.formula.verdicts.red), findsWidgets);
    // Titre de l'ecran.
    expect(find.text(t.feasibility.formula.title), findsOneWidget);
    // TACHE 634 (DEM-260929-1134) : le plafond en km-energie est une
    // EXPLICATION du verdict, pas le verdict. Il reste disponible, sous le
    // volet du calcul, et n'est plus impose en tete d'ecran.
    expect(find.textContaining('Plafond conseillé'), findsNothing);
    await ouvrirLeVoletEtAtteindre(
      tester,
      find.textContaining('Plafond conseillé'),
    );
    expect(find.textContaining('Plafond conseillé'), findsOneWidget);
  });

  testWidgets('affiche les trois couleurs par etape', (tester) async {
    await pumpScreen(tester, mixedAssessment());
    // Chaque etape porte son libelle de verdict.
    expect(find.text(t.feasibility.formula.verdicts.red), findsWidgets);
    expect(find.text(t.feasibility.formula.verdicts.orange), findsWidgets);
    expect(find.text(t.feasibility.formula.verdicts.green), findsWidgets);
    // Les noms d'etapes sont rendus.
    expect(find.text('Depart -> Col'), findsWidgets);
    expect(find.text('Refuge -> Village'), findsOneWidget);
  });

  testWidgets('nomme le facteur limitant et la reco entrainement', (
    tester,
  ) async {
    await pumpScreen(tester, mixedAssessment());
    // Disponibles sous le volet du calcul depuis la tache 634 (DEM-1134).
    await ouvrirLeVoletEtAtteindre(
      tester,
      find.textContaining('Facteur limitant'),
    );
    expect(find.textContaining('Facteur limitant'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.textContaining('Entraînement conseillé'),
      200,
    );
    expect(find.textContaining('Entraînement conseillé'), findsOneWidget);
  });

  testWidgets('affiche les conseils de programme (alerte journee dure)', (
    tester,
  ) async {
    await pumpScreen(tester, mixedAssessment());
    expect(find.text(t.feasibility.formula.adviceTitle), findsOneWidget);
    // TACHE 569 (R4) : la journee 1 est rouge -> ALERTE, plus jamais un conseil
    // de decoupe. Chris, 26/09 : « decoupe la journee 1 en 2 === comment on
    // fait???? pas une solution ». Une etape s'arrete la ou il y a un toit.
    expect(find.textContaining('Découpe la journée'), findsNothing);
    expect(
      find.text(t.feasibility.formula.advice.hardStageAlert(stage: 1)),
      findsOneWidget,
    );
  });

  // TACHE 569 (R3) — LE CALCUL EST MONTRE LA OU LE VERDICT TOMBE.
  testWidgets('le verdict montre son calcul, avec les chiffres reels', (
    tester,
  ) async {
    await pumpScreen(tester, mixedAssessment());
    // Disponible sous le volet du calcul depuis la tache 634 (DEM-1134) : c'est
    // precisement « comment c'est calcule », donc sa place est la.
    await ouvrirLeVoletEtAtteindre(
      tester,
      find.byKey(const ValueKey('feasibility-verdict-how')),
    );
    expect(
      find.byKey(const ValueKey('feasibility-verdict-how')),
      findsOneWidget,
      reason:
          'Chris : « tu mexplique comment c est calcule au moment ou ca '
          'le fait? »',
    );
    expect(find.text(t.feasibility.formula.verdictHowTitle), findsOneWidget);
    // La journee la plus dure est nommee, avec sa geometrie reelle.
    expect(find.textContaining('Depart -> Col'), findsWidgets);
    expect(find.textContaining('1600'), findsWidgets);
    // L'unite d'energie et les deux seuils de l'echelle sont dits ICI.
    //
    // SEPARATEUR DECIMAL : l'application ecrit les nombres avec un POINT
    // (`toStringAsFixed`, convention de tout l'ecran depuis #100068) ; Chris les
    // cite avec une virgule dans ses retours. Ce test suit ce que l'ecran
    // affiche reellement — uniformiser la virgule est un chantier d'affichage a
    // part, qui touche tous les chiffres de l'app et pas seulement ce bloc.
    expect(find.textContaining('42'), findsWidgets);
    expect(
      find.textContaining('0.85'),
      findsWidgets,
      reason:
          'Chris : « score 1,30 sans echelle ca ne veut rien dire » — le '
          'seuil vert doit etre a l ecran',
    );
    expect(find.textContaining('1.10'), findsWidgets);
    // Les trois travaux qui nourrissent la division sont nommes.
    expect(
      find.text(t.feasibility.formula.verdictHowNoBlackBox),
      findsOneWidget,
    );
  });

  testWidgets('assessment vert -> conseil equilibre, pas de facteur limitant', (
    tester,
  ) async {
    final green = FeasibilityFormula.evaluate(
      stages: [stage(0, 'Facile', 10, 200)],
      level: HikerLevel.confirmed,
    );
    await pumpScreen(tester, green);
    expect(find.text(t.feasibility.formula.verdicts.green), findsWidgets);
    // Pas de facteur limitant affiche quand tout est vert.
    expect(find.textContaining('Facteur limitant'), findsNothing);
    // Conseil « equilibre ».
    expect(find.text(t.feasibility.formula.advice.balancedOk), findsOneWidget);
  });

  testWidgets('sans etapes -> fallback questionnaire', (tester) async {
    await pumpScreen(tester, null);
    // La vue de dépannage montre le raccourci « profil ».
    expect(find.text(t.feasibility.openProfile), findsOneWidget);
  });

  // R2f (#100122 / parite GR20 « CONTINUER ») : l'appli PROPOSE le planning. Le
  // bouton « Generer mon programme » APPLIQUE la reco de la formule (nb de jours
  // optimal) a la source unique des jours (selectedDurationProvider) puis mene
  // au Programme. La reco de `mixedAssessment` (intermediaire) = 5 jours de
  // marche (bornes du sentier test [3..7]).
  group('R2f — Generer mon programme applique la reco', () {
    /// Monte l'ecran avec la config sentier test (trailId + bornes de duree) et
    /// une route /trail/:id/planning pour observer la navigation. Expose le
    /// container pour lire selectedDurationProvider apres le tap.
    Future<ProviderContainer> pumpWithPlanningRoute(
      WidgetTester tester,
      FeasibilityAssessment assessment,
    ) async {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (_, __) => const TrekFeasibilityScreen()),
          GoRoute(
            path: '/trail/:id/planning',
            builder: (_, state) =>
                Scaffold(body: Text('PLANNING ${state.pathParameters['id']}')),
          ),
        ],
      );
      // 5 etapes seedees pour la SOURCE UNIQUE (bornes de duree du sentier =
      // fromStageCount(5) -> [3..7]) : la reco (5) est ainsi dans les bornes.
      StageModel st(int n) => StageModel(
        trailId: 'test-trail',
        stageNumber: n,
        name: 'Etape $n',
        distanceKm: 10,
        elevationGainM: 400,
        elevationLossM: 300,
        startLat: 42.0,
        startLng: 9.0,
        endLat: 42.1,
        endLng: 9.1,
      );
      late ProviderContainer container;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            trailConfigProvider.overrideWithValue(testTrailConfig),
            stagesProvider('test-trail').overrideWith(
              (ref) => Future.value([for (var n = 1; n <= 5; n++) st(n)]),
            ),
            feasibilityAssessmentProvider.overrideWith(
              (ref) async => assessment,
            ),
            // Criteres au complet (correctif N2 / D1) : ce groupe teste le
            // bouton « Generer mon programme », pas la porte d'entree.
            feasibilityCriteriaProvider.overrideWith(
              (ref) async => const FeasibilityCriteria(
                profileComplete: true,
                hasPastHike: true,
                hasWalkTest: true,
              ),
            ),
            hasObjectiveProfileProvider.overrideWith((ref) async => true),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              container = ProviderScope.containerOf(context);
              return MaterialApp.router(
                locale: const Locale('fr'),
                routerConfig: router,
              );
            },
          ),
        ),
      );
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 20));
      }
      return container;
    }

    testWidgets('le bouton est present et affiche la duree recommandee', (
      tester,
    ) async {
      await pumpWithPlanningRoute(tester, mixedAssessment());
      // TACHE 639 (DEM-260930-1238) — LE BOUTON ANNONCE LA DUREE DU PLAN.
      //
      // Il annoncait « 6 jours au total » : 5 jours de MARCHE plus 1 jour de
      // REPOS conseille. Verbatim de Christophe le 30/09 a 12:37 : « Si c est 7
      // jours c est 7 jours ». Le repos reste CONSEILLE et se lit a cote ; le
      // bouton applique et annonce les 5 jours de marche.
      expect(
        find.text(t.feasibility.formula.generateProgram(days: 5)),
        findsOneWidget,
      );
    });

    testWidgets(
      'taper le bouton FIXE la duree (source unique) et mene au Programme',
      (tester) async {
        final container = await pumpWithPlanningRoute(
          tester,
          mixedAssessment(),
        );
        // Duree de depart differente de la reco (3) pour prouver l'application.
        container.read(selectedDurationProvider.notifier).set(3);
        await tester.pump();
        expect(container.read(selectedDurationProvider), 3);

        // Le bouton est en bas de la vue scrollable -> le rendre visible avant tap.
        final button = find.widgetWithText(
          ElevatedButton,
          t.feasibility.formula.generateProgram(days: 5),
        );
        await tester.ensureVisible(button);
        await tester.tap(button);
        await tester.pumpAndSettle();

        // La SOURCE UNIQUE des jours est passee a la duree du PLAN (5 jours de
        // marche), plus au total repos compris (tache 639, DEM-260930-1238).
        expect(container.read(selectedDurationProvider), 5);
        // On a navigue vers le Programme du sentier (parite GR20 CONTINUER).
        expect(find.text('PLANNING test-trail'), findsOneWidget);
      },
    );

    // TACHE 569 (R1-c) — QUAND AUCUNE VALEUR NE MARCHE, ON N'EN PROPOSE AUCUNE.
    //
    // Chris l'a tranche : mieux vaut avouer qu'il n'y a pas de solution de
    // programme que d'en pointer une fausse. Un bouton « Generer mon programme
    // (N jours) » sous un ecran qui declare N mauvais est le pire des deux
    // mondes — c'est ce que faisait l'ancien code sur une etape indivisible.
    testWidgets(
      'aucune duree conseillee -> AUCUN bouton, et l ecran dit franchement '
      'que l etape bloque',
      (tester) async {
        final bloque = FeasibilityFormula.evaluate(
          stages: [stage(0, 'Mur', 40, 3000)],
          level: HikerLevel.beginner,
          durationAdvice: ProgramDurationAdvice.impossible,
        );
        expect(bloque.isDurationAdvised, isFalse);
        await pumpWithPlanningRoute(tester, bloque);

        // Le conseil franc est a l'ecran, et il NOMME la journee qui bloque.
        expect(
          find.text(t.feasibility.formula.advice.noViableDuration(stage: 1)),
          findsOneWidget,
        );
        // Et plus aucun bouton ne propose une duree : pas une seule valeur.
        expect(
          find.ancestor(
            of: find.byWidgetPredicate(
              (w) => w is StepIcon && w.asset == StepwaysIcons.calendrier,
            ),
            matching: find.byType(ElevatedButton),
          ),
          findsNothing,
          reason:
              'le bouton appliquerait une duree que l ecran declare '
              'mauvaise trois lignes plus haut',
        );
      },
    );
  });

  group('GO-61 — le repos s affiche et conseille, il ne decide pas', () {
    /// Sentier de production (7 etapes) pour un profil CONFIRME : toutes les
    /// etapes sont vertes, et la monotonie depasse pourtant son seuil. C est le
    /// cas exact qui rendait un circuit ROUGE devant des etapes vertes.
    FeasibilityAssessment reposConseille() => FeasibilityFormula.evaluate(
      stages: [
        stage(0, 'E1', 15, 850),
        stage(1, 'E2', 12, 600),
        stage(2, 'E3', 10, 400),
        stage(3, 'E4', 11, 550),
        stage(4, 'E5', 14, 650),
        stage(5, 'E6', 12, 500),
        stage(6, 'E7', 10, 200),
      ],
      level: HikerLevel.confirmed,
    );

    testWidgets('l ecran dit ce qui decide : la pire journee', (tester) async {
      await pumpScreen(tester, reposConseille());
      await ouvrirLeVoletEtAtteindre(
        tester,
        find.text(t.feasibility.formula.circuitIsWorstStage),
      );
      expect(
        find.text(t.feasibility.formula.circuitIsWorstStage),
        findsOneWidget,
      );
      // Le verdict du circuit EST celui des etapes : toutes vertes.
      final a = reposConseille();
      expect(a.globalVerdict, FeasibilityVerdict.green);
      expect(a.circuit!.rest, greaterThan(1.0));
    });

    testWidgets('le chiffre du repos est montre, avec sa non-decision', (
      tester,
    ) async {
      await pumpScreen(tester, reposConseille());
      await ouvrirLeVoletEtAtteindre(
        tester,
        find.byKey(const ValueKey('feasibility-rest-days-counted')),
      );
      expect(
        find.byKey(const ValueKey('feasibility-rest-days-counted')),
        findsOneWidget,
      );
      expect(find.text(t.feasibility.formula.restDaysNone), findsOneWidget);
      expect(find.text(t.feasibility.formula.restNotDecisive), findsOneWidget);
      // L extrapolation declaree reste dite la ou le chiffre est montre.
      expect(
        find.text(t.feasibility.formula.restExtrapolation),
        findsOneWidget,
      );
    });

    testWidgets('le CONSEIL est affiche : combien de repos, et ou', (
      tester,
    ) async {
      final a = reposConseille();
      await pumpScreen(tester, a);
      await ouvrirLeVoletEtAtteindre(
        tester,
        find.byKey(const ValueKey('feasibility-rest-advised')),
      );
      expect(
        find.byKey(const ValueKey('feasibility-rest-advised')),
        findsOneWidget,
      );
      expect(
        find.text(
          t.feasibility.formula.restAdvisedLine(days: a.recommendedRestDays),
        ),
        findsOneWidget,
      );
      // Et le meme conseil, en toutes lettres, dans les conseils de programme.
      expect(
        find.text(
          t.feasibility.formula.advice.restAdvised(
            days: a.recommendedRestDays,
            stages: (a.recommendedRestAfterStageIndex.toList()..sort())
                .map((i) => i + 1)
                .join(', '),
          ),
        ),
        findsOneWidget,
      );
    });
  });
}
