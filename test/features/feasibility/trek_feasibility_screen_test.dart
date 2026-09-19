import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moteur_gr/core/config/test_trail_config.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/core/models/stage.dart';
import 'package:moteur_gr/features/feasibility/domain/feasibility_formula.dart';
import 'package:moteur_gr/features/feasibility/presentation/trek_feasibility_screen.dart';
import 'package:moteur_gr/features/feasibility/providers/trek_feasibility_provider.dart';
import 'package:moteur_gr/features/planning/providers/planning_provider.dart';
import 'package:moteur_gr/features/trail/providers/stages_provider.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

/// Test WIDGET de l'ecran de faisabilite FEU TRICOLORE (LOT 3a, #100068).
///
/// Verifie que le verdict global, les pastilles par etape (vert/orange/rouge),
/// le facteur limitant et les conseils de programme s'affichent avec les
/// libelles Slang FR (accents). L'evaluation est injectee via override du
/// provider (calcul deja teste a l'unite dans feasibility_formula_test.dart).
void main() {
  setUpAll(() => LocaleSettings.setLocaleRaw('fr'));

  StageEffort stage(int i, String name, double dist, int elev) => StageEffort(
        index: i,
        name: name,
        distanceKm: dist,
        elevationGainM: elev,
      );

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
        GoRoute(
          path: '/',
          builder: (_, __) => const TrekFeasibilityScreen(),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          feasibilityAssessmentProvider.overrideWith((ref) async => assessment),
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

  testWidgets('affiche le verdict global tricolore + le plafond', (tester) async {
    await pumpScreen(tester,mixedAssessment());
    // Verdict global rouge (etape la plus dure).
    expect(find.text(t.feasibility.formula.verdicts.red), findsWidgets);
    // Plafond conseille (niveau intermediaire).
    expect(find.textContaining('Plafond conseillé'), findsOneWidget);
    // Titre de l'ecran.
    expect(find.text(t.feasibility.formula.title), findsOneWidget);
  });

  testWidgets('affiche les trois couleurs par etape', (tester) async {
    await pumpScreen(tester,mixedAssessment());
    // Chaque etape porte son libelle de verdict.
    expect(find.text(t.feasibility.formula.verdicts.red), findsWidgets);
    expect(find.text(t.feasibility.formula.verdicts.orange), findsWidgets);
    expect(find.text(t.feasibility.formula.verdicts.green), findsWidgets);
    // Les noms d'etapes sont rendus.
    expect(find.text('Depart -> Col'), findsWidgets);
    expect(find.text('Refuge -> Village'), findsOneWidget);
  });

  testWidgets('nomme le facteur limitant et la reco entrainement', (tester) async {
    await pumpScreen(tester,mixedAssessment());
    expect(find.textContaining('Facteur limitant'), findsOneWidget);
    expect(find.textContaining('Entraînement conseillé'), findsOneWidget);
  });

  testWidgets('affiche les conseils de programme (decoupe)', (tester) async {
    await pumpScreen(tester,mixedAssessment());
    expect(find.text(t.feasibility.formula.adviceTitle), findsOneWidget);
    // L'etape 1 est rouge -> conseil de decoupe present.
    expect(find.textContaining('Découpe'), findsOneWidget);
  });

  testWidgets('assessment vert -> conseil equilibre, pas de facteur limitant',
      (tester) async {
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
    await pumpScreen(tester,null);
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
          GoRoute(
            path: '/',
            builder: (_, __) => const TrekFeasibilityScreen(),
          ),
          GoRoute(
            path: '/trail/:id/planning',
            builder: (_, state) => Scaffold(
              body: Text('PLANNING ${state.pathParameters['id']}'),
            ),
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
                (ref) => Future.value([for (var n = 1; n <= 5; n++) st(n)])),
            feasibilityAssessmentProvider
                .overrideWith((ref) async => assessment),
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

    testWidgets('le bouton est present et affiche la duree recommandee',
        (tester) async {
      await pumpWithPlanningRoute(tester, mixedAssessment());
      // Reco = 5 jours (bornee [3..7]).
      expect(
        find.text(t.feasibility.formula.generateProgram(days: 5)),
        findsOneWidget,
      );
    });

    testWidgets(
        'taper le bouton FIXE la duree (source unique) et mene au Programme',
        (tester) async {
      final container = await pumpWithPlanningRoute(tester, mixedAssessment());
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

      // La SOURCE UNIQUE des jours est passee a la reco (5).
      expect(container.read(selectedDurationProvider), 5);
      // On a navigue vers le Programme du sentier (parite GR20 CONTINUER).
      expect(find.text('PLANNING test-trail'), findsOneWidget);
    });
  });
}

