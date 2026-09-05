import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/config/test_trail_config.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/core/models/stage.dart';
import 'package:moteur_gr/features/planning/providers/planned_days_provider.dart';
import 'package:moteur_gr/features/planning/providers/planning_provider.dart';
import 'package:moteur_gr/features/trail/providers/stages_provider.dart';

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
}
