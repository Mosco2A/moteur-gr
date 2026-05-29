import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:moteur_gr/features/weather/data/weather_api_service.dart';
import 'package:moteur_gr/features/weather/domain/weather_data.dart';

/// Reponse Open-Meteo fictive pour les tests.
///
/// 3 jours de prevision, donnees realistes haute montagne Corse.
const _fakeApiResponse = '''
{
  "latitude": 42.15,
  "longitude": 9.10,
  "daily": {
    "time": ["2026-07-01", "2026-07-02", "2026-07-03"],
    "temperature_2m_min": [12.5, 8.3, 15.0],
    "temperature_2m_max": [24.0, 18.5, 28.0],
    "precipitation_sum": [0.0, 12.5, 0.2],
    "precipitation_probability_max": [5, 85, 10],
    "weather_code": [0, 63, 1],
    "wind_speed_10m_max": [15.0, 45.0, 8.0],
    "uv_index_max": [9.0, 3.0, 8.5]
  }
}
''';

void main() {
  group('WeatherApiService', () {
    test('fetchForecast parse correctement la reponse Open-Meteo', () async {
      // Client HTTP mock qui retourne la reponse fictive
      final mockClient = MockClient((request) async {
        // Verifier que l'URL contient les bons parametres
        expect(request.url.host, 'api.open-meteo.com');
        expect(request.url.path, '/v1/forecast');
        expect(request.url.queryParameters['latitude'], '42.1500');
        expect(request.url.queryParameters['longitude'], '9.1000');
        expect(
          request.url.queryParameters['daily'],
          contains('temperature_2m_min'),
        );

        return http.Response(_fakeApiResponse, 200);
      });

      final service = WeatherApiService(httpClient: mockClient);

      final forecasts = await service.fetchForecast(
        latitude: 42.15,
        longitude: 9.10,
      );

      // 3 jours de prevision
      expect(forecasts, hasLength(3));

      // Jour 1 — ciel degage, chaud, UV eleve
      final day1 = forecasts[0];
      expect(day1.date, '2026-07-01');
      expect(day1.latitude, 42.15);
      expect(day1.longitude, 9.10);
      expect(day1.temperatureMin, 12.5);
      expect(day1.temperatureMax, 24.0);
      expect(day1.precipitationMm, 0.0);
      expect(day1.precipitationProbability, 5);
      expect(day1.weatherCode, 0);
      expect(day1.windSpeedMax, 15.0);
      expect(day1.uvIndexMax, 9.0);
      expect(day1.weatherDescription, 'Ciel dégagé');
      expect(day1.hasPrecipitation, isFalse);
      expect(day1.isDangerous, isTrue); // UV >= 8

      // Jour 2 — pluie forte, vent
      final day2 = forecasts[1];
      expect(day2.date, '2026-07-02');
      expect(day2.temperatureMin, 8.3);
      expect(day2.temperatureMax, 18.5);
      expect(day2.precipitationMm, 12.5);
      expect(day2.precipitationProbability, 85);
      expect(day2.weatherCode, 63);
      expect(day2.weatherDescription, 'Pluie');
      expect(day2.hasPrecipitation, isTrue);

      // Jour 3 — partiellement nuageux
      final day3 = forecasts[2];
      expect(day3.weatherCode, 1);
      expect(day3.weatherDescription, 'Partiellement nuageux');
      expect(day3.isDangerous, isTrue); // UV 8.5 >= 8

      service.dispose();
    });

    test('fetchForecast leve WeatherApiException sur erreur HTTP', () async {
      final mockClient = MockClient((request) async {
        return http.Response('{"error": true}', 500);
      });

      final service = WeatherApiService(httpClient: mockClient);

      expect(
        () => service.fetchForecast(latitude: 42.15, longitude: 9.10),
        throwsA(isA<WeatherApiException>()),
      );

      service.dispose();
    });

    test('fetchForecast leve WeatherApiException sur JSON invalide', () async {
      final mockClient = MockClient((request) async {
        return http.Response('not json', 200);
      });

      final service = WeatherApiService(httpClient: mockClient);

      expect(
        () => service.fetchForecast(latitude: 42.15, longitude: 9.10),
        throwsA(isA<WeatherApiException>()),
      );

      service.dispose();
    });
  });

  group('WeatherData', () {
    test('weatherDescription retourne le bon texte WMO', () {
      const data = WeatherData(
        date: '2026-07-01',
        latitude: 42.0,
        longitude: 9.0,
        temperatureMin: 10,
        temperatureMax: 20,
        precipitationMm: 0,
        precipitationProbability: 0,
        weatherCode: 95,
        windSpeedMax: 10,
        uvIndexMax: 5,
      );

      expect(data.weatherDescription, 'Orage');
      expect(data.isDangerous, isTrue); // code >= 95
    });

    test('equality et hashCode basee sur date+position', () {
      const a = WeatherData(
        date: '2026-07-01',
        latitude: 42.0,
        longitude: 9.0,
        temperatureMin: 10,
        temperatureMax: 20,
        precipitationMm: 0,
        precipitationProbability: 0,
        weatherCode: 0,
        windSpeedMax: 10,
        uvIndexMax: 5,
      );

      const b = WeatherData(
        date: '2026-07-01',
        latitude: 42.0,
        longitude: 9.0,
        temperatureMin: 15, // temperatures differentes
        temperatureMax: 25,
        precipitationMm: 5,
        precipitationProbability: 50,
        weatherCode: 3,
        windSpeedMax: 20,
        uvIndexMax: 7,
      );

      // Meme date + meme position = egaux
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });
  });
}
