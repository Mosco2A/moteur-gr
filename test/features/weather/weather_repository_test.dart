import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';

import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/data/daos/stages_dao.dart';
import 'package:moteur_gr/core/data/daos/weather_cache_dao.dart';
import 'package:moteur_gr/features/weather/data/weather_api_service.dart';
import 'package:moteur_gr/features/weather/data/weather_cache.dart';
import 'package:moteur_gr/features/weather/data/weather_repository.dart';

/// Reponse Open-Meteo simulee pour les tests
const _mockApiResponse = {
  'latitude': 42.18,
  'longitude': 9.12,
  'daily': {
    'time': ['2026-06-01', '2026-06-02', '2026-06-03'],
    'temperature_2m_max': [25.0, 22.0, 28.0],
    'temperature_2m_min': [12.0, 10.0, 15.0],
    'precipitation_sum': [0.0, 5.0, 0.0],
    'wind_speed_10m_max': [15.0, 25.0, 10.0],
    'uv_index_max': [7.0, 5.0, 9.0],
    'weather_code': [0, 61, 1],
  },
};

/// Tests E3.5a : API mock + expiration cache 1h.
void main() {
  late AppDatabase db;
  late StagesDao stagesDao;
  late WeatherCacheDao weatherCacheDao;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    stagesDao = StagesDao(db);
    weatherCacheDao = WeatherCacheDao(db);

    // Inserer une etape de test avec coordonnees dynamiques
    await stagesDao.insertAll([
      const StagesCompanion(
        trailId: Value('gr20'),
        stageNumber: Value(1),
        name: Value('Calenzana - Ortu di u Piobbu'),
        distanceKm: Value(12.0),
        elevationGainM: Value(1500),
        elevationLossM: Value(200),
        startLat: Value(42.508),
        startLng: Value(8.855),
        endLat: Value(42.472),
        endLng: Value(8.927),
      ),
    ]);
  });

  tearDown(() async {
    await db.close();
  });

  group('WeatherRepository -- API mock retourne previsions', () {
    test('fetchForecast via API mock retourne 3 jours de previsions', () async {
      // ARRANGE : client HTTP mock qui retourne la reponse Open-Meteo
      final mockClient = http_testing.MockClient((request) async {
        // Verifier que l'URL contient les coordonnees dynamiques
        expect(request.url.toString(), contains('latitude=42.508'));
        expect(request.url.toString(), contains('longitude=8.855'));
        return http.Response(
          jsonEncode(_mockApiResponse),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiService = WeatherApiService(client: mockClient);
      final cache = WeatherCache(dao: weatherCacheDao);
      final repo = WeatherRepository(
        apiService: apiService,
        cache: cache,
        stagesDao: stagesDao,
      );

      // ACT
      final forecast = await repo.getForecast(
        trailId: 'gr20',
        stageNumber: 1,
      );

      // ASSERT
      expect(forecast, isNotNull);
      expect(forecast!.days.length, 3);
      expect(forecast.days[0].temperatureMax, 25.0);
      expect(forecast.days[1].precipitationMm, 5.0);
      expect(forecast.days[2].weatherCode, 1);

      // Verifier que le cache a ete rempli
      final cached = await cache.getCachedForecast(
        trailId: 'gr20',
        stageNumber: 1,
      );
      expect(cached, isNotNull,
          reason: 'La prevision doit etre en cache apres l appel API');

      repo.dispose();
    });
  });

  group('WeatherCache -- expiration apres 1h', () {
    test('cache valide retourne la prevision, cache expire retourne null',
        () async {
      // ARRANGE : cache avec TTL 0 secondes pour simuler expiration
      final cacheExpired = WeatherCache(
        dao: weatherCacheDao,
        cacheTtl: Duration.zero,
      );
      final cacheValid = WeatherCache(
        dao: weatherCacheDao,
        cacheTtl: const Duration(hours: 2),
      );

      // Creer une prevision mock et la sauvegarder
      final mockClient = http_testing.MockClient((request) async {
        return http.Response(
          jsonEncode(_mockApiResponse),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final apiService = WeatherApiService(client: mockClient);

      // Sauvegarder via API pour remplir le cache
      final forecast = await apiService.fetchForecast(
        latitude: 42.508,
        longitude: 8.855,
      );
      expect(forecast, isNotNull);

      await cacheValid.saveForecast(
        trailId: 'gr20',
        stageNumber: 1,
        forecast: forecast!,
      );

      // ACT & ASSERT : cache avec TTL long => retourne la prevision
      final validResult = await cacheValid.getCachedForecast(
        trailId: 'gr20',
        stageNumber: 1,
      );
      expect(validResult, isNotNull,
          reason: 'Cache valide (TTL 2h) doit retourner la prevision');
      expect(validResult!.days.length, 3);

      // ACT & ASSERT : cache avec TTL 0 => expire immediatement
      final expiredResult = await cacheExpired.getCachedForecast(
        trailId: 'gr20',
        stageNumber: 1,
      );
      expect(expiredResult, isNull,
          reason: 'Cache expire (TTL 0s) doit retourner null');

      apiService.dispose();
    });
  });
}
