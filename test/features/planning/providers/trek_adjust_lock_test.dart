import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/config/test_trail_config.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/core/models/stage.dart';
import 'package:moteur_gr/features/planning/domain/trek_edit_lock.dart';
import 'package:moteur_gr/features/planning/providers/planned_days_provider.dart';
import 'package:moteur_gr/features/planning/providers/planning_provider.dart';
import 'package:moteur_gr/features/planning/providers/trek_edit_lock_provider.dart';
import 'package:moteur_gr/features/trail/providers/stages_provider.dart';

/// R12 (LOT L9) — MODIFIER LA RANDO EN COURS : preuve de la regle metier.
///
/// Regle imposee par Christophe : pendant la rando, le randonneur ne peut
/// toucher QUE les jours et etapes NON FAITS ; ce qui est deja realise est
/// FIGE, et AUCUNE inversion de l'ordre des etapes n'est possible.
///
/// Ces tests attaquent le DOMAINE ([PlannedDaysNotifier]), pas l'ecran : la
/// garde doit tenir quelle que soit la porte d'entree (ecran « Adapter
/// l'itineraire » de la phase Randonner, mais aussi ecran « Programme » de la
/// preparation, qui reste joignable pendant la rando).
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

  // 5 etapes courtes : la somme de 2 etapes adjacentes reste < 16 h, donc le
  // regroupement n'est jamais bloque par la duree -> si un merge est refuse,
  // c'est bien a cause du verrou R12 et de rien d'autre.
  final testStages = [
    makeStage(1, 8.0, 400),
    makeStage(2, 10.0, 500),
    makeStage(3, 9.0, 450),
    makeStage(4, 7.0, 350),
    makeStage(5, 11.0, 550),
  ];

  /// Conteneur avec un verrou de rando IMPOSE (aucune session reelle, aucune
  /// base : on teste la regle, pas la plomberie GPS).
  ProviderContainer makeContainer({TrekEditLock lock = TrekEditLock.none}) {
    return ProviderContainer(
      overrides: [
        trailConfigProvider.overrideWithValue(testTrailConfig),
        stagesProvider('test-trail')
            .overrideWith((ref) => Future.value(testStages)),
        trekEditLockProvider.overrideWithValue(lock),
      ],
    );
  }

  /// Programme a 5 jours mono-etape, verrou applique.
  Future<(ProviderContainer, PlannedDaysNotifier)> setUpProgram({
    required TrekEditLock lock,
  }) async {
    final container = makeContainer(lock: lock);
    await container.read(stagesProvider('test-trail').future);
    container.read(selectedDurationProvider.notifier).set(5);
    final notifier = container.read(plannedDaysProvider('test-trail').notifier);
    return (container, notifier);
  }

  /// Signature lisible d'un programme : les numeros d'etape par jour
  /// (`R` = jour de repos). Sert a prouver qu'un etat n'a PAS bouge.
  List<String> signature(List<dynamic> days) => [
        for (final d in days)
          d.isRestDay
              ? 'R'
              : (d.stages as List<StageModel>)
                  .map((s) => s.stageNumber)
                  .join('+'),
      ];

  group('R12 — perimetre du verrou', () {
    test('Sans rando demarree, le programme reste ENTIEREMENT editable', () async {
      final (container, notifier) =
          await setUpProgram(lock: TrekEditLock.none);

      expect(notifier.lockedDayCount, 0, reason: 'rien de fait, rien de fige');
      expect(notifier.canReorder, isTrue,
          reason: 'en preparation on peut encore tout reorganiser');
      expect(notifier.canSplit(0), isFalse, reason: 'jour mono-etape');
      expect(notifier.canMergeWithNext(0), isTrue);

      // Non-regression du flux amont : la reorganisation fonctionne toujours.
      notifier.reorder(0, 3);
      expect(signature(container.read(plannedDaysProvider('test-trail'))),
          ['2', '3', '1', '4', '5']);

      container.dispose();
    });

    test('Les jours contenant une etape FAITE sont figes, les suivants non',
        () async {
      // Etapes 1 et 2 marchees -> jours 1 et 2 figes (5 jours mono-etape).
      final (container, notifier) = await setUpProgram(
        lock: const TrekEditLock(
          trekStarted: true,
          doneStageIds: {'1', '2'},
        ),
      );

      expect(notifier.lockedDayCount, 2);
      expect(notifier.isDayLocked(0), isTrue);
      expect(notifier.isDayLocked(1), isTrue);
      expect(notifier.isDayLocked(2), isFalse);
      expect(notifier.isStageDone(2), isTrue);
      expect(notifier.isStageDone(3), isFalse);

      container.dispose();
    });
  });

  group('R12 — un jour / une etape DEJA FAIT ne peut pas etre modifie', () {
    test('REGROUPER est refuse sur un jour deja marche (raison « locked »)',
        () async {
      final (container, notifier) = await setUpProgram(
        lock: const TrekEditLock(trekStarted: true, doneStageIds: {'1', '2'}),
      );
      final before = signature(container.read(plannedDaysProvider('test-trail')));

      expect(notifier.canMergeWithNext(0), isFalse);
      expect(notifier.mergeBlockedReason(0), 'locked');
      expect(notifier.canMergeWithNext(1), isFalse);
      expect(notifier.mergeBlockedReason(1), 'locked');

      // Appel FORCE : la garde tient meme si l'UI etait contournee.
      notifier.mergeWithNext(0);
      notifier.mergeWithNext(1);

      expect(signature(container.read(plannedDaysProvider('test-trail'))), before,
          reason: 'aucun jour deja marche ne doit avoir bouge');
      container.dispose();
    });

    test('SEPARER est refuse sur un jour deja marche, meme multi-etapes',
        () async {
      // 1) En preparation : on regroupe les etapes 1+2 sur le jour 1.
      final (container, notifier) =
          await setUpProgram(lock: TrekEditLock.none);
      notifier.mergeWithNext(0);
      expect(signature(container.read(plannedDaysProvider('test-trail'))).first,
          '1+2');
      expect(notifier.canSplit(0), isTrue,
          reason: 'avant depart, un jour a 2 etapes est separable');

      // 2) Le randonneur part et marche ce jour-la : il se fige.
      notifier.applyEditLock(
        const TrekEditLock(trekStarted: true, doneStageIds: {'1', '2'}),
      );
      final before = signature(container.read(plannedDaysProvider('test-trail')));

      expect(notifier.lockedDayCount, 1);
      expect(notifier.canSplit(0), isFalse);
      expect(notifier.splitBlockedReason(0), 'locked');

      notifier.splitDay(0);
      expect(signature(container.read(plannedDaysProvider('test-trail'))), before,
          reason: 'un jour deja marche ne se separe pas');

      container.dispose();
    });

    test('Un jour de REPOS deja passe ne peut pas etre supprime', () async {
      // Repos insere apres le jour 1 en preparation.
      final (container, notifier) =
          await setUpProgram(lock: TrekEditLock.none);
      notifier.addRestDay(0);
      expect(signature(container.read(plannedDaysProvider('test-trail'))),
          ['1', 'R', '2', '3', '4', '5']);

      // Le randonneur a marche les etapes 1 et 2 : le repos (index 1) est
      // derriere lui -> jours 0,1,2 figes.
      notifier.applyEditLock(
        const TrekEditLock(trekStarted: true, doneStageIds: {'1', '2'}),
      );
      expect(notifier.lockedDayCount, 3);
      expect(notifier.isDayLocked(1), isTrue);

      notifier.removeRestDay(1);
      expect(signature(container.read(plannedDaysProvider('test-trail'))),
          ['1', 'R', '2', '3', '4', '5'],
          reason: 'un repos deja pris ne s efface pas du programme');

      container.dispose();
    });

    test('Ajouter un REPOS dans la partie deja marchee est refuse', () async {
      final (container, notifier) = await setUpProgram(
        lock: const TrekEditLock(trekStarted: true, doneStageIds: {'1', '2'}),
      );
      final before = signature(container.read(plannedDaysProvider('test-trail')));

      expect(notifier.canAddRestDayAfter(0), isFalse);
      notifier.addRestDay(0);
      expect(signature(container.read(plannedDaysProvider('test-trail'))), before,
          reason: 'on n insere pas un repos entre deux jours deja marches');

      // En revanche, apres le DERNIER jour fige, le repos tombe dans le futur.
      expect(notifier.canAddRestDayAfter(1), isTrue);
      notifier.addRestDay(1);
      expect(signature(container.read(plannedDaysProvider('test-trail'))),
          ['1', '2', 'R', '3', '4', '5']);

      container.dispose();
    });

    test('REPLANIFIER ne reecrit pas les jours deja marches', () async {
      final (container, notifier) = await setUpProgram(
        lock: const TrekEditLock(trekStarted: true, doneStageIds: {'1', '2'}),
      );

      notifier.regeneratePreservingRestDays();
      final after = signature(container.read(plannedDaysProvider('test-trail')));

      expect(after.take(2).toList(), ['1', '2'],
          reason: 'le passe marche est recopie tel quel');
      expect(after.skip(2).join('+').contains('1'), isFalse,
          reason: 'une etape deja marchee ne repasse pas dans le futur');

      container.dispose();
    });
  });

  group('R12 — aucune inversion de l ordre des etapes', () {
    test('REORGANISER est refuse des que le trek est demarre', () async {
      final (container, notifier) = await setUpProgram(
        lock: const TrekEditLock(trekStarted: true, doneStageIds: {'1', '2'}),
      );
      final before = signature(container.read(plannedDaysProvider('test-trail')));
      expect(before, ['1', '2', '3', '4', '5']);
      expect(notifier.canReorder, isFalse);

      // Toutes les inversions imaginables : depuis le passe, vers le passe,
      // entre deux jours a venir. Aucune ne doit passer.
      notifier.reorder(4, 0); // ramener la derniere etape en premier
      notifier.reorder(0, 4); // repousser une etape deja marchee a la fin
      notifier.reorder(3, 2); // inverser deux jours pourtant tous deux a venir

      expect(signature(container.read(plannedDaysProvider('test-trail'))), before,
          reason: 'une fois parti, l ordre des etapes est gele');
      container.dispose();
    });

    test('REORGANISER est refuse meme si aucune etape n est encore terminee',
        () async {
      // Cas limite : trek demarre a l instant, rien de marche. Le passe est
      // vide, mais l ordre est deja engage -> pas d inversion.
      final (container, notifier) = await setUpProgram(
        lock: const TrekEditLock(trekStarted: true),
      );
      expect(notifier.lockedDayCount, 0);
      expect(notifier.canReorder, isFalse);

      notifier.reorder(4, 0);
      expect(signature(container.read(plannedDaysProvider('test-trail'))),
          ['1', '2', '3', '4', '5']);
      container.dispose();
    });
  });

  group('R12 — la partie NON FAITE reste bien modifiable', () {
    test('Regrouper / separer / repos fonctionnent sur les jours a venir',
        () async {
      final (container, notifier) = await setUpProgram(
        lock: const TrekEditLock(trekStarted: true, doneStageIds: {'1', '2'}),
      );

      // Regrouper les jours 3 et 4 (a venir).
      expect(notifier.canMergeWithNext(2), isTrue);
      expect(notifier.mergeBlockedReason(2), isNull);
      notifier.mergeWithNext(2);
      expect(signature(container.read(plannedDaysProvider('test-trail'))),
          ['1', '2', '3+4', '5']);

      // Puis le reseparer : c'est un jour a venir, il reste libre.
      expect(notifier.canSplit(2), isTrue);
      notifier.splitDay(2);
      expect(signature(container.read(plannedDaysProvider('test-trail'))),
          ['1', '2', '3', '4', '5']);

      // Et y inserer un jour de repos.
      notifier.addRestDay(3);
      expect(signature(container.read(plannedDaysProvider('test-trail'))),
          ['1', '2', '3', '4', 'R', '5']);

      // Le passe marche n a pas bouge d un pouce pendant tout ca.
      expect(notifier.lockedDayCount, 2);
      container.dispose();
    });
  });
}
