import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/trek/data/arrival_detection_service.dart';
import 'package:moteur_gr/features/trek/domain/models/stage.dart';

void main() {
  group('ArrivalDetectionService', () {
    // Etape fictive : depart Calenzana, arrivee refuge d'Ortu di u Piobbu
    // Point d'arrivee a lat=42.35, lng=8.95 (fictif, coherent GR20)
    final stageA = Stage(
      id: 'gr20-1',
      nameFr: 'Calenzana - Ortu di u Piobbu',
      nameEn: 'Calenzana - Ortu di u Piobbu',
      distance: 12.0,
      elevationGain: 1500,
      elevationLoss: 100,
      estimatedDurationMinutes: 420,
      difficulty: 'hard',
      orderIndex: 0,
      startLat: 42.5074,
      startLng: 8.8558,
      endLat: 42.35,
      endLng: 8.95,
    );

    // Deuxieme etape (derniere du sentier pour ce test)
    final stageB = Stage(
      id: 'gr20-2',
      nameFr: 'Ortu di u Piobbu - Carrozzu',
      nameEn: 'Ortu di u Piobbu - Carrozzu',
      distance: 7.0,
      elevationGain: 800,
      elevationLoss: 700,
      estimatedDurationMinutes: 300,
      difficulty: 'moderate',
      orderIndex: 1,
      startLat: 42.35,
      startLng: 8.95,
      endLat: 42.40,
      endLng: 9.00,
    );

    test('detection arrivee etape + pas de doublon', () async {
      final service = ArrivalDetectionService(
        stages: [stageA, stageB],
      );

      final emitted = <ArrivalEvent>[];
      service.events.listen(emitted.add);

      // Position tres proche du point d'arrivee de stageA (~50m)
      // Decalage de 0.0004 degre en latitude ~ 44m
      service.checkPosition(42.3504, 8.95);

      // Attendre que le stream propage l'evenement
      await Future<void>.delayed(Duration.zero);

      // Un evenement doit avoir ete emis pour stageA
      expect(emitted, hasLength(1));
      expect(emitted.first.type, equals(ArrivalType.stageEnd));
      expect(emitted.first.stageId, equals('gr20-1'));

      // Re-verifier la meme position — pas de doublon
      service.checkPosition(42.3504, 8.95);
      await Future<void>.delayed(Duration.zero);

      // Toujours un seul evenement
      expect(emitted, hasLength(1));

      // Verifier que le guard contient bien l'etape
      expect(service.alreadyArrived, contains('gr20-1'));

      service.dispose();
    });

    test('detection fin de sentier sur derniere etape', () async {
      final service = ArrivalDetectionService(
        stages: [stageA, stageB],
      );

      final emitted = <ArrivalEvent>[];
      service.events.listen(emitted.add);

      // Position proche du point d'arrivee de stageB (derniere etape)
      service.checkPosition(42.4003, 9.0001);
      await Future<void>.delayed(Duration.zero);

      expect(emitted, hasLength(1));
      expect(emitted.first.type, equals(ArrivalType.trailEnd));
      expect(emitted.first.stageId, equals('gr20-2'));

      service.dispose();
    });

    test('pas de detection hors rayon', () async {
      final service = ArrivalDetectionService(
        stages: [stageA, stageB],
      );

      final emitted = <ArrivalEvent>[];
      service.events.listen(emitted.add);

      // Position loin de tout point d'arrivee (~5km)
      service.checkPosition(42.30, 8.90);
      await Future<void>.delayed(Duration.zero);

      expect(emitted, isEmpty);

      service.dispose();
    });

    test('rayon configurable respecte', () async {
      // Rayon tres petit (10m) — la position a ~44m ne doit pas declencher
      final service = ArrivalDetectionService(
        arrivalRadiusMeters: 10.0,
        stages: [stageA],
      );

      final emitted = <ArrivalEvent>[];
      service.events.listen(emitted.add);

      // Position a ~44m du point d'arrivee (hors rayon de 10m)
      service.checkPosition(42.3504, 8.95);
      await Future<void>.delayed(Duration.zero);

      expect(emitted, isEmpty);

      service.dispose();
    });

    test('reset permet de re-detecter', () async {
      final service = ArrivalDetectionService(
        stages: [stageA],
      );

      final emitted = <ArrivalEvent>[];
      service.events.listen(emitted.add);

      // Premiere detection
      service.checkPosition(42.3504, 8.95);
      await Future<void>.delayed(Duration.zero);
      expect(emitted, hasLength(1));

      // Reset
      service.reset();
      expect(service.alreadyArrived, isEmpty);

      // Re-detection possible
      service.checkPosition(42.3504, 8.95);
      await Future<void>.delayed(Duration.zero);
      expect(emitted, hasLength(2));

      service.dispose();
    });
  });
}
