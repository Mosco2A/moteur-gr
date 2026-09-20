import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moteur_gr/core/config/test_trail_config.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/core/models/stage.dart';
import 'package:moteur_gr/features/planning/domain/trek_edit_lock.dart';
import 'package:moteur_gr/features/planning/presentation/trek_adjust_screen.dart';
import 'package:moteur_gr/features/planning/providers/planned_days_provider.dart';
import 'package:moteur_gr/features/planning/providers/planning_provider.dart';
import 'package:moteur_gr/features/planning/providers/trek_edit_lock_provider.dart';
import 'package:moteur_gr/features/trail/providers/stages_provider.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

/// Ecran « Adapter l'itineraire » (R12, LOT L9) — preuve cote INTERFACE.
///
/// Le test de domaine (`trek_adjust_lock_test.dart`) prouve que la regle est
/// infranchissable. Celui-ci prouve que l'ECRAN la RESPECTE et la MONTRE :
///   * les jours deja marches sont rendus, verrouilles, sans aucune action ;
///   * les jours a venir portent bien les trois actions du geste GR20 ;
///   * il n'y a AUCUNE poignee de glissement / liste reordonnable — l'ordre des
///     etapes ne se touche pas depuis cet ecran.
void main() {
  StageModel makeStage(int num) => StageModel(
        trailId: 'test-trail',
        stageNumber: num,
        name: 'Etape $num - Refuge $num',
        distanceKm: 10.0,
        elevationGainM: 500,
        elevationLossM: 400,
        startLat: 42.0,
        startLng: 9.0,
        endLat: 42.1,
        endLng: 9.1,
      );

  final testStages = [for (var i = 1; i <= 5; i++) makeStage(i)];

  List<Override> overridesWith(TrekEditLock lock) => [
        trailConfigProvider.overrideWithValue(testTrailConfig),
        stagesProvider('test-trail')
            .overrideWith((ref) => Future.value(testStages)),
        trekEditLockProvider.overrideWithValue(lock),
      ];

  Widget wrap() => MaterialApp.router(
        routerConfig: GoRouter(
          initialLocation: '/adjust',
          routes: [
            GoRoute(
              path: '/adjust',
              builder: (_, __) => const TrekAdjustScreen(trailId: 'test-trail'),
            ),
          ],
        ),
      );

  /// Monte l'ecran avec un verrou donne, sur une surface haute pour que toutes
  /// les cartes de jour soient rendues (pas de culling de viewport).
  Future<ProviderContainer> pumpScreen(
    WidgetTester tester, {
    required TrekEditLock lock,
  }) async {
    tester.view.physicalSize = const Size(1200, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer(overrides: overridesWith(lock));
    addTearDown(container.dispose);
    await container.read(stagesProvider('test-trail').future);
    container.read(selectedDurationProvider.notifier).set(5);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: wrap()),
    );
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets(
      'un jour DEJA MARCHE est rendu verrouille et sans aucune action',
      (tester) async {
    await pumpScreen(
      tester,
      lock: const TrekEditLock(trekStarted: true, doneStageIds: {'1', '2'}),
    );

    // Les deux sections sont annoncees : ce qui est fait / ce qui reste.
    expect(find.text(t.programme.inTrek.doneSection), findsOneWidget);
    expect(find.text(t.programme.inTrek.upcomingSection), findsOneWidget);

    // Les 2 jours marches portent le badge « Fait » — et eux seuls.
    expect(find.text(t.programme.inTrek.doneBadge), findsNWidgets(2));

    // Les actions d'edition n'existent QUE sur les 3 jours a venir : aucun
    // chip, meme grise, sur un jour fige.
    expect(find.text(t.programme.actions.merge), findsNWidgets(3));
    expect(find.text(t.programme.actions.split), findsNWidgets(3));
    expect(find.text(t.programme.actions.rest), findsNWidgets(3));
  });

  testWidgets('AUCUNE inversion possible : pas de liste reordonnable',
      (tester) async {
    await pumpScreen(
      tester,
      lock: const TrekEditLock(trekStarted: true, doneStageIds: {'1'}),
    );

    expect(find.byType(ReorderableListView), findsNothing,
        reason: 'l ordre des etapes ne se glisse pas une fois parti');
    expect(find.byIcon(Icons.drag_handle), findsNothing,
        reason: 'aucune poignee de glissement ne doit etre offerte');
  });

  testWidgets('taper REGROUPER modifie reellement le programme partage',
      (tester) async {
    final container = await pumpScreen(
      tester,
      lock: const TrekEditLock(trekStarted: true, doneStageIds: {'1', '2'}),
    );

    expect(container.read(plannedDaysProvider('test-trail')).length, 5);

    // Premier « Regrouper » a l'ecran = celui du 1er jour A VENIR (jour 3) :
    // les jours figes n'en ont pas. Il fusionne les jours 3 et 4.
    await tester.tap(find.text(t.programme.actions.merge).first);
    await tester.pumpAndSettle();

    final days = container.read(plannedDaysProvider('test-trail'));
    expect(days.length, 4, reason: 'un jour a venir de moins');
    // Le passe marche est intact : jour 1 = etape 1, jour 2 = etape 2.
    expect(days[0].stages.single.stageNumber, 1);
    expect(days[1].stages.single.stageNumber, 2);
    // Le jour regroupe porte bien les etapes 3 et 4, dans l'ordre.
    expect(days[2].stages.map((s) => s.stageNumber).toList(), [3, 4]);
  });

  testWidgets('tout marche : plus rien a adapter, message explicite',
      (tester) async {
    await pumpScreen(
      tester,
      lock: const TrekEditLock(
        trekStarted: true,
        doneStageIds: {'1', '2', '3', '4', '5'},
      ),
    );

    expect(find.text(t.programme.inTrek.allDone), findsOneWidget);
    expect(find.text(t.programme.actions.merge), findsNothing);
  });
}
