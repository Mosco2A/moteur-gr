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
