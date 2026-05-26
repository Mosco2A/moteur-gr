import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/geo/gpx_parser.dart';

void main() {
  group('GpxParser', () {
    late String gpxContent;

    setUp(() {
      // Charger le fichier GPX directement depuis le filesystem
      // (rootBundle n est pas disponible dans les tests unitaires)
      final file = File('assets/gpx/test_trail.gpx');
      gpxContent = file.readAsStringSync();
    });

    test('parse le fichier test et retourne 27 points', () {
      final points = GpxParser.parseFromString(gpxContent);
      expect(points.length, equals(27));
    });

    test('premier point a les bonnes coordonnees', () {
      final points = GpxParser.parseFromString(gpxContent);
      final first = points.first;

      expect(first.lat, closeTo(45.5000, 0.001));
      expect(first.lng, closeTo(2.8000, 0.001));
      expect(first.altitude, closeTo(820, 1));
      expect(first.distanceFromStart, equals(0.0));
    });

    test('dernier point a des coordonnees coherentes', () {
      final points = GpxParser.parseFromString(gpxContent);
      final last = points.last;

      expect(last.lat, closeTo(45.6900, 0.001));
      expect(last.lng, closeTo(2.9720, 0.001));
      expect(last.altitude, closeTo(720, 1));
      // Le dernier point doit avoir une distance > 0
      expect(last.distanceFromStart, greaterThan(0));
    });

    test('distances cumulees strictement croissantes', () {
      final points = GpxParser.parseFromString(gpxContent);

      for (var i = 1; i < points.length; i++) {
        expect(
          points[i].distanceFromStart,
          greaterThan(points[i - 1].distanceFromStart),
          reason:
              'Distance au point $i devrait etre > distance au point ${i - 1}',
        );
      }
    });

    test('retourne liste vide si XML sans track', () {
      const emptyGpx = '''
<?xml version="1.0" encoding="UTF-8"?>
<gpx version="1.1">
  <metadata><name>Vide</name></metadata>
</gpx>
''';
      final points = GpxParser.parseFromString(emptyGpx);
      expect(points, isEmpty);
    });
  });
}
