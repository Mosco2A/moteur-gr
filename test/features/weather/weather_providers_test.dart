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
import 'package:moteur_gr/features/weather/providers/weather_providers.dart';

/// Reponse Open-Meteo simulee pour les tests providers
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

/// Tests E3.5c : provider retourne donnees cache si offline.
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
        trailId: Value('sentier-bleu'),
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

  group('WeatherProviders -- cache offline', () {
    test('retourne donnees cache si offline', () async {
      // ARRANGE : remplir le cache via une requete API simulee
      final mockClient = http_testing.MockClient((request) async {
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

      // 1. Remplir le cache en simulant un appel online
      final forecast = await repo.getForecast(
        trailId: 'sentier-bleu',
        stageNumber: 1,
      );
      expect(forecast, isNotNull,
          reason: 'La prevision API doit fonctionner pour remplir le cache');
      expect(forecast!.days.length, 3);

      // 2. Simuler le mode offline : client qui echoue systematiquement
      final offlineClient = http_testing.MockClient((request) async {
        throw Exception('Pas de reseau');
      });

      final offlineApiService = WeatherApiService(client: offlineClient);
      final offlineRepo = WeatherRepository(
        apiService: offlineApiService,
        cache: cache,
        stagesDao: stagesDao,
      );

      // ACT : recuperer la meteo en mode offline (cache doit repondre)
      final cachedForecast = await offlineRepo.getForecast(
        trailId: 'sentier-bleu',
        stageNumber: 1,
      );

      // ASSERT : le cache retourne les donnees meme sans reseau
      expect(cachedForecast, isNotNull,
          reason: 'Le cache doit retourner les donnees en mode offline');
      expect(cachedForecast!.days.length, 3);
      expect(cachedForecast.days[0].temperatureMax, 25.0);
      expect(cachedForecast.days[1].precipitationMm, 5.0);
      expect(cachedForecast.days[2].weatherCode, 1);

      // Verifier que les params du provider sont corrects
      const params = WeatherStageParams(trailId: 'sentier-bleu', stageNumber: 1);
      expect(params.trailId, 'sentier-bleu');
      expect(params.stageNumber, 1);
      expect(params, equals(const WeatherStageParams(trailId: 'sentier-bleu', stageNumber: 1)));

      apiService.dispose();
      offlineApiService.dispose();
    });
  });
}
