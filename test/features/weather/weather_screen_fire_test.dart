import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/weather/models/fire_risk_config.dart';
import 'package:moteur_gr/features/weather/models/weather_alert.dart';
import 'package:moteur_gr/features/weather/models/weather_forecast.dart';

/// Tests E3.5b : alertes meteo + alerte incendie sur conditions.
void main() {
  group('WeatherAlertBanner - alerte meteo classique', () {
    test('alerte meteo s\'affiche pour orage severe', () {
      // Prevision avec orage (code WMO 95)
      final forecast = WeatherForecast(
        latitude: 42.15,
        longitude: 9.1,
        days: [
          DayForecast(
            date: DateTime(2026, 7, 15),
            temperatureMax: 28,
            temperatureMin: 18,
            precipitationMm: 15,
            windSpeedKmh: 45,
            uvIndex: 6,
            weatherCode: 95,
          ),
        ],
      );

      final alerts = WeatherAlert.fromForecast(forecast);

      // Verifie qu'une alerte orage est generee
      expect(alerts.isNotEmpty, true);
      expect(alerts.any((a) => a.title == 'Orage prévu'), true);
      expect(alerts.any((a) => a.severity == 'danger'), true);
      // Toutes les alertes meteo classiques sont de type weather
      expect(alerts.every((a) => a.type == AlertType.weather), true);
    });

    test('alerte meteo s\'affiche pour neige', () {
      final forecast = WeatherForecast(
        latitude: 42.15,
        longitude: 9.1,
        days: [
          DayForecast(
            date: DateTime(2026, 3, 10),
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

      expect(alerts.isNotEmpty, true);
      expect(alerts.any((a) => a.title == 'Neige prévue'), true);
      expect(alerts.any((a) => a.severity == 'warning'), true);
    });
  });

  group('WeatherAlertBanner - alerte incendie sur conditions', () {
    test('alerte incendie se declenche quand conditions reunies', () {
      // Config : risque juin-sept, >= 30°C, regions Corse/PACA
      const config = FireRiskConfig(
        riskMonthStart: 6,
        riskMonthEnd: 9,
        temperatureThreshold: 30.0,
        riskRegions: ['Corse', 'PACA'],
        fireTipId: 'incendie-periode-risque',
      );

      // Prevision en juillet, 35°C, region Corse -> doit declencher
      final forecast = WeatherForecast(
        latitude: 42.15,
        longitude: 9.1,
        days: [
          DayForecast(
            date: DateTime(2026, 7, 15),
            temperatureMax: 35,
            temperatureMin: 22,
            precipitationMm: 0,
            windSpeedKmh: 10,
            uvIndex: 9,
            weatherCode: 0,
          ),
        ],
      );

      final fireAlerts = WeatherAlert.fireAlertsFromForecast(
        forecast,
        fireConfig: config,
        region: 'Corse',
      );

      expect(fireAlerts.isNotEmpty, true);
      expect(fireAlerts.first.type, AlertType.fire);
      expect(fireAlerts.first.severity, 'danger');
      expect(fireAlerts.first.fireTipId, 'incendie-periode-risque');
      expect(fireAlerts.first.title, 'Risque incendie');
    });

    test('pas d\'alerte incendie hors periode ou sous seuil', () {
      const config = FireRiskConfig(
        riskMonthStart: 6,
        riskMonthEnd: 9,
        temperatureThreshold: 30.0,
        riskRegions: ['Corse'],
      );

      // Cas 1 : hors periode (mars)
      final forecastMarch = WeatherForecast(
        latitude: 42.15,
        longitude: 9.1,
        days: [
          DayForecast(
            date: DateTime(2026, 3, 15),
            temperatureMax: 35,
            temperatureMin: 20,
            precipitationMm: 0,
            windSpeedKmh: 5,
            uvIndex: 7,
            weatherCode: 0,
          ),
        ],
      );

      expect(
        WeatherAlert.fireAlertsFromForecast(
          forecastMarch,
          fireConfig: config,
          region: 'Corse',
        ),
        isEmpty,
      );

      // Cas 2 : sous seuil temperature (25°C en ete)
      final forecastCool = WeatherForecast(
        latitude: 42.15,
        longitude: 9.1,
        days: [
          DayForecast(
            date: DateTime(2026, 7, 15),
            temperatureMax: 25,
            temperatureMin: 18,
            precipitationMm: 0,
            windSpeedKmh: 5,
            uvIndex: 7,
            weatherCode: 0,
          ),
        ],
      );

      expect(
        WeatherAlert.fireAlertsFromForecast(
          forecastCool,
          fireConfig: config,
          region: 'Corse',
        ),
        isEmpty,
      );

      // Cas 3 : region non a risque
      final forecastOther = WeatherForecast(
        latitude: 45.0,
        longitude: 6.0,
        days: [
          DayForecast(
            date: DateTime(2026, 7, 15),
            temperatureMax: 35,
            temperatureMin: 22,
            precipitationMm: 0,
            windSpeedKmh: 5,
            uvIndex: 9,
            weatherCode: 0,
          ),
        ],
      );

      expect(
        WeatherAlert.fireAlertsFromForecast(
          forecastOther,
          fireConfig: config,
          region: 'Alpes',
        ),
        isEmpty,
      );
    });

    test('FireRiskConfig conditions parametrables', () {
      // Config custom avec seuils differents
      const customConfig = FireRiskConfig(
        riskMonthStart: 5,
        riskMonthEnd: 10,
        temperatureThreshold: 25.0,
        riskRegions: ['Alpes'],
        fireTipId: 'custom-fire-tip',
      );

      final forecast = WeatherForecast(
        latitude: 45.0,
        longitude: 6.0,
        days: [
          DayForecast(
            date: DateTime(2026, 5, 20),
            temperatureMax: 27,
            temperatureMin: 15,
            precipitationMm: 0,
            windSpeedKmh: 5,
            uvIndex: 7,
            weatherCode: 0,
          ),
        ],
      );

      final alerts = WeatherAlert.fireAlertsFromForecast(
        forecast,
        fireConfig: customConfig,
        region: 'Alpes',
      );

      // Doit declencher car mai dans [5..10], 27 >= 25, Alpes dans la liste
      expect(alerts.isNotEmpty, true);
      expect(alerts.first.fireTipId, 'custom-fire-tip');
    });
  });
}
