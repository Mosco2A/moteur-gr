import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/geo/geo_utils.dart';

void main() {
  group('GeoUtils', () {
    group('haversineDistance', () {
      test('distance Paris-Marseille environ 660 km', () {
        // Paris : 48.8566, 2.3522
        // Marseille : 43.2965, 5.3698
        final distance = GeoUtils.haversineDistance(
          48.8566, 2.3522,
          43.2965, 5.3698,
        );

        // La distance a vol d'oiseau est d'environ 660 km
        // Tolerance de 20 km pour les variations de formule
        expect(distance, closeTo(660000, 20000));
      });

      test('distance entre deux points identiques vaut 0', () {
        final distance = GeoUtils.haversineDistance(
          45.0, 3.0,
          45.0, 3.0,
        );
        expect(distance, equals(0.0));
      });

      test('distance courte entre deux points proches', () {
        // Deux points separes d'environ 1 km
        final distance = GeoUtils.haversineDistance(
          45.0000, 3.0000,
          45.0090, 3.0000,
        );

        // ~1 km en latitude (1 degre lat ~ 111 km, 0.009 ~ 1 km)
        expect(distance, closeTo(1000, 50));
      });
    });

    group('bearing', () {
      test('cap vers le nord = environ 0 degres', () {
        // Point au sud, point au nord (meme longitude)
        final cap = GeoUtils.bearing(45.0, 3.0, 46.0, 3.0);
        // Devrait etre proche de 0 (nord)
        expect(cap, closeTo(0, 1));
      });

      test('cap vers l est = environ 90 degres', () {
        // Point a l ouest, point a l est (meme latitude)
        final cap = GeoUtils.bearing(45.0, 3.0, 45.0, 4.0);
        // Devrait etre proche de 90 (est)
        expect(cap, closeTo(90, 2));
      });

      test('cap vers le sud = environ 180 degres', () {
        final cap = GeoUtils.bearing(46.0, 3.0, 45.0, 3.0);
        expect(cap, closeTo(180, 1));
      });
    });

    group('projectPointOnSegment', () {
      test('projection d un point sur un segment simple', () {
        // Segment horizontal (meme latitude)
        // Point au-dessus du milieu du segment
        final result = GeoUtils.projectPointOnSegment(
          45.001, 3.005, // point decale au nord
          45.000, 3.000, // segA
          45.000, 3.010, // segB
        );

        // La projection devrait etre a peu pres au milieu du segment
        expect(result.projectedLat, closeTo(45.000, 0.001));
        expect(result.projectedLng, closeTo(3.005, 0.001));
        // Distance perpendiculaire d environ 111 m (0.001 degre lat)
        expect(result.distanceToSegment, closeTo(111, 20));
      });

      test('projection hors segment clampe a l extremite A', () {
        // Point avant le debut du segment
        final result = GeoUtils.projectPointOnSegment(
          45.000, 2.990, // point avant segA
          45.000, 3.000, // segA
          45.000, 3.010, // segB
        );

        // Devrait clamper sur segA
        expect(result.projectedLat, closeTo(45.000, 0.001));
        expect(result.projectedLng, closeTo(3.000, 0.001));
      });

      test('projection hors segment clampe a l extremite B', () {
        // Point apres la fin du segment
        final result = GeoUtils.projectPointOnSegment(
          45.000, 3.020, // point apres segB
          45.000, 3.000, // segA
          45.000, 3.010, // segB
        );

        // Devrait clamper sur segB
        expect(result.projectedLat, closeTo(45.000, 0.001));
        expect(result.projectedLng, closeTo(3.010, 0.001));
      });
    });
  });
}
