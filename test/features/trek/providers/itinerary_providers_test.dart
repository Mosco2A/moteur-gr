import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/config/test_trail_config.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/core/models/stage.dart';
import 'package:moteur_gr/features/planning/providers/planned_days_provider.dart';
import 'package:moteur_gr/features/planning/providers/planning_provider.dart';
import 'package:moteur_gr/features/trail/providers/stages_provider.dart';
import 'package:moteur_gr/features/trek/providers/gps_providers.dart';
import 'package:moteur_gr/features/trek/providers/itinerary_providers.dart';

/// Tests de [itineraryProvider] APRES l'unification R3 (#100122 / D2).
///
/// L'itineraire DERIVE desormais de la SOURCE UNIQUE des jours
/// ([plannedDaysProvider] / [selectedDurationProvider]) : il n'a plus son propre
/// calcul par plafond km/heures. On verifie donc que :
///   - l'itineraire reflete le PROGRAMME (meme nombre de jours) ;
///   - REDUIRE les jours dans le Programme met a jour l'itineraire (le bug R3
///     etait justement que l'itineraire ne suivait pas) ;
///   - le sens de marche reste applique (via [plannedDaysProvider]).
void main() {
  StageModel makeStage(int num, double km, int gain) => StageModel(
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

  // 5 etapes courtes (memes donnees que planned_days_provider_test) : la duree
  // pilote la repartition (5 jours = 1 etape/jour ; 3 jours = regroupements).
  final testStages = [
    makeStage(1, 8.0, 400),
    makeStage(2, 10.0, 500),
    makeStage(3, 9.0, 450),
    makeStage(4, 7.0, 350),
    makeStage(5, 11.0, 550),
  ];

  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      overrides: [
        trailConfigProvider.overrideWithValue(testTrailConfig),
        // SOURCE des etapes du Programme (family, keyee par trailId).
        stagesProvider('test-trail')
            .overrideWith((ref) => Future.value(testStages)),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('itineraryProvider — derive de la source unique des jours (R3)', () {
    test('l itineraire reflete le PROGRAMME (meme nombre de jours de marche)',
        () async {
      final container = makeContainer();
      await container.read(stagesProvider('test-trail').future);
      // 5 jours de marche (1 etape / jour).
      container.read(selectedDurationProvider.notifier).set(5);
      // Laisse le Programme se composer sur la duree choisie.
      container.read(plannedDaysProvider('test-trail'));

      final days = await container.read(itineraryProvider.future);

      // 5 jours, toutes les etapes distribuees, dayNumber 1-indexe et croissant.
      expect(days.length, 5);
      final totalStages = days.fold<int>(0, (s, d) => s + d.stageCount);
      expect(totalStages, 5);
      for (var i = 0; i < days.length; i++) {
        expect(days[i].dayNumber, i + 1);
      }
      // Chaque jour de marche porte des totaux > 0 (distance / D+ / duree).
      for (final d in days) {
        expect(d.stages, isNotEmpty);
        expect(d.totalDistance, greaterThan(0));
        expect(d.totalElevation, greaterThan(0));
        expect(d.estimatedHours, greaterThan(0));
      }
    });

    test('REDUIRE les jours dans le Programme met a jour l itineraire (R3)',
        () async {
      final container = makeContainer();
      await container.read(stagesProvider('test-trail').future);

      // Depart : 5 jours -> itineraire a 5 jours.
      container.read(selectedDurationProvider.notifier).set(5);
      container.read(plannedDaysProvider('test-trail'));
      final before = await container.read(itineraryProvider.future);
      expect(before.length, 5);

      // Reduire a 3 jours (le geste que Chris fait dans le Programme).
      container.read(selectedDurationProvider.notifier).set(3);

      // L'ITINERAIRE SUIT : il passe a 3 jours (avant R3 il restait fige).
      final after = await container.read(itineraryProvider.future);
      expect(after.length, 3);
      // Toutes les etapes restent presentes (regroupees, pas perdues).
      final totalStages = after.fold<int>(0, (s, d) => s + d.stageCount);
      expect(totalStages, 5);
      // La distance totale est conservee (meme parcours, moins de jours).
      double totalKm(List days) =>
          days.fold<double>(0, (s, d) => s + (d.totalDistance as double));
      expect(totalKm(after), closeTo(totalKm(before), 0.001));
    });

    test('un JOUR DE REPOS ajoute au Programme apparait dans l itineraire',
        () async {
      final container = makeContainer();
      await container.read(stagesProvider('test-trail').future);
      container.read(selectedDurationProvider.notifier).set(5);

      final notifier = container.read(plannedDaysProvider('test-trail').notifier)
        ..addRestDay(0); // repos apres le jour 1

      final days = await container.read(itineraryProvider.future);
      // 5 jours de marche + 1 repos = 6 jours dans l'itineraire.
      expect(days.length, 6);
      // Le jour de repos = un jour sans etape (l'ecran affiche « repos »).
      expect(days.where((d) => d.stageCount == 0).length, 1);
      // Non-regression : le notifier porte bien le repos.
      expect(notifier.hasManualRestDays, isTrue);
    });
  });

  group('itineraryProvider — sens de marche (via la source unique)', () {
    test('inverser le sens inverse l ORDRE des jours de l itineraire', () async {
      final container = makeContainer();
      await container.read(stagesProvider('test-trail').future);
      container.read(selectedDurationProvider.notifier).set(5);
      container.read(plannedDaysProvider('test-trail'));

      // Sens de reference (1er code 'NS') : Jour 1 = etape 1.
      final forward = await container.read(itineraryProvider.future);
      expect(forward.first.stages.first.stageNumber, 1);

      // Inverser le sens (comme l'ancien controle #12b) : 'SN'.
      container.read(selectedDirectionProvider.notifier).state = 'SN';

      // L'itineraire (via le Programme) s'inverse : Jour 1 = derniere etape.
      final reversed = await container.read(itineraryProvider.future);
      expect(reversed.first.stages.first.stageNumber, 5);
      // Distance totale conservee (meme parcours, sens oppose).
      double totalKm(List days) =>
          days.fold<double>(0, (s, d) => s + (d.totalDistance as double));
      expect(totalKm(reversed), closeTo(totalKm(forward), 0.001));
    });
  });
}
