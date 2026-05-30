import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:moteur_gr/features/trek/data/stage_detection_service.dart';
import 'package:moteur_gr/features/trek/domain/models/stage.dart';

/// Helper : cree une Position de test avec les champs requis.
Position _fakePosition({
  required double lat,
  required double lng,
}) {
  return Position(
    latitude: lat,
    longitude: lng,
    altitude: 0,
    accuracy: 5.0,
    altitudeAccuracy: 5.0,
    heading: 0,
    headingAccuracy: 0,
    speed: 0,
    speedAccuracy: 0,
    timestamp: DateTime.now(),
  );
}

/// Helper : cree une Stage de test a partir de coordonnees.
Stage _fakeStage({
  required String id,
  required double startLat,
  required double startLng,
  required double endLat,
  required double endLng,
  int orderIndex = 1,
}) {
  return Stage(
    id: id,
    nameFr: 'Etape ',
    distance: 10.0,
    elevationGain: 500,
    elevationLoss: 300,
    orderIndex: orderIndex,
    startLat: startLat,
    startLng: startLng,
    endLat: endLat,
    endLng: endLng,
  );
}

void main() {
  // Etapes fictives en Corse (GR20).
  // Etape 1 : (42.0, 9.0) -> (42.1, 9.1)  ~14 km
  // Etape 2 : (42.1, 9.1) -> (42.2, 9.2)  ~14 km
  // Etape 3 : (42.2, 9.2) -> (42.3, 9.3)  ~14 km
  final stages = [
    _fakeStage(
      id: 'stage-1',
      startLat: 42.0,
      startLng: 9.0,
      endLat: 42.1,
      endLng: 9.1,
      orderIndex: 1,
    ),
    _fakeStage(
      id: 'stage-2',
      startLat: 42.1,
      startLng: 9.1,
      endLat: 42.2,
      endLng: 9.2,
      orderIndex: 2,
    ),
    _fakeStage(
      id: 'stage-3',
      startLat: 42.2,
      startLng: 9.2,
      endLat: 42.3,
      endLng: 9.3,
      orderIndex: 3,
    ),
  ];

  group('StageDetectionService', () {
    test('detecte l etape correcte quand position proche du depart', () async {
      final service = StageDetectionService();

      // Positions progressant : depart etape 1, milieu etape 2, fin etape 3
      final positions = [
        // Pile sur le depart de etape 1 -> stage-1
        _fakePosition(lat: 42.0, lng: 9.0),
        // Proche du depart de etape 2 (42.1, 9.1) -> stage-2
        _fakePosition(lat: 42.105, lng: 9.105),
        // Proche du fin de etape 3 (42.3, 9.3) -> stage-3
        _fakePosition(lat: 42.298, lng: 9.298),
      ];

      final positionStream = Stream.fromIterable(positions);

      final emitted = await service
          .currentStageId(positionStream, stages)
          .toList();

      // Premier point sur le depart de etape 1
      expect(emitted.first, equals('stage-1'));
      // Dernier point proche de la fin de etape 3
      expect(emitted.last, equals('stage-3'));
      // On doit avoir au moins 2 changements (stage-1 -> stage-2 -> stage-3)
      expect(emitted.length, greaterThanOrEqualTo(2));
    });

    test('hysteresis empeche le flip-flop a la frontiere entre etapes',
        () async {
      // Hysteresis de 5000m pour forcer le blocage
      // (la frontiere stage-1/stage-2 est a 42.1, 9.1)
      final service = StageDetectionService(hysteresisMeters: 5000.0);

      final positions = [
        // Depart sur etape 1
        _fakePosition(lat: 42.0, lng: 9.0),
        // Juste de l'autre cote de la frontiere -> stage-2 est plus proche
        // MAIS l'hysteresis (5000m) empeche le flip
        // car la difference de distance n'est pas assez grande
        _fakePosition(lat: 42.102, lng: 9.102),
        // Revient cote etape 1
        _fakePosition(lat: 42.098, lng: 9.098),
        // Repart cote etape 2 (tres legerement)
        _fakePosition(lat: 42.103, lng: 9.103),
      ];

      final positionStream = Stream.fromIterable(positions);

      final emitted = await service
          .currentStageId(positionStream, stages)
          .toList();

      // Avec une hysteresis de 5000m, on ne devrait PAS changer d'etape
      // car les positions oscillent autour de la frontiere (42.1, 9.1)
      // et la difference de distance est < 5000m.
      // Tous les points doivent rester sur stage-1 (premier detecte).
      expect(emitted.length, equals(1));
      expect(emitted.first, equals('stage-1'));
    });
  });
}
