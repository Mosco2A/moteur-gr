import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/config/test_trail_config.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/core/models/stage.dart';
import 'package:moteur_gr/features/planning/presentation/planning_screen.dart';
import 'package:moteur_gr/features/trail/providers/stages_provider.dart';

/// Tests widget de l'écran PlanningScreen.
void main() {
  /// Fabrique une étape fictive
  StageModel makeStage(int num, double km, int gain) {
    return StageModel(
      trailId: 'test-trail',
      stageNumber: num,
      name: 'Étape $num',
      distanceKm: km,
      elevationGainM: gain,
      elevationLossM: (gain * 0.8).round(),
      startLat: 42.0,
      startLng: 9.0,
      endLat: 42.1,
      endLng: 9.1,
    );
  }

  final testStages = [
    makeStage(1, 12.0, 800),
    makeStage(2, 15.0, 600),
    makeStage(3, 10.0, 1000),
    makeStage(4, 8.0, 400),
    makeStage(5, 14.0, 700),
  ];

  group('PlanningScreen', () {
    testWidgets('affiche le bon nombre de jours', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            trailConfigProvider.overrideWithValue(testTrailConfig),
            stagesProvider('test-trail').overrideWith(
              (ref) => Future.value(testStages),
            ),
          ],
          child: const MaterialApp(
            home: PlanningScreen(trailId: 'test-trail'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Vérifier que Jour 1 est affiché (visible à l'écran)
      expect(find.textContaining('Jour 1'), findsOneWidget);
      // Vérifier que le DayPlanCard est bien généré
      // (on cherche le nombre de cards via le widget)
      expect(
        find.textContaining('Jour'),
        findsWidgets,
      );
    });

    testWidgets('changement de durée recalcule le planning',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            trailConfigProvider.overrideWithValue(testTrailConfig),
            stagesProvider('test-trail').overrideWith(
              (ref) => Future.value(testStages),
            ),
          ],
          child: const MaterialApp(
            home: PlanningScreen(trailId: 'test-trail'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Le chip "5 j" doit être sélectionné par défaut
      expect(find.text('5 j'), findsOneWidget);

      // Taper sur "7 j" pour changer la durée
      await tester.tap(find.text('7 j'));
      await tester.pumpAndSettle();

      // Avec 7 jours et 5 étapes, il doit y avoir des jours de repos
      expect(find.text('Jour de repos'), findsWidgets);
    });

    testWidgets('affiche le résumé en bas', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            trailConfigProvider.overrideWithValue(testTrailConfig),
            stagesProvider('test-trail').overrideWith(
              (ref) => Future.value(testStages),
            ),
          ],
          child: const MaterialApp(
            home: PlanningScreen(trailId: 'test-trail'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Le résumé doit afficher les totaux
      // 12+15+10+8+14 = 59.0 km
      expect(find.textContaining('59.0 km'), findsOneWidget);
      // Jours de marche
      expect(find.textContaining('j. marche'), findsOneWidget);
    });

    testWidgets('affiche le titre Planning dans l\'AppBar',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            trailConfigProvider.overrideWithValue(testTrailConfig),
            stagesProvider('test-trail').overrideWith(
              (ref) => Future.value(testStages),
            ),
          ],
          child: const MaterialApp(
            home: PlanningScreen(trailId: 'test-trail'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Planning'), findsOneWidget);
    });
  });
}
