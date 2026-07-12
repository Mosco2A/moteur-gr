import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/weather/models/weather_alert.dart';
import 'package:moteur_gr/features/weather/models/weather_forecast.dart';

/// Tests des alertes météo.
///
/// LOT-B (D-5) : les libellés sont externalisés en i18n ; le modèle porte
/// désormais un [WeatherAlertKind] sémantique. Les seuils sont inchangés.
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
      expect(alerts.any((a) => a.kind == WeatherAlertKind.storm), true);
      expect(alerts.any((a) => a.severity == 'danger'), true);
      // Le libellé de condition WMO est conservé pour paramétrer l'i18n.
      final storm = alerts.firstWhere((a) => a.kind == WeatherAlertKind.storm);
      expect(storm.conditionLabel, 'Orage');
      expect(alerts.every((a) => a.type == AlertType.weather), true);
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
      final wind = alerts.firstWhere((a) => a.kind == WeatherAlertKind.wind);
      expect(wind.amount, 70);
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
      expect(alerts.any((a) => a.kind == WeatherAlertKind.rain), true);
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
      expect(alerts.any((a) => a.kind == WeatherAlertKind.uv), true);
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
      expect(alerts.any((a) => a.kind == WeatherAlertKind.snow), true);
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
      final windAlert =
          alerts.firstWhere((a) => a.kind == WeatherAlertKind.wind);
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
      final windAlert =
          alerts.firstWhere((a) => a.kind == WeatherAlertKind.wind);
      expect(windAlert.severity, 'warning');
    });
  });
}
