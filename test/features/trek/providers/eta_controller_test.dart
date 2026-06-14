import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/trek/domain/eta_service.dart';
import 'package:moteur_gr/features/trek/providers/eta_providers.dart';

EtaInput _input({double pace = 1.1, bool degraded = false}) => EtaInput(
      distanceToWaypointM: 1000,
      ascentToWaypointM: 50,
      descentToWaypointM: 0,
      distanceToStageEndM: 5000,
      ascentToStageEndM: 300,
      descentToStageEndM: 100,
      observedPaceMps: pace,
      gpsDegraded: degraded,
    );

/// Tests du contrôleur d'ETA piloté par événement (F6B-02).
///
/// Vérifie : recalcul SUR ÉVÉNEMENT, débounce (intervalle minimal), forçage qui
/// ignore le débounce, propagation de la confiance, et reset.
void main() {
  group('EtaController', () {
    test('état initial null (aucun événement)', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(etaControllerProvider), isNull);
    });

    test('onEvent calcule une estimation', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final ctrl = container.read(etaControllerProvider.notifier);

      final didCompute = ctrl.onEvent(_input(), now: DateTime(2026, 6, 14, 8));
      expect(didCompute, isTrue);

      final est = container.read(etaControllerProvider);
      expect(est, isNotNull);
      expect(est!.toNextWaypoint.inSeconds, greaterThan(0));
      expect(est.toStageEnd.inSeconds, greaterThan(est.toNextWaypoint.inSeconds));
    });

    test('débounce : un 2e événement trop rapproché est ignoré (pas forcé)', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final ctrl = container.read(etaControllerProvider.notifier);
      final t0 = DateTime(2026, 6, 14, 8);

      expect(ctrl.onEvent(_input(), now: t0), isTrue);
      // +10 s < 30 s -> ignoré.
      expect(
        ctrl.onEvent(_input(), now: t0.add(const Duration(seconds: 10))),
        isFalse,
      );
    });

    test('après l intervalle minimal, un nouvel événement recalcule', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final ctrl = container.read(etaControllerProvider.notifier);
      final t0 = DateTime(2026, 6, 14, 8);

      ctrl.onEvent(_input(), now: t0);
      expect(
        ctrl.onEvent(_input(), now: t0.add(const Duration(seconds: 31))),
        isTrue,
      );
    });

    test('force=true ignore le débounce (ex. waypoint franchi)', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final ctrl = container.read(etaControllerProvider.notifier);
      final t0 = DateTime(2026, 6, 14, 8);

      ctrl.onEvent(_input(), now: t0);
      expect(
        ctrl.onEvent(_input(),
            force: true, now: t0.add(const Duration(seconds: 5))),
        isTrue,
      );
    });

    test('confiance basse propagée quand GPS dégradé', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final ctrl = container.read(etaControllerProvider.notifier);

      ctrl.onEvent(_input(degraded: true), now: DateTime(2026, 6, 14, 8));
      expect(
        container.read(etaControllerProvider)!.confidence,
        EtaConfidence.low,
      );
    });

    test('reset remet l état à null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final ctrl = container.read(etaControllerProvider.notifier);

      ctrl.onEvent(_input(), now: DateTime(2026, 6, 14, 8));
      expect(container.read(etaControllerProvider), isNotNull);
      ctrl.reset();
      expect(container.read(etaControllerProvider), isNull);
    });
  });
}
