import 'package:logger/logger.dart';

import '../domain/weather_data.dart';
import 'weather_api_service.dart';
import 'weather_cache.dart';

final _log = Logger(
  printer: PrettyPrinter(methodCount: 0),
  level: Level.debug,
);

/// Repository meteo — cache-first avec fallback API.
///
/// Strategie:
/// 1. Cherche dans le cache Drift (TTL 6h)
/// 2. Si cache vide ou expire → appel Open-Meteo
/// 3. Stocke la reponse API en cache
/// 4. Si API echoue → retourne liste vide
///
/// Utilise par [weatherForecastProvider] via Riverpod.
class WeatherRepository {
  WeatherRepository({
    required WeatherApiService apiService,
    required WeatherCacheStore cacheStore,
  })  : _api = apiService,
        _cache = cacheStore;

  final WeatherApiService _api;
  final WeatherCacheStore _cache;

  /// Recupere les previsions meteo pour une position GPS.
  ///
  /// [latitude] et [longitude] correspondent au point de depart
  /// ou centre d'une etape. Le cache arrondit a ~1km.
  ///
  /// Retourne une liste vide uniquement si l'API echoue
  /// ET qu'aucun cache (meme expire) n'est disponible.
  Future<List<WeatherData>> getForecast({
    required double latitude,
    required double longitude,
  }) async {
    // 1. Essayer le cache (non expire)
    final cached = await _cache.getCachedForecast(
      latitude: latitude,
      longitude: longitude,
    );

    if (cached.isNotEmpty) {
      _log.d('[WeatherRepo] Cache hit: ${cached.length} jours');
      return cached;
    }

    // 2. Appel API
    try {
      final forecasts = await _api.fetchForecast(
        latitude: latitude,
        longitude: longitude,
      );

      // 3. Stocker en cache
      await _cache.cacheForecast(forecasts);

      // Purge en arriere-plan (pas bloquant)
      // ignore: unawaited_futures
      _cache.purgeExpired().then(
            (_) {},
            onError: (Object e) =>
                _log.d('[WeatherRepo] Purge erreur: $e'),
          );

      _log.d('[WeatherRepo] API ok: ${forecasts.length} jours');
      return forecasts;
    } on WeatherApiException catch (e) {
      _log.d('[WeatherRepo] API erreur: $e');
      return [];
    }
  }
}
