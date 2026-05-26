import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/geo/douglas_peucker.dart';
import 'package:moteur_gr/core/geo/gpx_parser.dart';
import 'package:moteur_gr/core/geo/track_point.dart';

/// Tests du provider simplifiedTrackProvider.
///
/// Vérifie que la simplification Douglas-Peucker selon le zoom
/// produit des résultats cohérents : moins de points à zoom faible,
/// plus de points à zoom élevé, jamais une liste vide.
void main() {
  late List<TrackPoint> fullTrack;

  setUp(() {
    final file = File('assets/gpx/test_trail.gpx');
    final content = file.readAsStringSync();
    fullTrack = GpxParser.parseFromString(content);
  });

  group('simplifiedTrackProvider — seuils de zoom', () {
    test('zoom 5 : epsilon 200m, moins de points que le tracé complet', () {
      final simplified = DouglasPeucker.simplify(fullTrack, 200.0);

      expect(simplified, isNotEmpty);
      expect(simplified.length, lessThan(fullTrack.length));
    });

    test('zoom 15 : epsilon 0, conserve la quasi-totalité des points', () {
      final simplified = DouglasPeucker.simplify(fullTrack, 0.0);

      // Epsilon 0 conserve tous les points sauf ceux parfaitement
      // alignés (distance perpendiculaire = 0.0 exactement)
      expect(simplified.length, greaterThanOrEqualTo(fullTrack.length - 2));
      expect(simplified.length, lessThanOrEqualTo(fullTrack.length));
    });

    test('zoom 5 produit moins de points que zoom 15', () {
      final atZoom5 = DouglasPeucker.simplify(fullTrack, 200.0);
      final atZoom15 = DouglasPeucker.simplify(fullTrack, 0.0);

      expect(atZoom5.length, lessThan(atZoom15.length));
    });

    test('zoom 10 : epsilon 50m, résultat intermédiaire', () {
      final atZoom10 = DouglasPeucker.simplify(fullTrack, 50.0);
      final atZoom5 = DouglasPeucker.simplify(fullTrack, 200.0);
      final atZoom15 = DouglasPeucker.simplify(fullTrack, 0.0);

      expect(atZoom10, isNotEmpty);
      expect(atZoom10.length, greaterThanOrEqualTo(atZoom5.length));
      expect(atZoom10.length, lessThanOrEqualTo(atZoom15.length));
    });

    test('la simplification ne retourne jamais une liste vide', () {
      // Tester plusieurs valeurs d'epsilon
      for (final epsilon in [0.0, 10.0, 50.0, 100.0, 200.0, 500.0, 1000.0]) {
        final simplified = DouglasPeucker.simplify(fullTrack, epsilon);
        expect(
          simplified,
          isNotEmpty,
          reason: 'Le tracé simplifié (epsilon=$epsilon) ne doit jamais '
              'être vide',
        );
      }
    });

    test('premier et dernier points toujours conservés', () {
      final simplified = DouglasPeucker.simplify(fullTrack, 200.0);

      expect(simplified.first.lat, equals(fullTrack.first.lat));
      expect(simplified.first.lng, equals(fullTrack.first.lng));
      expect(simplified.last.lat, equals(fullTrack.last.lat));
      expect(simplified.last.lng, equals(fullTrack.last.lng));
    });
  });
}
