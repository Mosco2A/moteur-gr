import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/trek/domain/models/track_point.dart';
import 'package:moteur_gr/features/trek/domain/trek_stats.dart';

/// Tests de TrekStats — calcul temps reel des statistiques de trek.
void main() {
  group('TrekStats', () {
    test('calcule distance, denivele, vitesse et ETA sur une serie de points',
        () {
      // Sentier fictif de 5 km total
      final stats = TrekStats(totalDistanceKm: 5.0);

      // Serie de 6 points simulant un parcours en Corse :
      // - Chaque segment ~ 500m horizontalement (0.0045 deg lat ~ 500m)
      // - Altitudes : 800 -> 810 -> 812 -> 900 -> 850 -> 860
      //   (810-800=10m D+, 812-810=2m bruit, 900-812=88m D+,
      //    850-900=50m D-, 860-850=10m D+)
      // - Timestamps espaces de 10 min sauf un gap de 8 min (pause)

      final baseTime = DateTime(2026, 5, 30, 8, 0, 0);

      final points = [
        TrackPoint(
          lat: 42.0000,
          lng: 9.0000,
          elevation: 800,
          timestamp: baseTime,
        ),
        TrackPoint(
          lat: 42.0045,
          lng: 9.0000,
          elevation: 810,
          timestamp: baseTime.add(const Duration(minutes: 10)),
        ),
        TrackPoint(
          lat: 42.0090,
          lng: 9.0000,
          elevation: 812, // +2m = bruit, ignore
          timestamp: baseTime.add(const Duration(minutes: 20)),
        ),
        TrackPoint(
          lat: 42.0135,
          lng: 9.0000,
          elevation: 900,
          timestamp: baseTime.add(const Duration(minutes: 30)),
        ),
        // Gap de 8 min apres le point 4 -> PAUSE detectee (>5min = 300s)
        // mais 8 min = 480s < seuil? Non, 8 min > 5 min -> pause
        // Correction: 8 min entre les deux ne suffit pas.
        // On met un vrai gap de 40 min pour forcer la pause.
        TrackPoint(
          lat: 42.0180,
          lng: 9.0000,
          elevation: 850,
          timestamp: baseTime.add(const Duration(minutes: 70)), // +40 min gap
        ),
        TrackPoint(
          lat: 42.0225,
          lng: 9.0000,
          elevation: 860,
          timestamp: baseTime.add(const Duration(minutes: 80)),
        ),
      ];

      for (final p in points) {
        stats.addPoint(p);
      }

      // --- Distance ---
      // 5 segments de ~500m chacun = ~2.5 km
      expect(stats.distanceKm, closeTo(2.5, 0.15));

      // --- Denivele D+ ---
      // 10 (800->810) + 0 (bruit 2m) + 88 (812->900) + 10 (850->860) = 108m
      expect(stats.elevationGain, closeTo(108, 1));

      // --- Denivele D- ---
      // 50 (900->850) = 50m
      expect(stats.elevationLoss, closeTo(50, 1));

      // --- Altitude min/max ---
      expect(stats.altitudeMin, equals(800));
      expect(stats.altitudeMax, equals(900));

      // --- Pause ---
      // Un gap de 40 min entre point 4 et 5
      expect(stats.pauseCount, equals(1));

      // --- Duree active ---
      // 4 segments actifs de 10 min = 40 min = 2400 s
      // (le gap 30->70 = 40 min est exclu car pause)
      expect(stats.elapsedDuration.inMinutes, equals(40));

      // --- Vitesse moyenne ---
      // ~2.5 km en 40 min (0.667h) = ~3.75 km/h
      expect(stats.avgSpeedKmh, closeTo(3.75, 0.5));

      // --- Vitesse instantanee ---
      // Dernier segment : ~500m en 10 min = ~3 km/h
      expect(stats.currentSpeedKmh, closeTo(3.0, 0.5));

      // --- ETA ---
      // Reste ~2.5 km a ~3.75 km/h = ~40 min
      final etaMinutes = stats.eta!.inMinutes;
      expect(etaMinutes, closeTo(40, 10));

      // --- Point count ---
      expect(stats.pointCount, equals(6));
    });

    test('ETA retourne null sans donnees suffisantes', () {
      final stats = TrekStats(totalDistanceKm: 10.0);
      expect(stats.eta, isNull);
      expect(stats.avgSpeedKmh, equals(0.0));
    });

    test('ETA retourne Duration.zero quand distance depassee', () {
      final stats = TrekStats(totalDistanceKm: 0.1); // 100m total

      final baseTime = DateTime(2026, 5, 30, 8, 0, 0);
      stats.addPoint(TrackPoint(
        lat: 42.0,
        lng: 9.0,
        elevation: 500,
        timestamp: baseTime,
      ));
      stats.addPoint(TrackPoint(
        lat: 42.009,
        lng: 9.0,
        elevation: 500,
        timestamp: baseTime.add(const Duration(minutes: 15)),
      ));

      // ~1 km parcouru > 0.1 km total -> ETA = zero
      expect(stats.eta, equals(Duration.zero));
    });

    test('filtre le bruit de denivele < 3m', () {
      final stats = TrekStats(totalDistanceKm: 10.0);
      final baseTime = DateTime(2026, 5, 30, 8, 0, 0);

      stats.addPoint(TrackPoint(
        lat: 42.0,
        lng: 9.0,
        elevation: 1000,
        timestamp: baseTime,
      ));
      // +2m = bruit
      stats.addPoint(TrackPoint(
        lat: 42.001,
        lng: 9.0,
        elevation: 1002,
        timestamp: baseTime.add(const Duration(minutes: 2)),
      ));
      // -1m = bruit
      stats.addPoint(TrackPoint(
        lat: 42.002,
        lng: 9.0,
        elevation: 1001,
        timestamp: baseTime.add(const Duration(minutes: 4)),
      ));
      // +5m = signal reel
      stats.addPoint(TrackPoint(
        lat: 42.003,
        lng: 9.0,
        elevation: 1006,
        timestamp: baseTime.add(const Duration(minutes: 6)),
      ));

      expect(stats.elevationGain, closeTo(5, 0.1));
      expect(stats.elevationLoss, equals(0));
    });

    test('reset remet toutes les stats a zero', () {
      final stats = TrekStats(totalDistanceKm: 10.0);
      final baseTime = DateTime(2026, 5, 30, 8, 0, 0);

      stats.addPoint(TrackPoint(
        lat: 42.0,
        lng: 9.0,
        elevation: 1000,
        timestamp: baseTime,
      ));
      stats.addPoint(TrackPoint(
        lat: 42.009,
        lng: 9.0,
        elevation: 1100,
        timestamp: baseTime.add(const Duration(minutes: 10)),
      ));

      expect(stats.distanceKm, greaterThan(0));
      expect(stats.elevationGain, greaterThan(0));

      stats.reset();

      expect(stats.distanceKm, equals(0));
      expect(stats.elevationGain, equals(0));
      expect(stats.elevationLoss, equals(0));
      expect(stats.altitudeMin, equals(0));
      expect(stats.altitudeMax, equals(0));
      expect(stats.avgSpeedKmh, equals(0));
      expect(stats.currentSpeedKmh, equals(0));
      expect(stats.elapsedDuration, equals(Duration.zero));
      expect(stats.eta, isNull);
      expect(stats.pointCount, equals(0));
      expect(stats.pauseCount, equals(0));
    });
  });
}
