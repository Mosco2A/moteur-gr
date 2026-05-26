import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/geo/douglas_peucker.dart';
import 'package:moteur_gr/core/geo/track_point.dart';

void main() {
  group('DouglasPeucker', () {
    /// Genere une ligne droite de [count] points entre deux positions.
    List<TrackPoint> straightLine(int count) {
      final points = <TrackPoint>[];
      for (var i = 0; i < count; i++) {
        final t = i / (count - 1);
        points.add(TrackPoint(
          lat: 45.0 + t * 0.1,
          lng: 3.0 + t * 0.1,
          altitude: 500 + t * 100,
          distanceFromStart: t * 10000,
        ));
      }
      return points;
    }

    test('epsilon = 0 ne supprime aucun point', () {
      // Trace quelconque avec des ecarts
      final points = [
        const TrackPoint(
            lat: 45.000, lng: 3.000, altitude: 500, distanceFromStart: 0),
        const TrackPoint(
            lat: 45.010, lng: 3.005, altitude: 600, distanceFromStart: 1000),
        const TrackPoint(
            lat: 45.005, lng: 3.010, altitude: 550, distanceFromStart: 2000),
        const TrackPoint(
            lat: 44.990, lng: 3.015, altitude: 650, distanceFromStart: 3000),
        const TrackPoint(
            lat: 45.015, lng: 3.030, altitude: 480, distanceFromStart: 4000),
      ];

      final simplified = DouglasPeucker.simplify(points, 0);

      // Avec epsilon = 0, tous les points doivent etre conserves
      expect(simplified.length, equals(points.length));
    });

    test('epsilon = 50m produit une reduction mesurable', () {
      // Trace en L : segment horizontal puis vertical
      // Les points intermediaires sur chaque branche sont alignes
      // avec leur sous-segment, donc supprimables
      final points = <TrackPoint>[];

      // Branche horizontale : 10 points a lat=45.0, lng de 3.0 a 3.01
      for (var i = 0; i < 10; i++) {
        points.add(TrackPoint(
          lat: 45.0,
          lng: 3.0 + i * 0.001,
          altitude: 500,
          distanceFromStart: i * 100.0,
        ));
      }

      // Coude : un point nettement hors-axe (~500m d ecart)
      points.add(const TrackPoint(
          lat: 45.005, lng: 3.010, altitude: 600, distanceFromStart: 1000));

      // Branche verticale : 10 points a lng=3.01, lat de 45.005 a 45.015
      for (var i = 1; i <= 10; i++) {
        points.add(TrackPoint(
          lat: 45.005 + i * 0.001,
          lng: 3.010,
          altitude: 700,
          distanceFromStart: 1000.0 + i * 100.0,
        ));
      }

      final simplified = DouglasPeucker.simplify(points, 50);

      // Les points alignes sur chaque branche doivent etre supprimes
      // Seuls le debut, le coude, et la fin (+- quelques points) restent
      expect(simplified.length, lessThan(points.length));
      expect(simplified.first, equals(points.first));
      expect(simplified.last, equals(points.last));
    });

    test('ligne droite : 0 points internes supprimes', () {
      final points = straightLine(20);
      // Avec un epsilon large, une ligne droite ne devrait garder
      // que le premier et dernier point (tous les internes sont alignes)
      final simplified = DouglasPeucker.simplify(points, 1);

      // Seuls debut et fin conserves pour une ligne parfaitement droite
      expect(simplified.length, equals(2));
      expect(simplified.first, equals(points.first));
      expect(simplified.last, equals(points.last));
    });

    test('moins de 3 points retourne la liste originale', () {
      final points = [
        const TrackPoint(
            lat: 45.0, lng: 3.0, altitude: 500, distanceFromStart: 0),
        const TrackPoint(
            lat: 45.1, lng: 3.1, altitude: 600, distanceFromStart: 1000),
      ];

      final simplified = DouglasPeucker.simplify(points, 100);
      expect(simplified.length, equals(2));
    });

    test('liste vide retourne liste vide', () {
      final simplified = DouglasPeucker.simplify([], 100);
      expect(simplified, isEmpty);
    });

    test('gros trace (1000 points) ne cause pas de stack overflow', () {
      // Generer un gros trace : ligne principale + ecarts alternes
      // grands (500m) et petits (5m) pour que epsilon=100 filtre bien
      final points = <TrackPoint>[];
      for (var i = 0; i < 1000; i++) {
        final zigzag = (i % 4 == 1)
            ? 0.005
            : (i % 4 == 3)
                ? -0.00005
                : 0.0;
        points.add(TrackPoint(
          lat: 45.0 + i * 0.0001 + zigzag,
          lng: 3.0 + i * 0.0001,
          altitude: 500.0 + i,
          distanceFromStart: i * 100.0,
        ));
      }

      // Ne doit pas planter (version iterative)
      final simplified = DouglasPeucker.simplify(points, 100);
      expect(simplified.length, greaterThan(2));
      expect(simplified.length, lessThan(points.length));
    });
  });
}
