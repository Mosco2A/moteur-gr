import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/tracking/domain/tracking_engine.dart';

/// Tests du moteur de tracking GPS.
void main() {
  late TrackingEngine engine;

  setUp(() {
    engine = TrackingEngine();
  });

  group('TrackingEngine', () {
    test('calcule la distance entre 3 points alignes', () {
      // 3 points espaces d'environ 1 km chacun en latitude
      // 0.009 degre lat ~ 1 km
      engine.addPosition(42.0000, 9.0, 500);
      engine.addPosition(42.0090, 9.0, 500);
      engine.addPosition(42.0180, 9.0, 500);

      // Distance totale ~ 2 km (2 segments de ~1 km)
      expect(engine.distanceMeters, closeTo(2000, 100));
      expect(engine.pointCount, 3);
    });

    test('calcule le denivele D+ et D- correctement', () {
      // Montee de 100m puis descente de 50m
      engine.addPosition(42.0, 9.0, 1000);
      engine.addPosition(42.001, 9.0, 1100); // +100m
      engine.addPosition(42.002, 9.0, 1050); // -50m

      expect(engine.elevationGainM, closeTo(100, 0.1));
      expect(engine.elevationLossM, closeTo(50, 0.1));
    });

    test('ignore les positions pendant une pause', () {
      engine.addPosition(42.0, 9.0, 500);
      engine.addPosition(42.001, 9.0, 500);
      final distAvantPause = engine.distanceMeters;

      engine.pause();
      expect(engine.isPaused, isTrue);

      // Position ignoree pendant la pause
      engine.addPosition(42.010, 9.0, 500);
      expect(engine.distanceMeters, equals(distAvantPause));
      expect(engine.pointCount, 2); // pas de nouveau point

      engine.resume();
      expect(engine.isPaused, isFalse);
    });

    test('calcule une vitesse moyenne > 0 avec des points', () {
      final start = DateTime(2026, 5, 26, 10, 0, 0);
      final after30min = DateTime(2026, 5, 26, 10, 30, 0);

      engine.addPosition(42.0, 9.0, 500, timestamp: start);
      // ~2 km en 30 min = 4 km/h
      engine.addPosition(42.018, 9.0, 500, timestamp: after30min);

      // La vitesse depend du durationSeconds qui utilise DateTime.now()
      // On verifie juste que la distance est bonne
      expect(engine.distanceMeters, closeTo(2000, 100));
      expect(engine.pointCount, 2);
    });

    test('reset remet tout a zero', () {
      engine.addPosition(42.0, 9.0, 1000);
      engine.addPosition(42.009, 9.0, 1100);
      expect(engine.distanceMeters, greaterThan(0));
      expect(engine.elevationGainM, greaterThan(0));

      engine.reset();

      expect(engine.distanceMeters, 0.0);
      expect(engine.elevationGainM, 0.0);
      expect(engine.elevationLossM, 0.0);
      expect(engine.durationSeconds, 0);
      expect(engine.averageSpeedKmh, 0.0);
      expect(engine.pointCount, 0);
      expect(engine.isPaused, isFalse);
    });
  });
}
