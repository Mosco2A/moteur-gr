import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/geo/geo_utils.dart';
import 'package:moteur_gr/features/feasibility/domain/walk_test_session.dart';

void main() {
  group('WalkTestSession — accumulateur de distance', () {
    test('premier point = origine, distance nulle', () {
      final s = WalkTestSession();
      final counted = s.addPosition(
        lat: 48.8566,
        lng: 2.3522,
        elapsed: Duration.zero,
      );
      expect(counted, isFalse);
      expect(s.distanceMeters, 0);
    });

    test('accumule la distance haversine entre points successifs', () {
      final s = WalkTestSession();
      // 3 points alignes espaces de ~15 m chacun (~0.000135 deg lat).
      const lat0 = 48.0;
      const lng0 = 2.0;
      final step = 15.0;
      // Convertit 15 m en delta lat approx.
      final dLat = step / 111320.0; // ~m par degre lat
      s.addPosition(lat: lat0, lng: lng0, elapsed: const Duration(seconds: 2));
      s.addPosition(
          lat: lat0 + dLat, lng: lng0, elapsed: const Duration(seconds: 4));
      s.addPosition(
          lat: lat0 + 2 * dLat, lng: lng0, elapsed: const Duration(seconds: 6));
      // ~30 m au total (2 pas de ~15 m).
      expect(s.distanceMeters, closeTo(30, 2));
    });

    test('ignore les positions au-dela de 6:00 (arret auto)', () {
      final s = WalkTestSession();
      final dLat = 15.0 / 111320.0;
      s.addPosition(lat: 48.0, lng: 2.0, elapsed: const Duration(seconds: 2));
      // Point apres 6:01 -> ignore.
      final counted = s.addPosition(
        lat: 48.0 + dLat,
        lng: 2.0,
        elapsed: const Duration(minutes: 6, seconds: 1),
      );
      expect(counted, isFalse);
      expect(s.distanceMeters, 0);
    });

    test('filtre le jitter GPS (< 1 m) a l arret', () {
      final s = WalkTestSession();
      const lat = 48.0;
      const lng = 2.0;
      final micro = 0.3 / 111320.0; // ~0.3 m
      s.addPosition(lat: lat, lng: lng, elapsed: const Duration(seconds: 2));
      final counted = s.addPosition(
          lat: lat + micro, lng: lng, elapsed: const Duration(seconds: 4));
      expect(counted, isFalse);
      expect(s.distanceMeters, 0);
    });

    test('ecarte un saut aberrant (> 50 m, teleportation GPS)', () {
      final s = WalkTestSession();
      s.addPosition(lat: 48.0, lng: 2.0, elapsed: const Duration(seconds: 2));
      // Saut de ~200 m.
      final dLat = 200.0 / 111320.0;
      final counted = s.addPosition(
          lat: 48.0 + dLat, lng: 2.0, elapsed: const Duration(seconds: 4));
      expect(counted, isFalse);
      expect(s.distanceMeters, 0);
    });

    test('reset remet a zero', () {
      final s = WalkTestSession();
      final dLat = 15.0 / 111320.0;
      s.addPosition(lat: 48.0, lng: 2.0, elapsed: const Duration(seconds: 2));
      s.addPosition(
          lat: 48.0 + dLat, lng: 2.0, elapsed: const Duration(seconds: 4));
      expect(s.distanceMeters, greaterThan(0));
      s.reset();
      expect(s.distanceMeters, 0);
    });

    test('coherence avec GeoUtils.haversineDistance', () {
      // Sanity: la distance accumulee entre 2 points == haversine direct.
      final s = WalkTestSession();
      const lat0 = 45.0, lng0 = 6.0, lat1 = 45.0003, lng1 = 6.0;
      s.addPosition(lat: lat0, lng: lng0, elapsed: const Duration(seconds: 2));
      s.addPosition(lat: lat1, lng: lng1, elapsed: const Duration(seconds: 4));
      final direct = GeoUtils.haversineDistance(lat0, lng0, lat1, lng1);
      expect(s.distanceMeters, closeTo(direct, 0.01));
    });
  });
}
