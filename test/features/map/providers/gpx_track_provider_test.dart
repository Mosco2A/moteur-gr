import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/config/test_trail_config.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/core/geo/gpx_parser.dart';

/// Tests du provider gpxTrackProvider.
///
/// Vérifie que le chargement du tracé GPX retourne des points
/// valides pour le sentier de test.
void main() {
  group('gpxTrackProvider', () {
    test('le sentier test contient des points non vides', () {
      // Charger directement depuis le filesystem (pas de rootBundle en test)
      final file = File('assets/gpx/test_trail.gpx');
      final content = file.readAsStringSync();
      final points = GpxParser.parseFromString(content);

      expect(points, isNotEmpty);
      expect(points.length, equals(27));
    });

    test('les points ont des coordonnées valides', () {
      final file = File('assets/gpx/test_trail.gpx');
      final content = file.readAsStringSync();
      final points = GpxParser.parseFromString(content);

      for (final point in points) {
        expect(point.lat, inInclusiveRange(-90.0, 90.0));
        expect(point.lng, inInclusiveRange(-180.0, 180.0));
        expect(point.altitude, isNonNegative);
      }
    });

    test('trailConfigProvider est accessible avec la config test', () {
      final container = ProviderContainer(
        overrides: [
          trailConfigProvider.overrideWithValue(testTrailConfig),
        ],
      );

      addTearDown(container.dispose);

      final config = container.read(trailConfigProvider);
      expect(config.id, equals('test-trail'));
      expect(config.gpxAssetPath, equals('assets/gpx/test_trail.gpx'));
    });

    test('le premier et dernier point ont des altitudes cohérentes', () {
      final file = File('assets/gpx/test_trail.gpx');
      final content = file.readAsStringSync();
      final points = GpxParser.parseFromString(content);

      // Premier point : environ 820m
      expect(points.first.altitude, closeTo(820, 1));
      // Dernier point : environ 720m
      expect(points.last.altitude, closeTo(720, 1));
    });
  });
}
