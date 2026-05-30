import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/daos/weather_cache_dao.dart';
import '../../../core/network/connectivity_monitor.dart';
import '../../../core/providers/database_provider.dart';
import '../data/weather_service.dart';
import '../models/weather_alert.dart';
import '../models/weather_forecast.dart';

/// Provider du service meteo
final weatherServiceProvider = Provider<WeatherService>((ref) {
  final service = WeatherService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Provider du DAO cache meteo
final weatherCacheDaoProvider = Provider<WeatherCacheDao>((ref) {
  return WeatherCacheDao(ref.watch(databaseProvider));
});

/// Etat de la meteo pour une etape
class WeatherState {
  const WeatherState({
    this.forecast,
    this.alerts = const [],
    this.isLoading = false,
    this.isFromCache = false,
    this.errorMessage,
  });

  final WeatherForecast? forecast;
  final List<WeatherAlert> alerts;
  final bool isLoading;
  final bool isFromCache;
  final String? errorMessage;

  WeatherState copyWith({
    WeatherForecast? forecast,
    List<WeatherAlert>? alerts,
    bool? isLoading,
    bool? isFromCache,
    String? errorMessage,
  }) {
    return WeatherState(
      forecast: forecast ?? this.forecast,
      alerts: alerts ?? this.alerts,
      isLoading: isLoading ?? this.isLoading,
      isFromCache: isFromCache ?? this.isFromCache,
      errorMessage: errorMessage,
    );
  }
}

/// Provider famille pour la meteo d'une etape
final weatherProvider =
    NotifierProvider.family<WeatherNotifier, WeatherState, WeatherStageParams>(
        WeatherNotifier.new);

/// Parametres pour identifier une etape meteo
class WeatherStageParams {
  const WeatherStageParams({
    required this.trailId,
    required this.stageNumber,
    required this.latitude,
    required this.longitude,
  });

  final String trailId;
  final int stageNumber;
  final double latitude;
  final double longitude;

  @override
  bool operator ==(Object other) =>
      other is WeatherStageParams &&
      trailId == other.trailId &&
      stageNumber == other.stageNumber;

  @override
  int get hashCode => Object.hash(trailId, stageNumber);
}

/// Notifier pour charger la meteo d'une etape (cache -> API -> cache)
class WeatherNotifier extends FamilyNotifier<WeatherState, WeatherStageParams> {
  late WeatherService _service;
  late WeatherCacheDao _cacheDao;
  late ConnectivityStatus _connectivity;

  @override
  WeatherState build(WeatherStageParams arg) {
    _service = ref.watch(weatherServiceProvider);
    _cacheDao = ref.watch(weatherCacheDaoProvider);
    _connectivity =
        ref.watch(connectivityProvider).valueOrNull ?? ConnectivityStatus.offline;
    _loadWeather();
    return const WeatherState(isLoading: true);
  }

  /// Charge la meteo : cache d'abord, puis API si en ligne
  Future<void> _loadWeather() async {
    // 1. Verifier le cache
    final cached = await _cacheDao.getValidCache(
      arg.trailId,
      arg.stageNumber,
    );

    if (cached != null) {
      try {
        final json = jsonDecode(cached.forecastJson) as Map<String, dynamic>;
        final forecast = WeatherForecast.fromJson(json);
        final alerts = WeatherAlert.fromForecast(forecast);
        state = WeatherState(
          forecast: forecast,
          alerts: alerts,
          isFromCache: true,
        );
        return;
      } catch (_) {
        // Cache corrompu - continuer vers l'API
      }
    }

    // 2. Appel API si en ligne
    if (_connectivity == ConnectivityStatus.online) {
      await refresh();
    } else {
      state = const WeatherState(
        errorMessage: 'Pas de connexion. Donnees meteo indisponibles.',
      );
    }
  }

  /// Force le rechargement depuis l'API
  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);

    final forecast = await _service.fetchForecast(
      latitude: arg.latitude,
      longitude: arg.longitude,
    );

    if (forecast != null) {
      // Sauvegarder en cache
      await _cacheDao.upsertForecast(
        trailId: arg.trailId,
        stageNumber: arg.stageNumber,
        forecastJson: jsonEncode(forecast.toJson()),
      );

      final alerts = WeatherAlert.fromForecast(forecast);
      state = WeatherState(
        forecast: forecast,
        alerts: alerts,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Impossible de charger la meteo.',
      );
    }
  }
}
