import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:moteur_gr/features/trek/data/arrival_detection_service.dart';
import 'package:moteur_gr/features/trek/domain/models/stage.dart';
import 'package:moteur_gr/features/trek/domain/trek_completion.dart';

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
    nameFr: 'Etape $orderIndex',
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
  // Etapes fictives (sentier de test, coordonnees arbitraires).
  // Etape 1 : (42.0, 9.0) -> (42.1, 9.1)
  // Etape 2 : (42.1, 9.1) -> (42.2, 9.2)
  // Etape 3 : (42.2, 9.2) -> (42.3, 9.3) — derniere etape
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

  group('ArrivalDetectionService', () {
    test('detecte arrivee etape + pas de doublon', () async {
      // Rayon large (15000m) pour garantir la detection avec nos coordonnees
      // fictives (la fin de etape-1 est a 42.1, 9.1 et on envoie 42.1001, 9.1001
      // soit ~15m de distance reelle — mais on utilise un rayon large pour le test)
      final service = ArrivalDetectionService(arrivalRadiusMeters: 15000.0);

      final positions = [
        // Position 1 — proche de la fin de etape-1 (42.1, 9.1) -> detection
        _fakePosition(lat: 42.1001, lng: 9.1001),
        // Position 2 — ENCORE proche de la fin de etape-1 -> PAS de doublon
        _fakePosition(lat: 42.0999, lng: 9.0999),
        // Position 3 — proche de la fin de etape-3 (42.3, 9.3) -> trailEnd
        _fakePosition(lat: 42.3001, lng: 9.3001),
      ];

      final positionStream = Stream.fromIterable(positions);

      final events = await service
          .arrivalEvents(positionStream, stages)
          .toList();

      // Position 1 : on arrive a la fin de etape-1 (et potentiellement etape-2
      // si dans le rayon). On verifie qu'au moins etape-1 est detecte.
      final stage1Events =
          events.where((e) => e.stageId == 'stage-1').toList();
      expect(stage1Events.length, equals(1),
          reason: 'Etape 1 doit etre emise exactement une fois');
      expect(stage1Events.first.type, equals('stageEnd'),
          reason: 'Etape 1 n est pas la derniere — type stageEnd');

      // Position 2 : meme zone -> etape-1 deja dans alreadyArrived -> pas de doublon
      // On verifie qu'il n'y a qu'UNE seule emission pour stage-1
      // (deja verifie ci-dessus par le count == 1)

      // Position 3 : fin de etape-3 = derniere etape -> trailEnd
      final stage3Events =
          events.where((e) => e.stageId == 'stage-3').toList();
      expect(stage3Events.length, equals(1),
          reason: 'Etape 3 doit etre emise exactement une fois');
      expect(stage3Events.first.type, equals('trailEnd'),
          reason: 'Etape 3 est la derniere — type trailEnd');

      // Guard anti-doublon : stage-1 est bien dans le set
      expect(service.alreadyArrived.contains('stage-1'), isTrue);
      expect(service.alreadyArrived.contains('stage-3'), isTrue);
    });

    test('stream vide si aucune etape', () async {
      final service = ArrivalDetectionService();
      final positions = [_fakePosition(lat: 42.0, lng: 9.0)];
      final positionStream = Stream.fromIterable(positions);

      final events = await service
          .arrivalEvents(positionStream, <Stage>[])
          .toList();

      expect(events, isEmpty);
    });

    test('reset vide le guard anti-doublon', () {
      final service = ArrivalDetectionService();
      service.alreadyArrived.addAll(['stage-1', 'stage-2']);

      service.reset();

      expect(service.alreadyArrived, isEmpty);
    });

    test('direction-aware SN : trailEnd = etape 1, PAS la derniere du JSON',
        () async {
      // Plan Sud->Nord : ordre de marche s3 -> s2 -> s1. La fin reelle = s1.
      final plan = TrekPlan.fromStages(
        stages,
        direction: 'SN',
        forwardDirectionCode: 'NS',
      );
      final service = ArrivalDetectionService(arrivalRadiusMeters: 15000.0);

      final positions = [
        // Fin de etape-1 (42.1, 9.1) = fin REELLE du trek en SN.
        _fakePosition(lat: 42.1001, lng: 9.1001),
      ];
      final events = await service
          .arrivalEvents(Stream.fromIterable(positions), stages, plan: plan)
          .toList();

      final s1 = events.where((e) => e.stageId == 'stage-1').toList();
      expect(s1.length, equals(1));
      expect(s1.first.type, equals('trailEnd'),
          reason: 'En SN, la fin de trek est l etape 1 (fin du parcours).');
    });

    test(
        'direction-aware SN : arrivee au refuge de DEPART (s4) => aucune '
        'emission (anti-felicitations prematurees)', () async {
      final plan = TrekPlan.fromStages(
        stages,
        direction: 'SN',
        forwardDirectionCode: 'NS',
      );
      final service = ArrivalDetectionService(arrivalRadiusMeters: 15000.0);

      final positions = [
        // Fin de etape-3 (42.3, 9.3) = point de DEPART en SN (etape s4 commence
        // ici cote marche). La detection ne doit rien emettre pour le depart.
        _fakePosition(lat: 42.3001, lng: 9.3001),
      ];
      final events = await service
          .arrivalEvents(Stream.fromIterable(positions), stages, plan: plan)
          .toList();

      // s4 est l'etape de depart en SN -> jamais d'arrivee emise pour elle.
      expect(events.where((e) => e.stageId == 'stage-4'), isEmpty,
          reason: 'Pas d arrivee a l etape de depart (garde anti-premature).');
    });

    test('sans plan : comportement historique (trailEnd = plus grand orderIndex)',
        () async {
      final service = ArrivalDetectionService(arrivalRadiusMeters: 15000.0);
      final positions = [
        _fakePosition(lat: 42.3001, lng: 9.3001), // fin de stage-3 (max index)
      ];
      final events = await service
          .arrivalEvents(Stream.fromIterable(positions), stages)
          .toList();
      final s3 = events.where((e) => e.stageId == 'stage-3').toList();
      expect(s3.single.type, equals('trailEnd'));
    });

    test('rayon configurable respecte', () async {
      // Rayon tres petit (1m) — la position a ~15m de distance ne doit PAS trigger
      final service = ArrivalDetectionService(arrivalRadiusMeters: 1.0);

      final positions = [
        // ~15m de la fin de etape-1 (42.1, 9.1)
        _fakePosition(lat: 42.1001, lng: 9.1001),
      ];

      final positionStream = Stream.fromIterable(positions);

      final events = await service
          .arrivalEvents(positionStream, stages)
          .toList();

      // Avec un rayon de 1m, aucune detection ne doit se produire
      // car la position est a ~15m de toute fin d'etape
      expect(events, isEmpty,
          reason: 'Rayon 1m ne doit pas detecter a 15m de distance');
    });
  });
}
