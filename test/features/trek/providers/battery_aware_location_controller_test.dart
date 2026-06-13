import 'dart:async';

import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moteur_gr/core/analytics/analytics_service.dart';
import 'package:moteur_gr/features/trek/data/gps_service.dart';
import 'package:moteur_gr/features/trek/providers/battery_aware_location_controller.dart';

/// Fake Battery : niveau et flux d'etat pilotables.
class _FakeBattery implements Battery {
  _FakeBattery({this.level = 100});
  int level;
  final StreamController<BatteryState> _ctrl =
      StreamController<BatteryState>.broadcast();

  @override
  Future<int> get batteryLevel async => level;

  @override
  Stream<BatteryState> get onBatteryStateChanged => _ctrl.stream;

  void emit(BatteryState s) => _ctrl.add(s);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Fake Connectivity : resultat initial + flux pilotable.
class _FakeConnectivity implements Connectivity {
  _FakeConnectivity({this.current = ConnectivityResult.wifi});
  ConnectivityResult current;
  final StreamController<ConnectivityResult> _ctrl =
      StreamController<ConnectivityResult>.broadcast();

  @override
  Future<ConnectivityResult> checkConnectivity() async => current;

  @override
  Stream<ConnectivityResult> get onConnectivityChanged => _ctrl.stream;

  void emit(ConnectivityResult r) => _ctrl.add(r);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ProviderContainer _container(BatteryAwareLocationController controller) {
  return ProviderContainer(
    overrides: [
      batteryAwareLocationControllerProvider.overrideWith(() => controller),
    ],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BatteryAwareLocationController — etat initial', () {
    test('demarre en walking, deferSync false, foreground', () {
      final controller = BatteryAwareLocationController(
        battery: _FakeBattery(),
        connectivity: _FakeConnectivity(),
        analytics: AnalyticsService.disabled(),
      );
      final container = _container(controller);
      addTearDown(container.dispose);

      final state =
          container.read(batteryAwareLocationControllerProvider);
      expect(state.mode, GpsAccuracyMode.walking);
      expect(state.deferSync, isFalse);
      expect(state.isForeground, isTrue);
    });
  });

  group('BatteryAwareLocationController — connectivite (zone blanche)', () {
    test('connectivity none au demarrage -> deferSync true', () async {
      final controller = BatteryAwareLocationController(
        battery: _FakeBattery(level: 80),
        connectivity: _FakeConnectivity(current: ConnectivityResult.none),
        analytics: AnalyticsService.disabled(),
      );
      final container = _container(controller);
      addTearDown(container.dispose);
      container.read(batteryAwareLocationControllerProvider);

      await controller.start();

      expect(
        container.read(batteryAwareLocationControllerProvider).deferSync,
        isTrue,
      );
    });

    test('passage online -> offline bascule deferSync', () async {
      final connectivity = _FakeConnectivity(current: ConnectivityResult.wifi);
      final controller = BatteryAwareLocationController(
        battery: _FakeBattery(level: 80),
        connectivity: connectivity,
        analytics: AnalyticsService.disabled(),
      );
      final container = _container(controller);
      addTearDown(container.dispose);
      container.read(batteryAwareLocationControllerProvider);
      await controller.start();
      expect(
        container.read(batteryAwareLocationControllerProvider).deferSync,
        isFalse,
      );

      connectivity.emit(ConnectivityResult.none);
      await Future<void>.delayed(Duration.zero);

      expect(
        container.read(batteryAwareLocationControllerProvider).deferSync,
        isTrue,
      );
    });
  });

  group('BatteryAwareLocationController — regime foreground/background', () {
    test('foreground : le regime detecte est applique tel quel (high)', () {
      final controller = BatteryAwareLocationController(
        battery: _FakeBattery(level: 90),
        connectivity: _FakeConnectivity(),
        analytics: AnalyticsService.disabled(),
      );
      final container = _container(controller);
      addTearDown(container.dispose);
      container.read(batteryAwareLocationControllerProvider);

      controller.onMovementRegime(GpsAccuracyMode.moving);

      expect(
        container.read(batteryAwareLocationControllerProvider).mode,
        GpsAccuracyMode.moving,
      );
    });

    test('background : high plafonne a walking (jamais high)', () {
      final controller = BatteryAwareLocationController(
        battery: _FakeBattery(level: 90),
        connectivity: _FakeConnectivity(),
        analytics: AnalyticsService.disabled(),
      );
      final container = _container(controller);
      addTearDown(container.dispose);
      container.read(batteryAwareLocationControllerProvider);

      // Passage en background.
      controller.didChangeAppLifecycleState(AppLifecycleState.paused);
      expect(
        container.read(batteryAwareLocationControllerProvider).isForeground,
        isFalse,
      );

      controller.onMovementRegime(GpsAccuracyMode.moving);
      expect(
        container.read(batteryAwareLocationControllerProvider).mode,
        GpsAccuracyMode.walking,
      );
    });

    test('retour foreground restaure le pilotage normal', () {
      final controller = BatteryAwareLocationController(
        battery: _FakeBattery(level: 90),
        connectivity: _FakeConnectivity(),
        analytics: AnalyticsService.disabled(),
      );
      final container = _container(controller);
      addTearDown(container.dispose);
      container.read(batteryAwareLocationControllerProvider);

      controller.didChangeAppLifecycleState(AppLifecycleState.paused);
      controller.didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(
        container.read(batteryAwareLocationControllerProvider).isForeground,
        isTrue,
      );
      controller.onMovementRegime(GpsAccuracyMode.moving);
      expect(
        container.read(batteryAwareLocationControllerProvider).mode,
        GpsAccuracyMode.moving,
      );
    });
  });

  group('BatteryAwareLocationController — batterie basse', () {
    test('batterie < 20% plafonne le regime a walking', () async {
      final controller = BatteryAwareLocationController(
        battery: _FakeBattery(level: 15),
        connectivity: _FakeConnectivity(),
        analytics: AnalyticsService.disabled(),
      );
      final container = _container(controller);
      addTearDown(container.dispose);
      container.read(batteryAwareLocationControllerProvider);

      // En foreground, on detecte high, mais batterie basse -> walking.
      controller.onMovementRegime(GpsAccuracyMode.moving);
      await controller.start(); // lit batteryLevel=15 -> plafonne

      final state = container.read(batteryAwareLocationControllerProvider);
      expect(state.batteryPct, 15);
      expect(state.mode, GpsAccuracyMode.walking);
    });
  });
}
