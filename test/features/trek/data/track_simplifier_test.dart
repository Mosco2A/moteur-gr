import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/trek/data/track_simplifier.dart';
import 'package:moteur_gr/features/trek/domain/models/track_point.dart';

void main() {
  group('DouglasPeucker (track_simplifier)', () {
    test('simplification reduit le nombre de points', () {
      // Trace en zigzag : points alternant nord/sud autour d'un axe
      // Les ecarts lateraux (~500m) depassent largement epsilon par defaut
      // mais les points intermediaires proches de l'axe seront supprimes
      final points = <TrackPoint>[];

      // Branche horizontale : 10 points alignes a lat=42.0
      for (var i = 0; i < 10; i++) {
        points.add(TrackPoint(
          lat: 42.0,
          lng: 9.0 + i * 0.001,
          elevation: 1000,
        ));
      }

      // Coude : un point nettement hors-axe (~550m d'ecart)
      points.add(const TrackPoint(
        lat: 42.005,
        lng: 9.010,
        elevation: 1200,
      ));

      // Branche verticale : 10 points alignes a lng=9.01
      for (var i = 1; i <= 10; i++) {
        points.add(TrackPoint(
          lat: 42.005 + i * 0.001,
          lng: 9.010,
          elevation: 1100,
        ));
      }

      // 21 points au total
      expect(points.length, equals(21));

      // Simplifier avec epsilon par defaut (0.0001 degres ~ 11m)
      final simplified = DouglasPeucker.simplify(points);

      // Les points alignes sur chaque branche doivent etre supprimes
      expect(simplified.length, lessThan(points.length));
    });

    test('premier et dernier points toujours preserves', () {
      // Trace quelconque avec des ecarts
      final points = [
        const TrackPoint(
          lat: 42.000,
          lng: 9.000,
          elevation: 800,
          timestamp: null,
        ),
        const TrackPoint(
          lat: 42.010,
          lng: 9.005,
          elevation: 900,
          timestamp: null,
        ),
        const TrackPoint(
          lat: 42.005,
          lng: 9.010,
          elevation: 850,
          timestamp: null,
        ),
        const TrackPoint(
          lat: 41.990,
          lng: 9.015,
          elevation: 950,
          timestamp: null,
        ),
        const TrackPoint(
          lat: 42.015,
          lng: 9.030,
          elevation: 780,
          timestamp: null,
        ),
      ];

      // Epsilon large pour forcer une simplification agressive
      final simplified = DouglasPeucker.simplify(points, 0.01);

      // Premier et dernier sont toujours la
      expect(simplified.first, equals(points.first));
      expect(simplified.last, equals(points.last));

      // Avec epsilon petit, idem
      final simplifiedSmall = DouglasPeucker.simplify(points, 0.00001);
      expect(simplifiedSmall.first, equals(points.first));
      expect(simplifiedSmall.last, equals(points.last));
    });
  });
}
