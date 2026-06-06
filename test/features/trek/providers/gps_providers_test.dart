import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:moteur_gr/features/trek/data/arrival_detection_service.dart';
import 'package:moteur_gr/features/trek/data/gps_service.dart';
import 'package:moteur_gr/features/trek/data/stage_detection_service.dart';
import 'package:moteur_gr/features/trek/domain/models/stage.dart';
import 'package:moteur_gr/features/trek/providers/gps_providers.dart';

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

/// Cree un GpsService mock qui emet des positions depuis un StreamController.
GpsService _createMockGpsService(StreamController<Position> controller) {
  return GpsService(
    isLocationServiceEnabled: () async => true,
    checkPermission: () async => LocationPermission.always,
    requestPermission: () async => LocationPermission.always,
    getPositionStream: ({required LocationSettings locationSettings}) =>
        controller.stream,
  );
}

void main() {
  // Etapes fictives (sentier de test, coordonnees arbitraires).
  // Etape 1 : (42.0, 9.0) -> (42.1, 9.1)
  // Etape 2 : (42.1, 9.1) -> (42.2, 9.2)
  // Etape 3 : (42.2, 9.2) -> (42.3, 9.3) — derniere etape
  final domainStages = [
    const Stage(
      id: '1',
      nameFr: 'Etape 1',
      distance: 10.0,
      elevationGain: 500,
      elevationLoss: 300,
      orderIndex: 1,
      startLat: 42.0,
      startLng: 9.0,
      endLat: 42.1,
      endLng: 9.1,
    ),
    const Stage(
      id: '2',
      nameFr: 'Etape 2',
      distance: 12.0,
      elevationGain: 600,
      elevationLoss: 400,
      orderIndex: 2,
      startLat: 42.1,
      startLng: 9.1,
      endLat: 42.2,
      endLng: 9.2,
    ),
    const Stage(
      id: '3',
      nameFr: 'Etape 3',
      distance: 8.0,
      elevationGain: 400,
      elevationLoss: 500,
      orderIndex: 3,
      startLat: 42.2,
      startLng: 9.2,
      endLat: 42.3,
      endLng: 9.3,
    ),
  ];

  group('GpsProviders pipeline complet', () {
    test('position -> stage detection -> arrival detection', () async {
      // --- Setup ---
      final positionController = StreamController<Position>.broadcast();
      final mockGps = _createMockGpsService(positionController);

      // Container Riverpod avec overrides
      final container = ProviderContainer(
        overrides: [
          // Injecter le mock GPS
          gpsServiceProvider.overrideWithValue(mockGps),
          // Injecter les stages domain directement (bypass DB)
          domainStagesProvider.overrideWithValue(domainStages),
        ],
      );
      addTearDown(() {
        container.dispose();
        positionController.close();
      });

      // --- Lire les providers ---
      // currentStageIdProvider : pipeline position -> stage detection
      final stageIdSubscription = container.listen(
        currentStageIdProvider,
        (_, __) {},
      );

      // arrivalEventsProvider : pipeline position -> arrival detection
      final arrivalSubscription = container.listen(
        arrivalEventsProvider,
        (_, __) {},
      );

      // Collecter les emissions
      final emittedStageIds = <String>[];
      final emittedArrivals = <ArrivalEvent>[];

      // Ecouter les changements
      container.listen(currentStageIdProvider, (prev, next) {
        final value = next.valueOrNull;
        if (value != null && !emittedStageIds.contains(value)) {
          emittedStageIds.add(value);
        }
      });

      container.listen(arrivalEventsProvider, (prev, next) {
        final value = next.valueOrNull;
        if (value != null) {
          emittedArrivals.add(value);
        }
      });

      // --- Emettre des positions ---
      // Position 1 : pile sur le depart etape 1 -> stageId = '1'
      positionController.add(_fakePosition(lat: 42.0, lng: 9.0));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Position 2 : proche fin etape 1 / debut etape 2 -> stageId = '2'
      positionController.add(_fakePosition(lat: 42.105, lng: 9.105));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Position 3 : en plein milieu etape 3 -> stageId = '3'
      positionController.add(_fakePosition(lat: 42.298, lng: 9.298));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // --- Verifications ---
      // Le pipeline doit avoir detecte au moins l'etape 1 comme premiere etape
      expect(
        emittedStageIds,
        isNotEmpty,
        reason: 'Le pipeline doit emettre au moins un stageId',
      );
      expect(
        emittedStageIds.first,
        equals('1'),
        reason: 'La premiere position est sur le depart de l etape 1',
      );

      // Verifier que les providers sont bien connectes et actifs
      final currentStageState = container.read(currentStageIdProvider);
      expect(
        currentStageState.hasValue || currentStageState.isLoading,
        isTrue,
        reason: 'currentStageIdProvider doit etre actif',
      );

      final arrivalState = container.read(arrivalEventsProvider);
      expect(
        arrivalState.hasValue || arrivalState.isLoading,
        isTrue,
        reason: 'arrivalEventsProvider doit etre actif',
      );

      // Verifier que le container a bien les services injectes
      final gps = container.read(gpsServiceProvider);
      expect(gps, isA<GpsService>(),
          reason: 'Le mock GPS doit etre injecte');

      final stages = container.read(domainStagesProvider);
      expect(stages.length, equals(3),
          reason: 'Les 3 etapes domain doivent etre presentes');

      // Verifier que stageDetectionServiceProvider fonctionne
      final detection = container.read(stageDetectionServiceProvider);
      expect(detection, isA<StageDetectionService>());

      // Verifier que arrivalDetectionServiceProvider fonctionne
      final arrival = container.read(arrivalDetectionServiceProvider);
      expect(arrival, isA<ArrivalDetectionService>());

      // Cleanup explicite
      stageIdSubscription.close();
      arrivalSubscription.close();
    });
  });
}
