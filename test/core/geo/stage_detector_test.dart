import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/geo/stage_detector.dart';
import 'package:moteur_gr/core/models/stage.dart';

void main() {
  /// Etapes fictives pour les tests de detection
  final stages = [
    const StageModel(
      trailId: 'test',
      stageNumber: 1,
      name: 'Etape 1',
      distanceKm: 10.0,
      elevationGainM: 500,
      elevationLossM: 300,
      startLat: 42.0,
      startLng: 9.0,
      endLat: 42.1,
      endLng: 9.1,
    ),
    const StageModel(
      trailId: 'test',
      stageNumber: 2,
      name: 'Etape 2',
      distanceKm: 12.0,
      elevationGainM: 600,
      elevationLossM: 400,
      startLat: 42.1,
      startLng: 9.1,
      endLat: 42.2,
      endLng: 9.2,
    ),
    const StageModel(
      trailId: 'test',
      stageNumber: 3,
      name: 'Etape 3',
      distanceKm: 8.0,
      elevationGainM: 400,
      elevationLossM: 500,
      startLat: 42.2,
      startLng: 9.2,
      endLat: 42.3,
      endLng: 9.3,
    ),
  ];

  group('StageDetector', () {
    test('detecte le depart de la premiere etape', () {
      final result = StageDetector.detect(
        projectedLat: 42.0,
        projectedLng: 9.0,
        stages: stages,
      );

      expect(result.stageNumber, 1);
      expect(result.event, StageDetectionEvent.entered);
    });

    test('detecte la fin de la premiere etape', () {
      final result = StageDetector.detect(
        projectedLat: 42.1,
        projectedLng: 9.1,
        stages: stages,
      );

      // Proche du end de etape 1 ET du start de etape 2
      // Le start de etape 2 est teste en premier dans la boucle
      expect(result.stageNumber, isIn([1, 2]));
      expect(
        result.event,
        isIn([StageDetectionEvent.exited, StageDetectionEvent.entered]),
      );
    });

    test('detecte la position au milieu de la deuxieme etape', () {
      // Position entre les bornes de etape 2 (pas dans le rayon de 200m)
      final result = StageDetector.detect(
        projectedLat: 42.15,
        projectedLng: 9.15,
        stages: stages,
      );

      expect(result.stageNumber, 2);
      expect(result.event, StageDetectionEvent.between);
    });

    test('detecte entre deux etapes quand hors rayon', () {
      // Position loin des bornes de toutes les etapes
      final result = StageDetector.detect(
        projectedLat: 42.05,
        projectedLng: 9.05,
        stages: stages,
      );

      // Devrait detecter etape 1 en mode "between"
      expect(result.stageNumber, 1);
      expect(result.event, StageDetectionEvent.between);
    });

    test('retourne unknown avec une liste vide', () {
      final result = StageDetector.detect(
        projectedLat: 42.0,
        projectedLng: 9.0,
        stages: [],
      );

      expect(result.stageNumber, 0);
      expect(result.event, StageDetectionEvent.unknown);
    });

    test('detecte la fin de la derniere etape', () {
      final result = StageDetector.detect(
        projectedLat: 42.3,
        projectedLng: 9.3,
        stages: stages,
      );

      expect(result.stageNumber, 3);
      expect(result.event, StageDetectionEvent.exited);
    });

    test('rayon de tolerance est de 200 metres', () {
      expect(StageDetector.toleranceRadiusM, 200.0);
    });
  });
}
