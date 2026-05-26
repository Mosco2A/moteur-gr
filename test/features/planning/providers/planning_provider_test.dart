import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/config/test_trail_config.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/core/models/stage.dart';
import 'package:moteur_gr/features/planning/providers/planning_provider.dart';
import 'package:moteur_gr/features/trail/providers/stages_provider.dart';

/// Tests du provider de planning.
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

  group('planningProvider', () {
    test('retourne un planning avec le bon nombre de jours',
        () async {
      final container = ProviderContainer(
        overrides: [
          trailConfigProvider.overrideWithValue(testTrailConfig),
          stagesProvider('test-trail').overrideWith(
            (ref) => Future.value(testStages),
          ),
        ],
      );

      final plan = await container
          .read(planningProvider('test-trail').future);

      // defaultDuration = 5 dans testTrailConfig
      expect(plan.length, 5);

      container.dispose();
    });

    test('recalcule quand la durée change', () async {
      final container = ProviderContainer(
        overrides: [
          trailConfigProvider.overrideWithValue(testTrailConfig),
          stagesProvider('test-trail').overrideWith(
            (ref) => Future.value(testStages),
          ),
        ],
      );

      // Plan initial avec durée par défaut (5 jours)
      var plan = await container
          .read(planningProvider('test-trail').future);
      expect(plan.length, 5);

      // Changer la durée à 3 jours
      container.read(selectedDurationProvider.notifier).state = 3;

      // Attendre le recalcul
      plan = await container
          .read(planningProvider('test-trail').future);
      expect(plan.length, 3);

      container.dispose();
    });

    test('recalcule quand la durée passe à 7 jours (avec repos)',
        () async {
      final container = ProviderContainer(
        overrides: [
          trailConfigProvider.overrideWithValue(testTrailConfig),
          stagesProvider('test-trail').overrideWith(
            (ref) => Future.value(testStages),
          ),
        ],
      );

      // Changer la durée à 7 jours
      container.read(selectedDurationProvider.notifier).state = 7;

      final plan = await container
          .read(planningProvider('test-trail').future);

      expect(plan.length, 7);
      // 5 étapes + 2 repos
      final walkDays = plan.where((d) => !d.isRestDay).length;
      final restDays = plan.where((d) => d.isRestDay).length;
      expect(walkDays, 5);
      expect(restDays, 2);

      container.dispose();
    });

    test('selectedDurationProvider initialisé avec defaultDuration',
        () {
      final container = ProviderContainer(
        overrides: [
          trailConfigProvider.overrideWithValue(testTrailConfig),
        ],
      );

      final duration = container.read(selectedDurationProvider);
      expect(duration, testTrailConfig.defaultDuration);

      container.dispose();
    });
  });
}
