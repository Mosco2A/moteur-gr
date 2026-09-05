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

  group('DurationBounds — bornes derivees du nombre d etapes', () {
    test('bornes generiques centrees sur le nombre d etapes', () {
      // 5 etapes : min = ceil(5/2) = 3 ; marge repos = round(5/3) = 2 ;
      // max = 5 + 2 = 7. Les bornes suivent le sentier, jamais « 16 » en dur.
      final b = DurationBounds.fromStageCount(5);
      expect(b.min, 3);
      expect(b.max, 7);
      expect(b.options, [3, 4, 5, 6, 7]);
    });

    test('un sentier a 1 etape n a pas de choix de duree', () {
      final b = DurationBounds.fromStageCount(1);
      expect(b.min, 1);
      expect(b.max, 1);
      expect(b.options, [1]);
    });

    test('cas vide (etapes non chargees) : borne neutre', () {
      final b = DurationBounds.fromStageCount(0);
      expect(b.min, 1);
      expect(b.max, 1);
    });

    test('clampDuration ramene une valeur hors bornes', () {
      final b = DurationBounds.fromStageCount(10); // min 5, max 10 + 3 = 13
      expect(b.min, 5);
      expect(b.max, 13);
      expect(b.clampDuration(2), 5);
      expect(b.clampDuration(99), 13);
      expect(b.clampDuration(8), 8);
    });

    test('les bornes ne sont PAS hardcodees : varient avec le sentier', () {
      final small = DurationBounds.fromStageCount(6);
      final big = DurationBounds.fromStageCount(20);
      expect(small.max, lessThan(big.max));
      expect(small.min, lessThan(big.min));
    });

    test('durationBoundsProvider derive du nombre d etapes reel', () async {
      final container = ProviderContainer(
        overrides: [
          trailConfigProvider.overrideWithValue(testTrailConfig),
          stagesProvider('test-trail')
              .overrideWith((ref) => Future.value(testStages)),
        ],
      );
      // Force le chargement des etapes (5).
      await container.read(stagesProvider('test-trail').future);
      final bounds = container.read(durationBoundsProvider('test-trail'));
      expect(bounds.min, 3);
      expect(bounds.max, 7);
      expect(bounds.options.contains(5), isTrue);

      container.dispose();
    });
  });
}
