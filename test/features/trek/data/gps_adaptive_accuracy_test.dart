import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:moteur_gr/features/trek/data/gps_service.dart';

/// Position de test avec vitesse parametrable (m/s).
Position _pos({double speed = 0, double lat = 42, double lng = 9}) {
  return Position(
    latitude: lat,
    longitude: lng,
    altitude: 0,
    accuracy: 5,
    altitudeAccuracy: 5,
    heading: 0,
    headingAccuracy: 0,
    speed: speed,
    speedAccuracy: 0,
    timestamp: DateTime.now(),
  );
}

/// Tests E5.2b (maj F6A-03) — precision GPS adaptative 3 paliers + filtre 10 m.
void main() {
  group('classifyMovement — hysteresis', () {
    test('repos : vitesse nulle reste repos', () {
      expect(GpsService.classifyMovement(0, GpsAccuracyMode.resting),
          GpsAccuracyMode.resting);
    });

    test('repos -> mouvement au-dela du seuil haut', () {
      expect(GpsService.classifyMovement(1.5, GpsAccuracyMode.resting),
          GpsAccuracyMode.moving);
    });

    test('repos : vitesse intermediaire -> walking (palier F6A-03)', () {
      // 0.7 m/s : entre 0.4 et 1.0 -> palier intermediaire walking (avant
      // F6A-03 cette bande restait au repos ; le palier balanced est ajoute).
      expect(GpsService.classifyMovement(0.7, GpsAccuracyMode.resting),
          GpsAccuracyMode.walking);
    });

    test('mouvement -> repos en deca du seuil bas', () {
      expect(GpsService.classifyMovement(0.2, GpsAccuracyMode.moving),
          GpsAccuracyMode.resting);
    });

    test('mouvement : vitesse intermediaire -> walking (hysteresis F6A-03)', () {
      // Depuis moving, a 0.7 m/s on redescend vers le palier walking (et non
      // jusqu au repos) : descente progressive via le palier intermediaire.
      expect(GpsService.classifyMovement(0.7, GpsAccuracyMode.moving),
          GpsAccuracyMode.walking);
    });

    test('vitesse non finie traitee comme repos', () {
      expect(GpsService.classifyMovement(double.nan, GpsAccuracyMode.moving),
          GpsAccuracyMode.resting);
    });
  });

  group('mapping precision', () {
    test('mouvement -> high, repos -> low (extremes preserves F6A-03)', () {
      expect(GpsService.accuracyForMode(GpsAccuracyMode.moving),
          LocationAccuracy.high);
      expect(GpsService.accuracyForMode(GpsAccuracyMode.resting),
          LocationAccuracy.low);
    });

    test('settingsForMode conserve le distanceFilter 10 m', () {
      expect(GpsService.settingsForMode(GpsAccuracyMode.moving).distanceFilter,
          10);
      expect(GpsService.settingsForMode(GpsAccuracyMode.resting).distanceFilter,
          10);
      expect(GpsService.distanceFilterMeters, 10);
    });
  });

  group('getPositionStream — switch precision mouvement/repos detecte', () {
    test('demarre basse precision, haute en mouvement, basse au repos',
        () async {
      final accuracies = <LocationAccuracy>[];
      final controllers = <StreamController<Position>>[];

      final service = GpsService(
        getPositionStream: ({required LocationSettings locationSettings}) {
          accuracies.add(locationSettings.accuracy);
          final c = StreamController<Position>();
          controllers.add(c);
          return c.stream;
        },
      );

      final received = <Position>[];
      final sub = service.getPositionStream().listen(received.add);

      // onListen -> 1ere souscription, regime repos par defaut -> low.
      await Future<void>.delayed(Duration.zero);
      expect(accuracies, [LocationAccuracy.low]);

      // Mouvement detecte -> re-souscription en haute precision.
      controllers.last.add(_pos(speed: 5.0));
      await Future<void>.delayed(Duration.zero);
      expect(accuracies, [LocationAccuracy.low, LocationAccuracy.high]);

      // Retour au repos -> re-souscription en basse precision.
      controllers.last.add(_pos(speed: 0.0));
      await Future<void>.delayed(Duration.zero);
      expect(accuracies,
          [LocationAccuracy.low, LocationAccuracy.high, LocationAccuracy.low]);

      // Les positions ont bien ete transmises au consommateur.
      expect(received.length, 2);

      await sub.cancel();
      for (final c in controllers) {
        await c.close();
      }
    });

    test('aucune re-souscription tant que le regime ne change pas', () async {
      final accuracies = <LocationAccuracy>[];
      final controllers = <StreamController<Position>>[];

      final service = GpsService(
        getPositionStream: ({required LocationSettings locationSettings}) {
          accuracies.add(locationSettings.accuracy);
          final c = StreamController<Position>();
          controllers.add(c);
          return c.stream;
        },
      );

      final sub = service.getPositionStream().listen((_) {});
      await Future<void>.delayed(Duration.zero);

      // Trois positions sous le seuil haut -> reste au repos, pas de switch.
      controllers.last
        ..add(_pos(speed: 0.0))
        ..add(_pos(speed: 0.1))
        ..add(_pos(speed: 0.3));
      await Future<void>.delayed(Duration.zero);

      expect(accuracies, [LocationAccuracy.low]);
      expect(controllers.length, 1);

      await sub.cancel();
      for (final c in controllers) {
        await c.close();
      }
    });
  });
}
