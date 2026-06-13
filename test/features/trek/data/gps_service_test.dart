import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:moteur_gr/features/trek/data/gps_service.dart';

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
  group('GpsService.requestPermission', () {
    test('service actif + permission denied -> demande -> granted', () async {
      final service = GpsService(
        isLocationServiceEnabled: () async => true,
        checkPermission: () async => LocationPermission.denied,
        requestPermission: () async => LocationPermission.whileInUse,
      );

      final result = await service.requestPermission();

      expect(result, equals(GpsPermissionResultValues.granted));
    });

    test('service actif + permission denied -> demande -> denied', () async {
      final service = GpsService(
        isLocationServiceEnabled: () async => true,
        checkPermission: () async => LocationPermission.denied,
        requestPermission: () async => LocationPermission.denied,
      );

      final result = await service.requestPermission();

      expect(result, equals(GpsPermissionResultValues.denied));
    });

    test('service actif + permission deniedForever', () async {
      final service = GpsService(
        isLocationServiceEnabled: () async => true,
        checkPermission: () async => LocationPermission.deniedForever,
      );

      final result = await service.requestPermission();

      expect(result, equals(GpsPermissionResultValues.deniedForever));
    });

    test('service desactive -> serviceDisabled', () async {
      final service = GpsService(
        isLocationServiceEnabled: () async => false,
      );

      final result = await service.requestPermission();

      expect(result, equals(GpsPermissionResultValues.serviceDisabled));
    });

    test('service actif + permission deja accordee -> granted', () async {
      final service = GpsService(
        isLocationServiceEnabled: () async => true,
        checkPermission: () async => LocationPermission.always,
      );

      final result = await service.requestPermission();

      expect(result, equals(GpsPermissionResultValues.granted));
    });
  });

  group('GpsService.classifyMovement (3 regimes + hysteresis, F6A-03)', () {
    test('repos: en deca de 0.4 m/s reste resting', () {
      expect(
        GpsService.classifyMovement(0.2, GpsAccuracyMode.resting),
        GpsAccuracyMode.resting,
      );
    });

    test('repos -> walking a la charniere 0.4 m/s', () {
      expect(
        GpsService.classifyMovement(0.4, GpsAccuracyMode.resting),
        GpsAccuracyMode.walking,
      );
      expect(
        GpsService.classifyMovement(0.8, GpsAccuracyMode.resting),
        GpsAccuracyMode.walking,
      );
    });

    test('repos -> moving directement si >= 1.0 m/s', () {
      expect(
        GpsService.classifyMovement(1.5, GpsAccuracyMode.resting),
        GpsAccuracyMode.moving,
      );
    });

    test('walking -> moving a 1.0 m/s', () {
      expect(
        GpsService.classifyMovement(1.0, GpsAccuracyMode.walking),
        GpsAccuracyMode.moving,
      );
    });

    test('walking reste walking dans la bande 0.4-1.0', () {
      expect(
        GpsService.classifyMovement(0.7, GpsAccuracyMode.walking),
        GpsAccuracyMode.walking,
      );
    });

    test('walking -> resting sous 0.4 m/s', () {
      expect(
        GpsService.classifyMovement(0.3, GpsAccuracyMode.walking),
        GpsAccuracyMode.resting,
      );
    });

    test('moving -> walking par hysteresis (descend a <=0.7, pas a 0.9)', () {
      // A 0.9 (entre 0.7 et 1.0) on RESTE moving : anti-flapping.
      expect(
        GpsService.classifyMovement(0.9, GpsAccuracyMode.moving),
        GpsAccuracyMode.moving,
      );
      // A 0.7 on redescend en walking.
      expect(
        GpsService.classifyMovement(0.7, GpsAccuracyMode.moving),
        GpsAccuracyMode.walking,
      );
    });

    test('moving -> resting si quasi arret (<=0.4)', () {
      expect(
        GpsService.classifyMovement(0.3, GpsAccuracyMode.moving),
        GpsAccuracyMode.resting,
      );
    });

    test('sequence complete resting->walking->moving->walking->resting', () {
      var mode = GpsAccuracyMode.resting;
      mode = GpsService.classifyMovement(0.5, mode); // -> walking
      expect(mode, GpsAccuracyMode.walking);
      mode = GpsService.classifyMovement(1.2, mode); // -> moving
      expect(mode, GpsAccuracyMode.moving);
      mode = GpsService.classifyMovement(0.6, mode); // -> walking (hysteresis)
      expect(mode, GpsAccuracyMode.walking);
      mode = GpsService.classifyMovement(0.1, mode); // -> resting
      expect(mode, GpsAccuracyMode.resting);
    });

    test('vitesse non finie traitee comme repos', () {
      expect(
        GpsService.classifyMovement(double.nan, GpsAccuracyMode.moving),
        GpsAccuracyMode.resting,
      );
    });
  });

  group('GpsService.accuracyForMode (3 paliers, F6A-03)', () {
    test('moving -> high', () {
      expect(
        GpsService.accuracyForMode(GpsAccuracyMode.moving),
        LocationAccuracy.high,
      );
    });
    test('walking -> medium (balanced)', () {
      expect(
        GpsService.accuracyForMode(GpsAccuracyMode.walking),
        LocationAccuracy.medium,
      );
    });
    test('resting -> low', () {
      expect(
        GpsService.accuracyForMode(GpsAccuracyMode.resting),
        LocationAccuracy.low,
      );
    });
  });

  group('GpsService.intervalForMode (espacement croissant, F6A-03)', () {
    test('intervalle resting > walking > moving (economie batterie)', () {
      final moving = GpsService.intervalForMode(GpsAccuracyMode.moving);
      final walking = GpsService.intervalForMode(GpsAccuracyMode.walking);
      final resting = GpsService.intervalForMode(GpsAccuracyMode.resting);
      expect(walking, greaterThan(moving));
      expect(resting, greaterThan(walking));
    });

    test('distanceFilter conserve a 10 m', () {
      expect(GpsService.distanceFilterMeters, 10);
    });
  });

  group('GpsService.getPositionStream', () {
    test('emet des positions depuis le stream mock', () async {
      final positions = [
        _fakePosition(lat: 42.0, lng: 9.0, altitude: 800),
        _fakePosition(lat: 42.001, lng: 9.001, altitude: 810),
        _fakePosition(lat: 42.002, lng: 9.002, altitude: 820),
      ];

      final service = GpsService(
        getPositionStream: ({required LocationSettings locationSettings}) {
          return Stream.fromIterable(positions);
        },
      );

      final emitted = await service.getPositionStream().toList();

      expect(emitted.length, equals(3));
      expect(emitted[0].latitude, closeTo(42.0, 0.001));
      expect(emitted[1].latitude, closeTo(42.001, 0.001));
      expect(emitted[2].altitude, closeTo(820, 1));
    });

    test('erreur stream -> loggee via ErrorHandler et propagee', () async {
      final service = GpsService(
        getPositionStream: ({required LocationSettings locationSettings}) {
          return Stream.error(
            StateError('GPS signal lost'),
            StackTrace.current,
          );
        },
      );

      expect(
        service.getPositionStream().first,
        throwsA(isA<StateError>()),
      );
    });
  });
}
