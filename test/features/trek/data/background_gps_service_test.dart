import 'dart:async';

import 'package:battery_plus/battery_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:moteur_gr/features/trek/data/background_gps_service.dart';

/// Mock Battery qui retourne un niveau de batterie configurable.
class MockBattery extends Battery {
  MockBattery({required this.level});

  final int level;

  @override
  Future<int> get batteryLevel async => level;
}

/// Helper : cree une Position de test avec les champs requis.
Position _fakePosition({
  required double lat,
  required double lng,
  double altitude = 0,
}) {
  return Position(
    latitude: lat,
    longitude: lng,
    altitude: altitude,
    accuracy: 5.0,
    altitudeAccuracy: 5.0,
    heading: 0,
    headingAccuracy: 0,
    speed: 0,
    speedAccuracy: 0,
    timestamp: DateTime.now(),
  );
}

void main() {
  group('BackgroundGpsService intervalle adaptatif', () {
    test('batterie basse (<20%) -> intervalle 30s au lieu de 15s', () async {
      // Arrange: batterie a 15%
      final mockBattery = MockBattery(level: 15);

      final service = BackgroundGpsService(
        battery: mockBattery,
        getPositionStream: ({required LocationSettings locationSettings}) {
          return Stream.fromIterable([
            _fakePosition(lat: 42.0, lng: 9.0),
          ]);
        },
      );

      // Assert: intervalle initial = 15s
      expect(service.currentIntervalMs, equals(kNormalIntervalMs));

      // Act: forcer la mise a jour de intervalle
      await service.updateInterval();

      // Assert: intervalle passe a 30s
      expect(service.currentIntervalMs, equals(kLowBatteryIntervalMs));
    });

    test('batterie normale (>=20%) -> intervalle reste 15s', () async {
      // Arrange: batterie a 80%
      final mockBattery = MockBattery(level: 80);

      final service = BackgroundGpsService(
        battery: mockBattery,
        getPositionStream: ({required LocationSettings locationSettings}) {
          return Stream.fromIterable([
            _fakePosition(lat: 42.0, lng: 9.0),
          ]);
        },
      );

      // Act
      await service.updateInterval();

      // Assert: intervalle reste 15s
      expect(service.currentIntervalMs, equals(kNormalIntervalMs));
    });

    test('batterie exactement 20% -> intervalle 15s (seuil non inclus)', () async {
      // Arrange: batterie exactement au seuil
      final mockBattery = MockBattery(level: 20);

      final service = BackgroundGpsService(
        battery: mockBattery,
        getPositionStream: ({required LocationSettings locationSettings}) {
          return Stream.fromIterable([
            _fakePosition(lat: 42.0, lng: 9.0),
          ]);
        },
      );

      // Act
      await service.updateInterval();

      // Assert: 20% >= 20% donc intervalle normal
      expect(service.currentIntervalMs, equals(kNormalIntervalMs));
    });

    test('batterie a 19% -> intervalle 30s', () async {
      // Arrange: batterie juste sous le seuil
      final mockBattery = MockBattery(level: 19);

      final service = BackgroundGpsService(
        battery: mockBattery,
        getPositionStream: ({required LocationSettings locationSettings}) {
          return Stream.fromIterable([
            _fakePosition(lat: 42.0, lng: 9.0),
          ]);
        },
      );

      // Act
      await service.updateInterval();

      // Assert: 19% < 20% donc intervalle batterie basse
      expect(service.currentIntervalMs, equals(kLowBatteryIntervalMs));
    });

    test('constantes correctement definies', () {
      expect(kNormalIntervalMs, equals(15000));
      expect(kLowBatteryIntervalMs, equals(30000));
      expect(kLowBatteryThreshold, equals(20));
      expect(kBackgroundPauseMinutes, equals(30));
    });
  });
}
