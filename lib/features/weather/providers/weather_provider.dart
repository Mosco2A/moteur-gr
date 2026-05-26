import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/daos/weather_cache_dao.dart';
import '../../../core/network/connectivity_monitor.dart';
import '../../../core/providers/database_provider.dart';
import '../data/weather_service.dart';
import '../models/weather_alert.dart';
import '../models/weather_forecast.dart';

/// Provider du service météo
final weatherServiceProvider = Provider<WeatherService>((ref) {
  final service = WeatherService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Provider du DAO cache météo
final weatherCacheDaoProvider = Provider<WeatherCacheDao>((ref) {
  return WeatherCacheDao(ref.watch(databaseProvider));
});

/// État de la météo pour une étape
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

/// Provider famille pour la météo d'une étape
final weatherProvider = StateNotifierProvider.family<
    WeatherNotifier, WeatherState, WeatherStageParams>((ref, params) {
  return WeatherNotifier(
    ref.watch(weatherServiceProvider),
    ref.watch(weatherCacheDaoProvider),
    ref.watch(connectivityProvider).valueOrNull ?? ConnectivityStatus.offline,
    params,
  );
});

/// Paramètres pour identifier une étape météo
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

/// Notifier pour charger la météo d'une étape (cache -> API -> cache)
class WeatherNotifier extends StateNotifier<WeatherState> {
  WeatherNotifier(
    this._service,
    this._cacheDao,
    this._connectivity,
    this._params,
  ) : super(const WeatherState(isLoading: true)) {
    _loadWeather();
  }

  final WeatherService _service;
  final WeatherCacheDao _cacheDao;
  final ConnectivityStatus _connectivity;
  final WeatherStageParams _params;

  /// Charge la météo : cache d'abord, puis API si en ligne
  Future<void> _loadWeather() async {
    // 1. Vérifier le cache
    final cached = await _cacheDao.getValidCache(
      _params.trailId,
      _params.stageNumber,
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
        // Cache corrompu — continuer vers l'API
      }
    }

    // 2. Appel API si en ligne
    if (_connectivity == ConnectivityStatus.online) {
      await refresh();
    } else {
      state = const WeatherState(
        errorMessage: 'Pas de connexion. Données météo indisponibles.',
      );
    }
  }

  /// Force le rechargement depuis l'API
  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);

    final forecast = await _service.fetchForecast(
      latitude: _params.latitude,
      longitude: _params.longitude,
    );

    if (forecast != null) {
      // Sauvegarder en cache
      await _cacheDao.upsertForecast(
        trailId: _params.trailId,
        stageNumber: _params.stageNumber,
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
        errorMessage: 'Impossible de charger la météo.',
      );
    }
  }
}
