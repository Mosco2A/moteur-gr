import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/trek/domain/models/track_point.dart';
import 'package:moteur_gr/features/trek/domain/post_trek_stats.dart';

/// Tests du calculateur de stats post-étape (F6B-03).
///
/// Vérifie : dénivelé cumulé depuis la série barométrique (préférée au GPS),
/// repli GPS si pas de baro, filtre de bruit, séparation actif/pause, et FC
/// moyenne optionnelle.
void main() {
  final t0 = DateTime.utc(2026, 6, 14, 8);

  List<TrackPoint> track(List<(int minutes, double elev)> pts) => [
        for (final p in pts)
          TrackPoint(
            lat: 42.0,
            lng: 9.0,
            elevation: p.$2,
            timestamp: t0.add(Duration(minutes: p.$1)),
          ),
      ];

  group('PostTrekStatsCalculator', () {
    test('dénivelé cumulé depuis la série barométrique (préférée)', () {
      final baro = [
        BaroAltitudeSample(timestamp: t0, altitudeM: 1000),
        BaroAltitudeSample(
            timestamp: t0.add(const Duration(minutes: 10)), altitudeM: 1100),
        BaroAltitudeSample(
            timestamp: t0.add(const Duration(minutes: 20)), altitudeM: 1050),
      ];
      final stats = PostTrekStatsCalculator.compute(
        track: track([(0, 1000), (10, 1100), (20, 1050)]),
        totalDistanceMeters: 4000,
        baroSeries: baro,
      );

      expect(stats.elevationSource, ElevationSource.barometer);
      expect(stats.elevationGainM, closeTo(100, 1e-6));
      expect(stats.elevationLossM, closeTo(50, 1e-6));
    });

    test('repli sur le vertical GPS si pas de série barométrique', () {
      final stats = PostTrekStatsCalculator.compute(
        track: track([(0, 500), (10, 560), (20, 540)]),
        totalDistanceMeters: 3000,
      );
      expect(stats.elevationSource, ElevationSource.gps);
      expect(stats.elevationGainM, closeTo(60, 1e-6));
      expect(stats.elevationLossM, closeTo(20, 1e-6));
    });

    test('filtre le bruit d altitude (< 3 m)', () {
      final stats = PostTrekStatsCalculator.compute(
        track: track([(0, 1000), (5, 1002), (10, 1001)]),
        totalDistanceMeters: 1000,
      );
      // Variations < 3 m ignorées : aucun dénivelé.
      expect(stats.elevationGainM, 0);
      expect(stats.elevationLossM, 0);
    });

    test('sépare temps actif et pauses (> 5 min)', () {
      // Segments actifs courts (2 min) entrecoupés d'UNE pause de 20 min.
      // 0->2 actif, 2->4 actif, 4->24 pause (20 min > seuil), 24->26 actif.
      final stats = PostTrekStatsCalculator.compute(
        track: track([(0, 1000), (2, 1005), (4, 1010), (24, 1010), (26, 1015)]),
        totalDistanceMeters: 600,
      );
      expect(stats.pauseCount, 1);
      expect(stats.pauseDuration, const Duration(minutes: 20));
      // Actif = 2 + 2 + 2 = 6 min.
      expect(stats.activeDuration, const Duration(minutes: 6));
      // Vitesse moyenne = 0.6 km / (6 min = 0.1 h) = 6 km/h.
      expect(stats.avgSpeedKmh, closeTo(6, 1e-6));
    });

    test('FC moyenne calculée si des échantillons sont fournis', () {
      final stats = PostTrekStatsCalculator.compute(
        track: track([(0, 1000), (10, 1010)]),
        totalDistanceMeters: 2000,
        heartRates: const [120, 130, 140],
      );
      expect(stats.avgHeartRateBpm, 130);
    });

    test('FC absente si aucune source fournie', () {
      final stats = PostTrekStatsCalculator.compute(
        track: track([(0, 1000), (10, 1010)]),
        totalDistanceMeters: 2000,
      );
      expect(stats.avgHeartRateBpm, isNull);
    });
  });
}
