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

  // --- LOT-B : probabilité d'orage (PT-5) + dérivation stormProbability ---
  group('DayForecast — orage (LOT-B)', () {
    test('fromOpenMeteo parse precipitation_probability_max', () {
      final json = {
        'latitude': 42.0,
        'longitude': 9.0,
        'daily': {
          'time': ['2026-07-01', '2026-07-02'],
          'temperature_2m_max': [25.0, 22.0],
          'temperature_2m_min': [15.0, 12.0],
          'precipitation_sum': [0.0, 8.0],
          'wind_speed_10m_max': [10.0, 20.0],
          'uv_index_max': [7.0, 5.0],
          'weather_code': [1, 80],
          'precipitation_probability_max': [10, 75],
        },
      };
      final forecast = WeatherForecast.fromOpenMeteo(json);
      expect(forecast.days[0].precipitationProbabilityMax, 10);
      expect(forecast.days[1].precipitationProbabilityMax, 75);
    });

    test('champ absent => precipitationProbabilityMax null (rétrocompat)', () {
      final json = {
        'latitude': 42.0,
        'longitude': 9.0,
        'daily': {
          'time': ['2026-07-01'],
          'temperature_2m_max': [25.0],
          'temperature_2m_min': [15.0],
          'precipitation_sum': [0.0],
          'wind_speed_10m_max': [10.0],
          'uv_index_max': [7.0],
          'weather_code': [1],
        },
      };
      final forecast = WeatherForecast.fromOpenMeteo(json);
      expect(forecast.days.first.precipitationProbabilityMax, isNull);
    });

    test('stormProbability = 100 si code orage, sinon la proba de pluie', () {
      final storm = DayForecast(
        date: DateTime(2026, 7, 1),
        temperatureMax: 20,
        temperatureMin: 12,
        precipitationMm: 5,
        windSpeedKmh: 30,
        uvIndex: 3,
        weatherCode: 95,
        precipitationProbabilityMax: 40,
      );
      expect(storm.isStorm, true);
      expect(storm.stormProbability, 100);

      final rainy = DayForecast(
        date: DateTime(2026, 7, 2),
        temperatureMax: 22,
        temperatureMin: 14,
        precipitationMm: 4,
        windSpeedKmh: 15,
        uvIndex: 4,
        weatherCode: 80,
        precipitationProbabilityMax: 65,
      );
      expect(rainy.isStorm, false);
      expect(rainy.stormProbability, 65);

      final clear = DayForecast(
        date: DateTime(2026, 7, 3),
        temperatureMax: 26,
        temperatureMin: 16,
        precipitationMm: 0,
        windSpeedKmh: 8,
        uvIndex: 6,
        weatherCode: 1,
      );
      expect(clear.stormProbability, 0);
    });

    test('cache round-trip conserve precipitationProbabilityMax', () {
      final original = DayForecast(
        date: DateTime(2026, 7, 1),
        temperatureMax: 20,
        temperatureMin: 12,
        precipitationMm: 5,
        windSpeedKmh: 30,
        uvIndex: 3,
        weatherCode: 80,
        precipitationProbabilityMax: 55,
      );
      final restored = DayForecast.fromJson(original.toJson());
      expect(restored.precipitationProbabilityMax, 55);
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
