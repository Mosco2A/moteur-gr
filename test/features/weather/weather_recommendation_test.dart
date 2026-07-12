import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/weather/domain/weather_recommendation.dart';
import 'package:moteur_gr/features/weather/models/weather_forecast.dart';

/// Tests LOT-B : dérivation de la recommandation randonnée (AM-7, 3 niveaux).
void main() {
  DayForecast day({
    double tMax = 20,
    double precip = 0,
    double wind = 10,
    double uv = 4,
    int code = 1,
    double? stormProb,
  }) {
    return DayForecast(
      date: DateTime(2026, 7, 1),
      temperatureMax: tMax,
      temperatureMin: tMax - 6,
      precipitationMm: precip,
      windSpeedKmh: wind,
      uvIndex: uv,
      weatherCode: code,
      precipitationProbabilityMax: stormProb,
    );
  }

  group('WeatherRecommendation.forDay', () {
    test('ok par beau temps', () {
      expect(
        WeatherRecommendation.forDay(day()),
        WeatherRecommendationLevel.ok,
      );
    });

    test('danger si orage', () {
      expect(
        WeatherRecommendation.forDay(day(code: 95)),
        WeatherRecommendationLevel.danger,
      );
    });

    test('danger si vent violent (>= 80 km/h)', () {
      expect(
        WeatherRecommendation.forDay(day(wind: 85)),
        WeatherRecommendationLevel.danger,
      );
    });

    test('danger si pluie très forte (>= 40 mm)', () {
      expect(
        WeatherRecommendation.forDay(day(precip: 45)),
        WeatherRecommendationLevel.danger,
      );
    });

    test('danger si probabilité d\'orage élevée (>= 80 %)', () {
      expect(
        WeatherRecommendation.forDay(day(code: 80, stormProb: 85)),
        WeatherRecommendationLevel.danger,
      );
    });

    test('watch si vent fort (60-79 km/h)', () {
      expect(
        WeatherRecommendation.forDay(day(wind: 65)),
        WeatherRecommendationLevel.watch,
      );
    });

    test('watch si UV très élevé (>= 8)', () {
      expect(
        WeatherRecommendation.forDay(day(uv: 9)),
        WeatherRecommendationLevel.watch,
      );
    });

    test('watch si neige', () {
      expect(
        WeatherRecommendation.forDay(day(code: 73)),
        WeatherRecommendationLevel.watch,
      );
    });

    test('watch si pluie notable (>= 20 mm)', () {
      expect(
        WeatherRecommendation.forDay(day(precip: 25)),
        WeatherRecommendationLevel.watch,
      );
    });
  });
}
