import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/weather_api_service.dart';
import '../data/weather_cache.dart';
import '../data/weather_repository.dart';
import '../domain/weather_data.dart';
import '../../../core/providers/database_provider.dart';

/// Provider du service API Open-Meteo.
///
/// Dispose le client HTTP automatiquement via ref.onDispose.
final weatherApiServiceProvider = Provider<WeatherApiService>((ref) {
  final service = WeatherApiService();
  ref.onDispose(service.dispose);
  return service;
});

/// Provider du cache meteo Drift.
final weatherCacheStoreProvider = Provider<WeatherCacheStore>((ref) {
  final db = ref.watch(databaseProvider);
  return DriftWeatherCacheDao(db);
});

/// Provider du repository meteo (cache-first + API).
final weatherRepositoryProvider = Provider<WeatherRepository>((ref) {
  return WeatherRepository(
    apiService: ref.watch(weatherApiServiceProvider),
    cacheStore: ref.watch(weatherCacheStoreProvider),
  );
});

/// Provider des previsions meteo pour une position GPS.
///
/// Parametre: (latitude, longitude) sous forme de record.
/// Retourne un Future avec la liste des previsions sur 7 jours.
///
/// Exemple d'utilisation:
/// ```dart
/// final forecast = ref.watch(
///   weatherForecastProvider((lat: 42.15, lng: 9.10)),
/// );
/// ```
final weatherForecastProvider = FutureProvider.family<
    List<WeatherData>, ({double lat, double lng})>((ref, coords) async {
  final repo = ref.watch(weatherRepositoryProvider);
  return repo.getForecast(
    latitude: coords.lat,
    longitude: coords.lng,
  );
});
