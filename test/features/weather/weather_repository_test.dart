import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/weather/data/weather_api_service.dart';
import 'package:moteur_gr/features/weather/data/weather_cache.dart';
import 'package:moteur_gr/features/weather/data/weather_repository.dart';
import 'package:moteur_gr/features/weather/domain/weather_data.dart';

/// Fake API service pour les tests du repository.
class FakeWeatherApiService extends WeatherApiService {
  FakeWeatherApiService() : super();

  List<WeatherData>? nextResult;
  WeatherApiException? nextError;
  int callCount = 0;

  @override
  Future<List<WeatherData>> fetchForecast({
    required double latitude,
    required double longitude,
  }) async {
    callCount++;
    if (nextError != null) throw nextError!;
    return nextResult ?? [];
  }

  @override
  void dispose() {}
}

/// Fake cache in-memory pour les tests.
///
/// Implemente [WeatherCacheStore] sans dependre de Drift.
class FakeWeatherCacheStore implements WeatherCacheStore {
  final Map<String, List<WeatherData>> _store = {};
  int purgeCallCount = 0;

  @override
  Future<List<WeatherData>> getCachedForecast({
    required double latitude,
    required double longitude,
  }) async {
    final key = _key(latitude, longitude);
    return _store[key] ?? [];
  }

  @override
  Future<void> cacheForecast(List<WeatherData> forecasts) async {
    if (forecasts.isEmpty) return;
    final f = forecasts.first;
    final key = _key(f.latitude, f.longitude);
    _store[key] = forecasts;
  }

  @override
  Future<int> purgeExpired() async {
    purgeCallCount++;
    return 0;
  }

  String _key(double lat, double lng) =>
      '${(lat * 100).round()}_${(lng * 100).round()}';
}

/// Previsions de test — 2 jours en haute montagne Corse.
final _testForecasts = [
  const WeatherData(
    date: '2026-07-10',
    latitude: 42.15,
    longitude: 9.10,
    temperatureMin: 11.0,
    temperatureMax: 22.0,
    precipitationMm: 0.0,
    precipitationProbability: 5,
    weatherCode: 0,
    windSpeedMax: 12.0,
    uvIndexMax: 9.0,
  ),
  const WeatherData(
    date: '2026-07-11',
    latitude: 42.15,
    longitude: 9.10,
    temperatureMin: 9.0,
    temperatureMax: 19.0,
    precipitationMm: 8.5,
    precipitationProbability: 70,
    weatherCode: 61,
    windSpeedMax: 30.0,
    uvIndexMax: 4.0,
  ),
];

void main() {
  group('WeatherRepository', () {
    late FakeWeatherApiService fakeApi;
    late FakeWeatherCacheStore fakeCache;
    late WeatherRepository repo;

    setUp(() {
      fakeApi = FakeWeatherApiService();
      fakeCache = FakeWeatherCacheStore();
      repo = WeatherRepository(
        apiService: fakeApi,
        cacheStore: fakeCache,
      );
    });

    test('retourne le cache quand disponible, sans appeler l\'API', () async {
      // Pre-remplir le cache
      await fakeCache.cacheForecast(_testForecasts);

      final result = await repo.getForecast(
        latitude: 42.15,
        longitude: 9.10,
      );

      // Resultat depuis le cache
      expect(result, hasLength(2));
      expect(result[0].date, '2026-07-10');
      expect(result[1].date, '2026-07-11');

      // API jamais appelee
      expect(fakeApi.callCount, 0);
    });

    test('appelle l\'API et cache le resultat quand cache vide', () async {
      // API retourne les previsions
      fakeApi.nextResult = _testForecasts;

      final result = await repo.getForecast(
        latitude: 42.15,
        longitude: 9.10,
      );

      // Resultat depuis l'API
      expect(result, hasLength(2));
      expect(result[0].temperatureMax, 22.0);
      expect(result[1].precipitationMm, 8.5);

      // API appelee une fois
      expect(fakeApi.callCount, 1);

      // Verifie que le cache est rempli
      final cached = await fakeCache.getCachedForecast(
        latitude: 42.15,
        longitude: 9.10,
      );
      expect(cached, hasLength(2));
    });

    test('retourne liste vide quand API echoue et cache vide', () async {
      fakeApi.nextError = WeatherApiException('timeout');

      final result = await repo.getForecast(
        latitude: 42.15,
        longitude: 9.10,
      );

      expect(result, isEmpty);
      expect(fakeApi.callCount, 1);
    });

    test('cache-first: second appel utilise le cache', () async {
      fakeApi.nextResult = _testForecasts;

      // Premier appel — API
      await repo.getForecast(latitude: 42.15, longitude: 9.10);
      expect(fakeApi.callCount, 1);

      // Deuxieme appel — cache
      final result = await repo.getForecast(
        latitude: 42.15,
        longitude: 9.10,
      );
      expect(result, hasLength(2));
      expect(fakeApi.callCount, 1); // Pas d'appel supplementaire
    });
  });
}
