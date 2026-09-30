// V1 ARGENT (tache 594, A2c) — LA DEMO BRIDEE AVAIT LE SENS INVERSE.
//
// Le modele eco du 08/09, §2 : « Gratuit / demo : consultation + demo BRIDEE
// des outils — SAC A DOS + PREPA PHYSIQUE jouables "pour de faux" (version
// bridee), toutes les autres categories GRISEES (visibles, verrouillees,
// jamais cachees) ».
//
// CE QUE L APPLICATION FAISAIT. L entrainement etait VERROUILLE derriere un
// apercu grise — visible, oui, mais NON JOUABLE : zero case a cocher, un
// cadenas et trois barres grises a la place des seances. Et le sac n avait
// AUCUN bridage : recherche `isDemo|PurchaseGate|paywall|demo` dans
// `lib/features/checklist/` = zero occurrence de monetisation. Il s ouvrait
// entier, gratuit et complet, contraire a la decision qui exige l achat du
// trek (inventaire 593 §M7).
//
// Les deux sens etaient donc inverses : verrouille ce qui devait etre jouable,
// offert ce qui devait etre bride.
//
// TESTS ECRITS ROUGES AVANT CORRECTION.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moteur_gr/core/config/test_trail_config.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/core/services/monetization_service.dart';
import 'package:moteur_gr/features/training/models/training_plan.dart';
import 'package:moteur_gr/features/training/presentation/training_screen.dart';
import 'package:moteur_gr/features/training/providers/training_plan_providers.dart';
import 'package:moteur_gr/i18n/translations.g.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const plan = TrainingPlan(
    trailId: 'test-trail',
    durationWeeks: 8,
    phases: [
      TrainingPhase(
        id: 'foundation',
        weekStart: 1,
        weekEnd: 2,
        titleFr: 'Fondation',
        sessions: [
          TrainingSession(id: 'foundation-s1', labelFr: 'Sortie cardio 1 h'),
          TrainingSession(id: 'foundation-s2', labelFr: 'Marche + renfo'),
        ],
      ),
      TrainingPhase(
        id: 'denivele',
        weekStart: 3,
        weekEnd: 5,
        titleFr: 'Denivele',
        sessions: [TrainingSession(id: 'denivele-s1', labelFr: 'Cotes')],
      ),
      TrainingPhase(
        id: 'endurance',
        weekStart: 6,
        weekEnd: 8,
        titleFr: 'Endurance',
        sessions: [
          TrainingSession(id: 'endurance-s1', labelFr: 'Sortie longue'),
        ],
      ),
    ],
    objective: TrainingObjective(labelFr: 'Tenir 6 h de marche'),
  );

  setUp(() => SharedPreferences.setMockInitialValues({}));

  Widget ecranEntrainement({required bool isDemo}) {
    return ProviderScope(
      overrides: [
        trailConfigProvider.overrideWithValue(testTrailConfig),
        isDemoModeProvider(
          testTrailConfig.id,
        ).overrideWith((ref) async => isDemo),
        trainingPlanProvider.overrideWith((ref) async => plan),
        trainingDepartureDateProvider.overrideWithValue(
          DateTime.now().add(const Duration(days: 90)),
        ),
      ],
      child: TranslationProvider(
        child: MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: '/training',
            routes: [
              GoRoute(
                path: '/training',
                builder: (_, __) => const TrainingScreen(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  group('A2c — la prepa physique est JOUABLE en demo, pas verrouillee', () {
    testWidgets('en demo, la premiere phase est reellement cochable', (
      tester,
    ) async {
      await tester.pumpWidget(ecranEntrainement(isDemo: true));
      await tester.pumpAndSettle();

      expect(
        find.byType(CheckboxListTile),
        findsWidgets,
        reason:
            'le modele demande la prepa physique JOUABLE en version '
            'bridee ; l ecran la verrouillait derriere un apercu grise',
      );

      final avant = tester
          .widgetList<CheckboxListTile>(find.byType(CheckboxListTile))
          .where((c) => c.value == true)
          .length;
      await tester.tap(find.byType(CheckboxListTile).first);
      await tester.pumpAndSettle();
      final apres = tester
          .widgetList<CheckboxListTile>(find.byType(CheckboxListTile))
          .where((c) => c.value == true)
          .length;
      expect(
        apres,
        avant + 1,
        reason:
            'jouable « pour de faux » veut dire que le geste produit '
            'quelque chose a l ecran',
      );
    });

    testWidgets('en demo, le bridage est dit, et il est borne', (tester) async {
      await tester.pumpWidget(ecranEntrainement(isDemo: true));
      await tester.pumpAndSettle();

      // Le bandeau dit que c est un essai (jamais un geste sans explication).
      expect(find.text(t.training.demoBridledTitle), findsOneWidget);
      // Seules les phases bridees sont jouables : les suivantes sont GRISEES,
      // visibles, verrouillees — jamais cachees.
      expect(
        find.byKey(const ValueKey('training-demo-locked-denivele')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('training-demo-locked-endurance')),
        findsOneWidget,
      );
      // Leur titre reste LISIBLE (visible, pas cache).
      expect(
        find.textContaining('Denivele', skipOffstage: false),
        findsWidgets,
      );
      // Et leurs seances, elles, ne sont pas servies.
      expect(find.text('Cotes', skipOffstage: false), findsNothing);
      expect(find.text('Sortie longue', skipOffstage: false), findsNothing);
      // Le nombre de phases jouables suit le point de reglage unique.
      expect(kDemoTrainingPhasesPlayable, 1);
    });

    testWidgets('en demo, on dit toujours ou acheter', (tester) async {
      await tester.pumpWidget(ecranEntrainement(isDemo: true));
      await tester.pumpAndSettle();
      expect(find.text(t.training.unlock, skipOffstage: false), findsOneWidget);
      expect(
        find.text(t.training.paywallTitle, skipOffstage: false),
        findsOneWidget,
      );
    });

    testWidgets('debloque : le plan entier, sans bandeau d essai', (
      tester,
    ) async {
      await tester.pumpWidget(ecranEntrainement(isDemo: false));
      await tester.pumpAndSettle();
      expect(find.text(t.training.demoBridledTitle), findsNothing);
      expect(find.text(t.training.unlock), findsNothing);
      expect(find.byType(CheckboxListTile), findsWidgets);
    });
  });
}
