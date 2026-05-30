import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/trek/data/track_simplifier.dart';
import 'package:moteur_gr/features/trek/domain/models/track_point.dart';

void main() {
  group('DouglasPeucker (track_simplifier)', () {
    test('simplification reduit le nombre de points', () {
      // Trace en zigzag : les points hors-axe sont loin du segment
      // global, mais les points alignes sont proches.
      // Avec un epsilon raisonnable, les points intermediaires
      // proches du segment global sont supprimes.
      final points = <TrackPoint>[];

      // Branche horizontale : 10 points a lat=42.0
      for (var i = 0; i < 10; i++) {
        points.add(TrackPoint(
          lat: 42.0,
          lng: 9.0 + i * 0.001,
          elevation: 500,
        ));
      }

      // Coude : un point nettement hors-axe (~500m d ecart)
      points.add(const TrackPoint(
        lat: 42.005,
        lng: 9.010,
        elevation: 600,
      ));

      // Branche verticale : 10 points a lng=9.01
      for (var i = 1; i <= 10; i++) {
        points.add(TrackPoint(
          lat: 42.005 + i * 0.001,
          lng: 9.010,
          elevation: 700,
        ));
      }

      // epsilon = 0.0005 degres (~55m) : les points alignes
      // sur chaque branche doivent etre supprimes
      final simplified = DouglasPeucker.simplify(points, 0.0005);

      // La simplification a reduit le nombre de points
      expect(simplified.length, lessThan(points.length),
          reason: 'La simplification doit reduire le nombre de points');

      // Au minimum : debut, coude, fin = 3 points
      expect(simplified.length, greaterThanOrEqualTo(3));
    });

    test('premier et dernier points toujours preserves', () {
      final points = <TrackPoint>[];

      // Generer 20 points en zigzag
      for (var i = 0; i < 20; i++) {
        final zigzag = (i % 2 == 0) ? 0.002 : -0.002;
        points.add(TrackPoint(
          lat: 42.0 + i * 0.001 + zigzag,
          lng: 9.0 + i * 0.001,
          elevation: 500.0 + i * 10,
        ));
      }

      // Epsilon large pour forcer beaucoup de suppression
      final simplified = DouglasPeucker.simplify(points, 0.001);

      // Premier et dernier points TOUJOURS preserves
      expect(simplified.first.lat, equals(points.first.lat),
          reason: 'Le premier point doit etre preserve');
      expect(simplified.first.lng, equals(points.first.lng),
          reason: 'Le premier point doit etre preserve');
      expect(simplified.last.lat, equals(points.last.lat),
          reason: 'Le dernier point doit etre preserve');
      expect(simplified.last.lng, equals(points.last.lng),
          reason: 'Le dernier point doit etre preserve');
    });

    test('epsilon par defaut est 0.0001 degres (~11m)', () {
      // Verifie que la constante est accessible
      expect(DouglasPeucker.defaultEpsilon, equals(0.0001));
    });

    test('moins de 3 points retourne la liste originale', () {
      final points = [
        const TrackPoint(lat: 42.0, lng: 9.0, elevation: 500),
        const TrackPoint(lat: 42.1, lng: 9.1, elevation: 600),
      ];

      final simplified = DouglasPeucker.simplify(points);
      expect(simplified.length, equals(2));
    });

    test('liste vide retourne liste vide', () {
      final simplified = DouglasPeucker.simplify([]);
      expect(simplified, isEmpty);
    });

    test('epsilon = 0 conserve tous les points (sauf colineaires exacts)', () {
      final points = [
        const TrackPoint(lat: 42.000, lng: 9.000, elevation: 500),
        const TrackPoint(lat: 42.010, lng: 9.005, elevation: 600),
        const TrackPoint(lat: 42.005, lng: 9.010, elevation: 550),
        const TrackPoint(lat: 41.990, lng: 9.015, elevation: 650),
        const TrackPoint(lat: 42.015, lng: 9.030, elevation: 480),
      ];

      final simplified = DouglasPeucker.simplify(points, 0);
      expect(simplified.length, equals(points.length));
    });
  });
}
