import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/weather/models/weather_forecast.dart';

/// Tests du modèle WeatherForecast.
void main() {
  group('WeatherForecast', () {
    test('fromOpenMeteo parse correctement les données', () {
      final json = _sampleOpenMeteoResponse();
      final forecast = WeatherForecast.fromOpenMeteo(json);

      expect(forecast.days.length, 3);
      expect(forecast.latitude, 42.15);
      expect(forecast.longitude, 9.1);
    });

    test('toJson et fromJson sont symétriques', () {
      final original = WeatherForecast.fromOpenMeteo(_sampleOpenMeteoResponse());
      final json = original.toJson();
      final restored = WeatherForecast.fromJson(json);

      expect(restored.days.length, original.days.length);
      expect(restored.latitude, original.latitude);
      expect(restored.days.first.temperatureMax, original.days.first.temperatureMax);
    });
  });

  group('DayForecast', () {
    test('isAlertCondition détecte pluie forte', () {
      final day = DayForecast(
        date: DateTime(2026, 7, 1),
        temperatureMax: 25,
        temperatureMin: 15,
        precipitationMm: 30,
        windSpeedKmh: 20,
        uvIndex: 5,
        weatherCode: 65,
      );
      expect(day.isAlertCondition, true);
    });

    test('isAlertCondition détecte vent fort', () {
      final day = DayForecast(
        date: DateTime(2026, 7, 1),
        temperatureMax: 20,
        temperatureMin: 10,
        precipitationMm: 0,
        windSpeedKmh: 65,
        uvIndex: 3,
        weatherCode: 2,
      );
      expect(day.isAlertCondition, true);
    });

    test('isAlertCondition false pour beau temps', () {
      final day = DayForecast(
        date: DateTime(2026, 7, 1),
        temperatureMax: 28,
        temperatureMin: 18,
        precipitationMm: 0,
        windSpeedKmh: 10,
        uvIndex: 6,
        weatherCode: 0,
      );
      expect(day.isAlertCondition, false);
    });

    test('weatherDescription retourne le bon texte', () {
      final day = DayForecast(
        date: DateTime(2026, 7, 1),
        temperatureMax: 20,
        temperatureMin: 10,
        precipitationMm: 0,
        windSpeedKmh: 10,
        uvIndex: 5,
        weatherCode: 0,
      );
      expect(day.weatherDescription, 'Ciel dégagé');
    });

    test('weatherDescription orage', () {
      final day = DayForecast(
        date: DateTime(2026, 7, 1),
        temperatureMax: 20,
        temperatureMin: 10,
        precipitationMm: 15,
        windSpeedKmh: 40,
        uvIndex: 2,
        weatherCode: 95,
      );
      expect(day.weatherDescription, 'Orage');
    });

    test('weatherIconName soleil pour code 0', () {
      final day = DayForecast(
        date: DateTime(2026, 7, 1),
        temperatureMax: 20,
        temperatureMin: 10,
        precipitationMm: 0,
        windSpeedKmh: 10,
        uvIndex: 5,
        weatherCode: 0,
      );
      expect(day.weatherIconName, 'wb_sunny');
    });

    test('weatherIconName neige pour code 71', () {
      final day = DayForecast(
        date: DateTime(2026, 7, 1),
        temperatureMax: 2,
        temperatureMin: -3,
        precipitationMm: 10,
        windSpeedKmh: 20,
        uvIndex: 1,
        weatherCode: 71,
      );
      expect(day.weatherIconName, 'ac_unit');
    });

    test('toJson et fromJson symétriques pour DayForecast', () {
      final original = DayForecast(
        date: DateTime(2026, 7, 15),
        temperatureMax: 28.5,
        temperatureMin: 14.2,
        precipitationMm: 2.3,
        windSpeedKmh: 15.0,
        uvIndex: 7.0,
        weatherCode: 2,
      );
      final json = original.toJson();
      final restored = DayForecast.fromJson(json);

      expect(restored.temperatureMax, 28.5);
      expect(restored.temperatureMin, 14.2);
      expect(restored.precipitationMm, 2.3);
      expect(restored.weatherCode, 2);
    });
  });
}

/// Réponse Open-Meteo simulée
Map<String, dynamic> _sampleOpenMeteoResponse() {
  return {
    'latitude': 42.15,
    'longitude': 9.1,
    'daily': {
      'time': ['2026-07-01', '2026-07-02', '2026-07-03'],
      'temperature_2m_max': [28.0, 25.0, 22.0],
      'temperature_2m_min': [18.0, 15.0, 12.0],
      'precipitation_sum': [0.0, 5.0, 15.0],
      'wind_speed_10m_max': [10.0, 20.0, 35.0],
      'uv_index_max': [8.0, 6.0, 3.0],
      'weather_code': [0, 3, 61],
    },
  };
}
