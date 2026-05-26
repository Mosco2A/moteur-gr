import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/weather/models/weather_alert.dart';
import 'package:moteur_gr/features/weather/models/weather_forecast.dart';

/// Tests des alertes météo.
void main() {
  group('WeatherAlert', () {
    test('fromForecast détecte un orage', () {
      final forecast = WeatherForecast(
        latitude: 42.15,
        longitude: 9.1,
        days: [
          DayForecast(
            date: DateTime(2026, 7, 1),
            temperatureMax: 25,
            temperatureMin: 15,
            precipitationMm: 10,
            windSpeedKmh: 30,
            uvIndex: 5,
            weatherCode: 95,
          ),
        ],
      );

      final alerts = WeatherAlert.fromForecast(forecast);
      expect(alerts.any((a) => a.title == 'Orage prévu'), true);
      expect(alerts.any((a) => a.severity == 'danger'), true);
    });

    test('fromForecast détecte vent fort', () {
      final forecast = WeatherForecast(
        latitude: 42.15,
        longitude: 9.1,
        days: [
          DayForecast(
            date: DateTime(2026, 7, 1),
            temperatureMax: 20,
            temperatureMin: 10,
            precipitationMm: 0,
            windSpeedKmh: 70,
            uvIndex: 5,
            weatherCode: 2,
          ),
        ],
      );

      final alerts = WeatherAlert.fromForecast(forecast);
      expect(alerts.any((a) => a.title == 'Vent fort'), true);
    });

    test('fromForecast détecte fortes précipitations', () {
      final forecast = WeatherForecast(
        latitude: 42.15,
        longitude: 9.1,
        days: [
          DayForecast(
            date: DateTime(2026, 7, 1),
            temperatureMax: 18,
            temperatureMin: 12,
            precipitationMm: 25,
            windSpeedKmh: 15,
            uvIndex: 2,
            weatherCode: 65,
          ),
        ],
      );

      final alerts = WeatherAlert.fromForecast(forecast);
      expect(alerts.any((a) => a.title == 'Fortes précipitations'), true);
    });

    test('fromForecast détecte UV extrême', () {
      final forecast = WeatherForecast(
        latitude: 42.15,
        longitude: 9.1,
        days: [
          DayForecast(
            date: DateTime(2026, 7, 1),
            temperatureMax: 35,
            temperatureMin: 22,
            precipitationMm: 0,
            windSpeedKmh: 10,
            uvIndex: 9,
            weatherCode: 0,
          ),
        ],
      );

      final alerts = WeatherAlert.fromForecast(forecast);
      expect(alerts.any((a) => a.title == 'UV très élevé'), true);
    });

    test('fromForecast détecte neige', () {
      final forecast = WeatherForecast(
        latitude: 42.15,
        longitude: 9.1,
        days: [
          DayForecast(
            date: DateTime(2026, 7, 1),
            temperatureMax: 2,
            temperatureMin: -3,
            precipitationMm: 10,
            windSpeedKmh: 20,
            uvIndex: 1,
            weatherCode: 73,
          ),
        ],
      );

      final alerts = WeatherAlert.fromForecast(forecast);
      expect(alerts.any((a) => a.title == 'Neige prévue'), true);
    });

    test('fromForecast vide si beau temps', () {
      final forecast = WeatherForecast(
        latitude: 42.15,
        longitude: 9.1,
        days: [
          DayForecast(
            date: DateTime(2026, 7, 1),
            temperatureMax: 25,
            temperatureMin: 15,
            precipitationMm: 0,
            windSpeedKmh: 10,
            uvIndex: 5,
            weatherCode: 0,
          ),
        ],
      );

      final alerts = WeatherAlert.fromForecast(forecast);
      expect(alerts, isEmpty);
    });

    test('sévérité danger pour vent >= 80 km/h', () {
      final forecast = WeatherForecast(
        latitude: 42.15,
        longitude: 9.1,
        days: [
          DayForecast(
            date: DateTime(2026, 7, 1),
            temperatureMax: 15,
            temperatureMin: 5,
            precipitationMm: 5,
            windSpeedKmh: 85,
            uvIndex: 3,
            weatherCode: 3,
          ),
        ],
      );

      final alerts = WeatherAlert.fromForecast(forecast);
      final windAlert = alerts.firstWhere((a) => a.title == 'Vent fort');
      expect(windAlert.severity, 'danger');
    });

    test('sévérité warning pour vent 60-79 km/h', () {
      final forecast = WeatherForecast(
        latitude: 42.15,
        longitude: 9.1,
        days: [
          DayForecast(
            date: DateTime(2026, 7, 1),
            temperatureMax: 15,
            temperatureMin: 5,
            precipitationMm: 5,
            windSpeedKmh: 65,
            uvIndex: 3,
            weatherCode: 3,
          ),
        ],
      );

      final alerts = WeatherAlert.fromForecast(forecast);
      final windAlert = alerts.firstWhere((a) => a.title == 'Vent fort');
      expect(windAlert.severity, 'warning');
    });
  });
}
