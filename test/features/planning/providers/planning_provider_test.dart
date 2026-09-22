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
    test(
        'le programme par defaut porte les REPOS CONSEILLES (GO-61)',
        () async {
      final container = ProviderContainer(
        overrides: [
          trailConfigProvider.overrideWithValue(testTrailConfig),
          stagesProvider('test-trail').overrideWith(
            (ref) => Future.value(testStages),
          ),
        ],
      );

      // defaultDuration = 5 dans testTrailConfig (5 etapes, une par jour). Le
      // moteur conseille 2 jours de repos sur ces cinq etapes : le programme
      // PAR DEFAUT les pose, au lieu de laisser le randonneur partir sans une
      // seule journee de recuperation et reparer lui-meme.
      //
      // Le plan est lu EN PREMIER : tant que les etapes ne sont pas arrivees,
      // on ne conseille rien (on ne devine pas un repos sur un sentier qu on
      // n a pas encore lu), et les deux providers derives valent leur valeur
      // neutre.
      final plan = await container
          .read(planningProvider('test-trail').future);

      expect(container.read(recommendedRestDaysProvider('test-trail')), 2);
      expect(container.read(defaultDurationWithRestProvider('test-trail')), 7);
      expect(plan.length, 7);
      expect(plan.where((d) => d.isRestDay).length, 2);
      expect(plan.where((d) => !d.isRestDay).length, 5);

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

      // Plan initial : 5 jours de marche + 2 repos conseilles (GO-61).
      var plan = await container
          .read(planningProvider('test-trail').future);
      expect(plan.length, 7);

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

    test(
        'sans etapes chargees, aucun repos n est conseille : la duree par '
        'defaut reste celle du sentier', () {
      // On ne conseille rien sur des etapes qu on n a pas : tant que le sentier
      // n est pas charge, le repos conseille vaut zero et la duree par defaut
      // est celle declaree par le sentier — pas un chiffre devine.
      final container = ProviderContainer(
        overrides: [
          trailConfigProvider.overrideWithValue(testTrailConfig),
        ],
      );

      expect(container.read(recommendedRestDaysProvider('test-trail')), 0);
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

    test('la borne haute ne peut pas etre sous le repos CONSEILLE (GO-61)', () {
      // 5 etapes : la marge de repos « maison » vaut 2. Si le moteur en
      // conseille 4, la borne suit — sinon l application proposerait un
      // programme que son propre curseur refuserait d atteindre.
      final b = DurationBounds.fromStageCount(5, recommendedRestDays: 4);
      expect(b.min, 3);
      expect(b.max, 9);
      // Et elle ne RETRECIT jamais : un conseil plus petit que la marge laisse
      // la marge en place.
      final c = DurationBounds.fromStageCount(5, recommendedRestDays: 1);
      expect(c.max, 7);
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
