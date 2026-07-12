import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/weather/data/weather_seed.dart';

/// Tests LOT-B : seed météo de démonstration (P2-P3, #DP7 / D-4).
void main() {
  group('WeatherSeed.forCoords', () {
    final now = DateTime(2026, 7, 1);

    test('génère 7 jours par défaut', () {
      final f = WeatherSeed.forCoords(latitude: 42.0, longitude: 9.0, now: now);
      expect(f.days.length, 7);
      expect(f.latitude, 42.0);
      expect(f.longitude, 9.0);
    });

    test('est déterministe pour les mêmes coordonnées', () {
      final a = WeatherSeed.forCoords(latitude: 42.5, longitude: 9.1, now: now);
      final b = WeatherSeed.forCoords(latitude: 42.5, longitude: 9.1, now: now);
      for (var i = 0; i < a.days.length; i++) {
        expect(a.days[i].weatherCode, b.days[i].weatherCode);
        expect(a.days[i].temperatureMax, b.days[i].temperatureMax);
        expect(a.days[i].windSpeedKmh, b.days[i].windSpeedKmh);
      }
    });

    test('diffère selon les coordonnées', () {
      final a = WeatherSeed.forCoords(latitude: 42.0, longitude: 9.0, now: now);
      final b = WeatherSeed.forCoords(latitude: 45.0, longitude: 6.0, now: now);
      final seqA = a.days.map((d) => d.weatherCode).toList();
      final seqB = b.days.map((d) => d.weatherCode).toList();
      expect(seqA, isNot(equals(seqB)));
    });

    test('valeurs dans des bornes plausibles', () {
      final f = WeatherSeed.forCoords(latitude: 42.0, longitude: 9.0, now: now);
      for (final d in f.days) {
        expect(d.temperatureMax, greaterThanOrEqualTo(d.temperatureMin));
        expect(d.uvIndex, inInclusiveRange(0, 11));
        expect(d.windSpeedKmh, greaterThanOrEqualTo(0));
        expect(d.precipitationMm, greaterThanOrEqualTo(0));
      }
    });

    test('le premier jour commence à la date fournie (minuit)', () {
      final f = WeatherSeed.forCoords(latitude: 42.0, longitude: 9.0, now: now);
      expect(f.days.first.date, DateTime(2026, 7, 1));
    });
  });
}
