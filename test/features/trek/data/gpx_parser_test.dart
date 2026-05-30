import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/trek/data/gpx_parser.dart';

void main() {
  group('GpxParser.parse', () {
    test('parse GPX valide — verifie metadata + trackPoints', () {
      const gpx = '''
<?xml version="1.0" encoding="UTF-8"?>
<gpx version="1.1" creator="test">
  <metadata>
    <name>Sentier Test</name>
    <desc>Un sentier de test</desc>
    <author><name>Vulcain</name></author>
  </metadata>
  <trk>
    <trkseg>
      <trkpt lat="42.0" lon="9.0"><ele>800</ele></trkpt>
      <trkpt lat="42.001" lon="9.001"><ele>810</ele></trkpt>
      <trkpt lat="42.002" lon="9.002"><ele>820</ele></trkpt>
    </trkseg>
  </trk>
</gpx>
''';

      final result = GpxParser.parse(gpx);

      // Metadata
      expect(result.metadata.name, equals('Sentier Test'));
      expect(result.metadata.desc, equals('Un sentier de test'));
      expect(result.metadata.author, equals('Vulcain'));

      // TrackPoints
      expect(result.tracks.length, equals(1));
      expect(result.tracks[0].length, equals(3));

      final first = result.tracks[0].first;
      expect(first.lat, closeTo(42.0, 0.001));
      expect(first.lng, closeTo(9.0, 0.001));
      expect(first.altitude, closeTo(800, 1));
      expect(first.distanceFromStart, equals(0.0));

      // Distances cumulees croissantes
      for (var i = 1; i < result.tracks[0].length; i++) {
        expect(
          result.tracks[0][i].distanceFromStart,
          greaterThan(result.tracks[0][i - 1].distanceFromStart),
        );
      }

      // allTrackPoints raccourci
      expect(result.allTrackPoints.length, equals(3));
      expect(result.totalPoints, equals(3));
    });

    test('GPX multi-segments — verifie que les segments sont separes', () {
      const gpx = '''
<?xml version="1.0" encoding="UTF-8"?>
<gpx version="1.1">
  <metadata><name>Multi-Seg</name></metadata>
  <trk>
    <trkseg>
      <trkpt lat="42.0" lon="9.0"><ele>100</ele></trkpt>
      <trkpt lat="42.01" lon="9.01"><ele>110</ele></trkpt>
    </trkseg>
    <trkseg>
      <trkpt lat="43.0" lon="10.0"><ele>200</ele></trkpt>
      <trkpt lat="43.01" lon="10.01"><ele>210</ele></trkpt>
      <trkpt lat="43.02" lon="10.02"><ele>220</ele></trkpt>
    </trkseg>
  </trk>
</gpx>
''';

      final result = GpxParser.parse(gpx);

      // 2 segments distincts
      expect(result.tracks.length, equals(2));
      expect(result.tracks[0].length, equals(2));
      expect(result.tracks[1].length, equals(3));

      // Premier segment: distances cumulees propres
      expect(result.tracks[0][0].distanceFromStart, equals(0.0));
      expect(result.tracks[0][1].distanceFromStart, greaterThan(0));

      // Deuxieme segment: distances recalculees depuis 0
      expect(result.tracks[1][0].distanceFromStart, equals(0.0));
      expect(result.tracks[1][1].distanceFromStart, greaterThan(0));

      // Total = 5 points
      expect(result.allTrackPoints.length, equals(5));

      // Metadata
      expect(result.metadata.name, equals('Multi-Seg'));
    });

    test('GPX invalide — retourne erreur propre (pas crash)', () {
      // Contenu vide
      expect(
        () => GpxParser.parse(''),
        throwsA(isA<FormatException>()),
      );

      // Espaces seuls
      expect(
        () => GpxParser.parse('   '),
        throwsA(isA<FormatException>()),
      );

      // GPX sans tracks ni waypoints — ne crash pas, retourne vide
      const emptyGpx = '''
<?xml version="1.0" encoding="UTF-8"?>
<gpx version="1.1">
  <metadata><name>Vide</name></metadata>
</gpx>
''';
      final result = GpxParser.parse(emptyGpx);
      expect(result.tracks, isEmpty);
      expect(result.waypoints, isEmpty);
      expect(result.metadata.name, equals('Vide'));
      expect(result.totalPoints, equals(0));
    });
  });
}
