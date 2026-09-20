import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/config/test_trail_config.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/core/models/stage.dart';
import 'package:moteur_gr/features/planning/providers/planned_days_provider.dart';
import 'package:moteur_gr/features/planning/providers/planning_provider.dart';
import 'package:moteur_gr/features/trail/providers/stages_provider.dart';
import 'package:moteur_gr/features/trek/providers/gps_providers.dart';

/// Tests du PROGRAMME editable (regrouper / separer, parite GR20).
///
/// Verifie l'ETAT REEL des affordances rapportees par Christophe :
///   - REGROUPER doit fonctionner sur des jours adjacents (limite 16 h) ;
///   - SEPARER ne doit JAMAIS etre propose sur un jour mono-etape, mais l'etre
///     sur un jour multi-etapes.
void main() {
  StageModel makeStage(int num, double km, int gain) {
    return StageModel(
      trailId: 'test-trail',
      stageNumber: num,
      name: 'Etape $num',
      distanceKm: km,
      elevationGainM: gain,
      elevationLossM: (gain * 0.8).round(),
      startLat: 42.0,
      startLng: 9.0,
      endLat: 42.1,
      endLng: 9.1,
    );
  }

  // 5 etapes courtes : la somme de 2 etapes adjacentes reste < 16 h -> merge
  // toujours possible entre voisins (Naismith : ~ (km/4 + D+/400) h).
  final testStages = [
    makeStage(1, 8.0, 400),
    makeStage(2, 10.0, 500),
    makeStage(3, 9.0, 450),
    makeStage(4, 7.0, 350),
    makeStage(5, 11.0, 550),
  ];

  ProviderContainer makeContainer({int? duration}) {
    final container = ProviderContainer(
      overrides: [
        trailConfigProvider.overrideWithValue(testTrailConfig),
        stagesProvider('test-trail')
            .overrideWith((ref) => Future.value(testStages)),
      ],
    );
    // Charger les etapes puis fixer la duree (chaque jour = 1 etape).
    return container;
  }

  group('PROGRAMME editable — regrouper (merge)', () {
    test('REGROUPER est possible entre deux jours adjacents (mono-etape)',
        () async {
      final container = makeContainer();
      await container.read(stagesProvider('test-trail').future);
      // 5 jours = 5 etapes (1 etape / jour).
      container.read(selectedDurationProvider.notifier).set(5);

      final notifier =
          container.read(plannedDaysProvider('test-trail').notifier);
      // Etat initial : 5 jours mono-etape.
      expect(container.read(plannedDaysProvider('test-trail')).length, 5);

      // Le jour 1 PEUT etre regroupe avec le jour 2 (2 etapes courtes < 16 h).
      expect(notifier.canMergeWithNext(0), isTrue);
      expect(notifier.mergeBlockedReason(0), isNull);

      notifier.mergeWithNext(0);
      final days = container.read(plannedDaysProvider('test-trail'));
      // Un jour de moins ; le 1er jour porte 2 etapes.
      expect(days.length, 4);
      expect(days.first.stages.length, 2);

      container.dispose();
    });

    test('REGROUPER est bloque (raison rest) avec un jour de repos', () async {
      final container = makeContainer();
      await container.read(stagesProvider('test-trail').future);
      container.read(selectedDurationProvider.notifier).set(5);

      final notifier =
          container.read(plannedDaysProvider('test-trail').notifier);
      // Inserer un repos apres le jour 1 -> le jour 1 a un voisin « repos ».
      notifier.addRestDay(0);
      expect(notifier.canMergeWithNext(0), isFalse);
      expect(notifier.mergeBlockedReason(0), 'rest');

      container.dispose();
    });
  });

  group('PROGRAMME editable — separer (split)', () {
    test('SEPARER est INDISPONIBLE sur un jour mono-etape', () async {
      final container = makeContainer();
      await container.read(stagesProvider('test-trail').future);
      container.read(selectedDurationProvider.notifier).set(5);

      final notifier =
          container.read(plannedDaysProvider('test-trail').notifier);
      final days = container.read(plannedDaysProvider('test-trail'));
      // Chaque jour ne porte qu'une etape -> aucun split possible.
      for (var i = 0; i < days.length; i++) {
        expect(notifier.canSplit(i), isFalse,
            reason: 'jour $i mono-etape ne doit pas etre separable');
      }
      // splitDay est un no-op sur un mono-etape (pas de dedoublement).
      notifier.splitDay(0);
      expect(container.read(plannedDaysProvider('test-trail')).length, 5);

      container.dispose();
    });

    test('SEPARER est DISPONIBLE sur un jour multi-etapes, et le decoupe',
        () async {
      final container = makeContainer();
      await container.read(stagesProvider('test-trail').future);
      // 3 jours < 5 etapes -> au moins un jour porte plusieurs etapes.
      container.read(selectedDurationProvider.notifier).set(3);

      final notifier =
          container.read(plannedDaysProvider('test-trail').notifier);
      final days = container.read(plannedDaysProvider('test-trail'));
      expect(days.length, 3);

      final multiIndex = days.indexWhere((d) => d.stages.length > 1);
      expect(multiIndex, isNot(-1),
          reason: '3 jours pour 5 etapes -> un jour multi-etapes existe');
      expect(notifier.canSplit(multiIndex), isTrue);

      final before = days.length;
      final splitCount = days[multiIndex].stages.length;
      notifier.splitDay(multiIndex);
      final after = container.read(plannedDaysProvider('test-trail'));
      // Le jour multi-etapes eclate en N jours mono-etape.
      expect(after.length, before - 1 + splitCount);

      container.dispose();
    });
  });

  // Retour QA polish (P3) : coherence Itineraire<->Programme. Le programme doit
  // honorer selectedDirectionProvider comme l'itineraire -> sens inverse =>
  // ordre des etapes du Programme inverse (Jour 1 = etape de depart du sens
  // choisi). testTrailConfig.directions = ['NS', 'SN'] (NS = sens de reference).
  group('PROGRAMME — honore le sens de marche (parite itineraire)', () {
    test('sens de reference (defaut) : Jour 1 = 1re etape (ordre croissant)',
        () async {
      final container = makeContainer();
      await container.read(stagesProvider('test-trail').future);
      container.read(selectedDurationProvider.notifier).set(5);

      final days = container.read(plannedDaysProvider('test-trail'));
      // 5 jours mono-etape, ordre croissant : J1=E1 ... J5=E5.
      expect(days.first.stages.single.stageNumber, 1);
      expect(days.last.stages.single.stageNumber, 5);

      container.dispose();
    });

    test('sens INVERSE (SN) : Jour 1 = derniere etape (ordre inverse)',
        () async {
      final container = ProviderContainer(
        overrides: [
          trailConfigProvider.overrideWithValue(testTrailConfig),
          stagesProvider('test-trail')
              .overrideWith((ref) => Future.value(testStages)),
        ],
      );
      await container.read(stagesProvider('test-trail').future);
      container.read(selectedDurationProvider.notifier).set(5);
      // Inverser le sens (sens != 1er sens declare) comme le fait l'itineraire.
      container.read(selectedDirectionProvider.notifier).state = 'SN';

      final days = container.read(plannedDaysProvider('test-trail'));
      // Ordre inverse : J1=E5 ... J5=E1 (coherent avec l'itineraire inverse).
      expect(days.first.stages.single.stageNumber, 5);
      expect(days.last.stages.single.stageNumber, 1);

      container.dispose();
    });

    test('selection explicite du sens de reference (NS) : ordre croissant',
        () async {
      final container = ProviderContainer(
        overrides: [
          trailConfigProvider.overrideWithValue(testTrailConfig),
          stagesProvider('test-trail')
              .overrideWith((ref) => Future.value(testStages)),
        ],
      );
      await container.read(stagesProvider('test-trail').future);
      container.read(selectedDurationProvider.notifier).set(5);
      container.read(selectedDirectionProvider.notifier).state = 'NS';

      final days = container.read(plannedDaysProvider('test-trail'));
      expect(days.first.stages.single.stageNumber, 1);
      expect(days.last.stages.single.stageNumber, 5);

      container.dispose();
    });
  });

  // -------------------------------------------------------------------------
  // R5 (retour Chris, LOT L10) — LE SENS DE MARCHE S'APPLIQUE AUX TOTAUX
  //
  // Les lignes JOUR PAR JOUR de l'ecran Resume honoraient deja le sens
  // (`directionalDayStats` echange D+ et D-), mais les TOTAUX du MEME ecran
  // sommaient les valeurs brutes du seed : incoherence interne, et rupture de
  // parite GR20 (qui oriente les etapes AVANT de sommer).
  //
  // Le defaut est INVISIBLE sur le seed actuel du Mare a Mare, ou D+ total et
  // D- total valent 3750 m tous les deux par hasard. D'ou ce jeu d'etapes ou
  // les deux totaux DIFFERENT : c'est la seule facon de prouver le correctif.
  // -------------------------------------------------------------------------
  group('R5 — planningStatsProvider honore le SENS DE MARCHE', () {
    // Sommes du jeu d'etapes ci-dessus : D+ = 400+500+450+350+550 = 2250 m ;
    // D- = 320+400+360+280+440 = 1800 m (chaque etape perd 80 % de son D+).
    const gainForward = 2250;
    const lossForward = 1800;

    Future<ProviderContainer> containerWith({String? direction}) async {
      final container = makeContainer();
      await container.read(stagesProvider('test-trail').future);
      container.read(selectedDurationProvider.notifier).set(5);
      if (direction != null) {
        container.read(selectedDirectionProvider.notifier).state = direction;
      }
      return container;
    }

    test('aucun sens choisi : totaux dans le sens de REFERENCE', () async {
      final container = await containerWith();
      addTearDown(container.dispose);

      final stats = container.read(planningStatsProvider('test-trail'));
      expect(stats.totalElevationGain, gainForward);
      expect(stats.totalElevationLoss, lossForward);
    });

    test('sens de reference (NS) explicite : totaux inchanges', () async {
      final container = await containerWith(direction: 'NS');
      addTearDown(container.dispose);

      final stats = container.read(planningStatsProvider('test-trail'));
      expect(stats.totalElevationGain, gainForward);
      expect(stats.totalElevationLoss, lossForward);
    });

    test('sens INVERSE (SN) : les D+/D- GLOBAUX s\'echangent', () async {
      final container = await containerWith(direction: 'SN');
      addTearDown(container.dispose);

      final stats = container.read(planningStatsProvider('test-trail'));
      // Ce qu'on monte a l'aller se descend au retour, et reciproquement.
      expect(stats.totalElevationGain, lossForward);
      expect(stats.totalElevationLoss, gainForward);
    });

    test('distance, duree et etapes restent INVARIANTES au sens', () async {
      final ns = await containerWith(direction: 'NS');
      addTearDown(ns.dispose);
      final sn = await containerWith(direction: 'SN');
      addTearDown(sn.dispose);

      final forward = ns.read(planningStatsProvider('test-trail'));
      final backward = sn.read(planningStatsProvider('test-trail'));

      expect(backward.totalDistance, forward.totalDistance);
      expect(backward.totalHours, forward.totalHours);
      expect(backward.stageCount, forward.stageCount);
      expect(backward.trekDays, forward.trekDays);
    });
  });
}
