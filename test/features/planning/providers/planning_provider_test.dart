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

  // ---------------------------------------------------------------------------
  // TACHE 558 — LA BORNE HAUTE A ETE ELARGIE, ET CES TESTS LE DISENT.
  //
  // Elle valait « nombre d'etapes + marge de repos ». Chris s'y est cogne, mot
  // pour mot : « ca me propose 9jours, je peux pas augmenter et ca met tout en
  // rouge !!! ». Entre le nombre d'etapes et cette borne, les seuls jours
  // disponibles etaient du REPOS — et le repos ne change rien a la pire journee,
  // donc rien au verdict (GO-61) : le curseur butait exactement la ou il aurait
  // commence a servir.
  //
  // La borne haute couvre desormais le DECOUPAGE (deux journees par etape) plus
  // le repos. La borne NATURELLE — une etape par jour plus le repos, l'ancienne
  // borne haute — est conservee a part : c'est elle qui plafonne le programme
  // PAR DEFAUT, pour qu'aucun sentier ne s'ouvre sur des etapes deja coupees.
  // ---------------------------------------------------------------------------
  group('DurationBounds — bornes derivees du nombre d etapes', () {
    test('bornes generiques centrees sur le nombre d etapes', () {
      // 5 etapes : min = ceil(5/2) = 3 ; marge repos = round(5/3) = 2 ;
      // borne NATURELLE = 5 + 2 = 7 ; borne HAUTE = 5 x 2 + 2 = 12.
      // Les bornes suivent le sentier, jamais « 16 » en dur.
      final b = DurationBounds.fromStageCount(5);
      expect(b.min, 3);
      expect(b.naturalMax, 7);
      expect(b.restAllowance, 2);
      expect(b.max, 12);
      expect(b.options.first, 3);
      expect(b.options.last, 12);
    });

    test('la borne haute ne peut pas etre sous le repos CONSEILLE (GO-61)', () {
      // 5 etapes : la marge de repos « maison » vaut 2. Si le moteur en
      // conseille 4, le budget de repos suit — sinon l application proposerait
      // un programme que son propre curseur refuserait d atteindre.
      final b = DurationBounds.fromStageCount(5, recommendedRestDays: 4);
      expect(b.min, 3);
      expect(b.restAllowance, 4);
      expect(b.naturalMax, 9);
      expect(b.max, 14);
      // Et le budget ne RETRECIT jamais : un conseil plus petit que la marge
      // laisse la marge en place.
      final c = DurationBounds.fromStageCount(5, recommendedRestDays: 1);
      expect(c.restAllowance, 2);
      expect(c.naturalMax, 7);
      expect(c.max, 12);
    });

    test('un sentier a 1 etape garde un curseur : son etape se COUPE', () {
      // Avant la tache 558, ce sentier n'avait AUCUN choix de duree (min = max
      // = 1) : une seule etape, rien a regrouper. Il n'avait donc aucun moyen
      // d'alleger sa seule journee. Elle se coupe desormais en deux.
      final b = DurationBounds.fromStageCount(1);
      expect(b.min, 1);
      expect(b.naturalMax, 1, reason: 'par defaut, l etape reste entiere');
      expect(b.max, 2, reason: 'mais on peut la couper en deux journees');
      expect(b.options, [1, 2]);
    });

    test('cas vide (etapes non chargees) : borne neutre', () {
      final b = DurationBounds.fromStageCount(0);
      expect(b.min, 1);
      expect(b.max, 1);
      expect(b.naturalMax, 1);
    });

    test('clampDuration ramene une valeur hors bornes', () {
      // 10 etapes : min 5 ; marge repos = round(10/3) = 3 ;
      // naturalMax = 13 ; max = 20 + 3 = 23.
      final b = DurationBounds.fromStageCount(10);
      expect(b.min, 5);
      expect(b.naturalMax, 13);
      expect(b.max, 23);
      expect(b.clampDuration(2), 5);
      expect(b.clampDuration(99), 23);
      expect(b.clampDuration(8), 8);
      // Le DEFAUT, lui, ne depasse jamais la duree naturelle : le decoupage se
      // demande, il ne s impose pas au premier ecran.
      expect(b.clampDefaultDuration(99), 13);
      expect(b.clampDefaultDuration(2), 5);
      expect(b.clampDefaultDuration(11), 11);
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
      // 5 etapes : duree naturelle 7, borne haute 12 (decoupage compris).
      expect(bounds.naturalMax, 7);
      expect(bounds.max, 12);
      expect(bounds.options.contains(5), isTrue);

      container.dispose();
    });
  });
}
