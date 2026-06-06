import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/trek/domain/models/track_point.dart';
import 'package:moteur_gr/features/trek/domain/trek_stats.dart';

/// Tests de TrekStats — calcul temps reel des statistiques de trek.
void main() {
  group('TrekStats', () {
    test('calcule distance, denivele, vitesse et ETA sur une serie de points',
        () {
      // Sentier fictif de 2.5 km total
      final stats = TrekStats(totalDistanceKm: 2.5);

      // Serie de 6 points simulant un parcours en Corse :
      // - Chaque segment ~ 250m horizontalement (0.00225 deg lat ~ 250m)
      // - Altitudes : 800 -> 810 -> 812 -> 900 -> 850 -> 860
      //   (810-800=10m D+, 812-810=2m bruit, 900-812=88m D+,
      //    850-900=50m D-, 860-850=10m D+)
      // - Echantillonnage actif toutes les 4 min (< seuil pause 5 min),
      //   avec UN gap de 40 min entre les points 4 et 5 = la seule pause.
      //   NB: a 250m / 4 min on est a ~3.75 km/h (allure rando realiste),
      //   et l'intervalle reste sous le seuil de pause (300 s).

      final baseTime = DateTime(2026, 5, 30, 8, 0, 0);

      final points = [
        TrackPoint(
          lat: 42.00000,
          lng: 9.0000,
          elevation: 800,
          timestamp: baseTime,
        ),
        TrackPoint(
          lat: 42.00225,
          lng: 9.0000,
          elevation: 810,
          timestamp: baseTime.add(const Duration(minutes: 4)),
        ),
        TrackPoint(
          lat: 42.00450,
          lng: 9.0000,
          elevation: 812, // +2m = bruit, ignore
          timestamp: baseTime.add(const Duration(minutes: 8)),
        ),
        TrackPoint(
          lat: 42.00675,
          lng: 9.0000,
          elevation: 900,
          timestamp: baseTime.add(const Duration(minutes: 12)),
        ),
        // Gap de 40 min apres le point 4 -> PAUSE detectee (> seuil 5 min).
        TrackPoint(
          lat: 42.00900,
          lng: 9.0000,
          elevation: 850,
          timestamp: baseTime.add(const Duration(minutes: 52)), // +40 min gap
        ),
        TrackPoint(
          lat: 42.01125,
          lng: 9.0000,
          elevation: 860,
          timestamp: baseTime.add(const Duration(minutes: 56)),
        ),
      ];

      for (final p in points) {
        stats.addPoint(p);
      }

      // --- Distance ---
      // 5 segments de ~250m chacun = ~1.25 km
      expect(stats.distanceKm, closeTo(1.25, 0.1));

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
      // Un seul gap > 5 min : entre point 4 et 5 (40 min).
      expect(stats.pauseCount, equals(1));

      // --- Duree active ---
      // 4 segments actifs de 4 min = 16 min (le gap de 40 min est exclu).
      expect(stats.elapsedDuration.inMinutes, equals(16));

      // --- Vitesse moyenne ---
      // ~1.25 km en 16 min (0.267h) = ~4.7 km/h
      expect(stats.avgSpeedKmh, closeTo(4.7, 0.5));

      // --- Vitesse instantanee ---
      // Dernier segment : ~250m en 4 min = ~3.75 km/h
      expect(stats.currentSpeedKmh, closeTo(3.75, 0.5));

      // --- ETA ---
      // Reste ~1.25 km a ~4.7 km/h = ~16 min
      final etaMinutes = stats.eta!.inMinutes;
      expect(etaMinutes, closeTo(16, 5));

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
