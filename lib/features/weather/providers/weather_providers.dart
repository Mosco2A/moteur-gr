import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../core/data/daos/stages_dao.dart';
import '../../../core/data/daos/weather_cache_dao.dart';
import '../../../core/network/connectivity_monitor.dart';
import '../../../core/providers/database_provider.dart';
import '../data/weather_api_service.dart';
import '../data/weather_cache.dart';
import '../data/weather_repository.dart';
import '../models/weather_alert.dart';
import '../models/weather_forecast.dart';

// ---------------------------------------------------------------------------
// Providers Riverpod 3 pour la meteo (E3.5c)
//
// Convention : select() partout, zero ref.watch brut dans build.
// Auto-refresh quand la connectivite passe de offline a online.
// ---------------------------------------------------------------------------

/// Provider du DAO stages — coordonnees dynamiques.
final stagesDaoProvider = Provider<StagesDao>((ref) {
  return StagesDao(ref.watch(databaseProvider));
});

/// Provider du DAO cache meteo.
final weatherCacheDaoProvider = Provider<WeatherCacheDao>((ref) {
  return WeatherCacheDao(ref.watch(databaseProvider));
});

/// Provider du cache meteo avec TTL 1h.
final weatherCacheProvider = Provider<WeatherCache>((ref) {
  return WeatherCache(dao: ref.watch(weatherCacheDaoProvider));
});

/// Provider du service API Open-Meteo.
final weatherApiServiceProvider = Provider<WeatherApiService>((ref) {
  final service = WeatherApiService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Provider du repository meteo — orchestre API + cache + coordonnees.
final weatherRepositoryProvider = Provider<WeatherRepository>((ref) {
  final repo = WeatherRepository(
    apiService: ref.watch(weatherApiServiceProvider),
    cache: ref.watch(weatherCacheProvider),
    stagesDao: ref.watch(stagesDaoProvider),
  );
  ref.onDispose(() => repo.dispose());
  return repo;
});

/// Parametres pour identifier une etape meteo.
class WeatherStageParams {
  const WeatherStageParams({
    required this.trailId,
    required this.stageNumber,
  });

  final String trailId;
  final int stageNumber;

  @override
  bool operator ==(Object other) =>
      other is WeatherStageParams &&
      trailId == other.trailId &&
      stageNumber == other.stageNumber;

  @override
  int get hashCode => Object.hash(trailId, stageNumber);
}

/// Etat de la meteo pour une etape.
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

/// Notifier meteo Riverpod 3 avec auto-refresh sur reconnexion.
///
/// Strategie :
/// 1. Charge depuis le cache (offline-first)
/// 2. Si online, rafraichit via API
/// 3. Ecoute la connectivite via select() — auto-refresh a la reconnexion
///
/// Usage widget :
/// ```dart
/// final isLoading = ref.watch(
///   stageWeatherProvider(params).select((s) => s.isLoading),
/// );
/// final forecast = ref.watch(
///   stageWeatherProvider(params).select((s) => s.forecast),
/// );
/// ```
class StageWeatherNotifier extends Notifier<WeatherState> {
  // Riverpod 3 : FamilyNotifier retire (remplace par Notifier). Les parametres
  // de famille (trailId + stageNumber) sont recus par le CONSTRUCTEUR (pattern
  // officiel sans codegen) au lieu de build(WeatherStageParams arg). Aucun
  // changement de logique : _params remplace mecaniquement l'ancien arg.
  StageWeatherNotifier(this._params);

  final WeatherStageParams _params;

  late WeatherRepository _repo;
  late ConnectivityStatus _connectivity;

  @override
  WeatherState build() {
    // select() sur le repository — ne reconstruit que si l'instance change
    _repo = ref.watch(
      weatherRepositoryProvider.select((repo) => repo),
    );

    // select() sur la connectivite — ne reconstruit que sur changement de statut
    _connectivity = ref.watch(
      connectivityProvider.select(
        (asyncVal) => asyncVal.value ?? ConnectivityStatusValues.offline,
      ),
    );

    // Charger la meteo au build (cache-first)
    _loadWeather();
    return const WeatherState(isLoading: true);
  }

  /// Charge la meteo : repository cache-first, puis API si online.
  Future<void> _loadWeather() async {
    // 1. Tenter le cache via le repository
    final forecast = await _repo.getForecast(
      trailId: _params.trailId,
      stageNumber: _params.stageNumber,
    );

    if (forecast != null) {
      final alerts = WeatherAlert.fromForecast(forecast);
      state = WeatherState(
        forecast: forecast,
        alerts: alerts,
        isFromCache: _connectivity == ConnectivityStatusValues.offline,
      );
      return;
    }

    // 2. Pas de donnees disponibles
    if (_connectivity == ConnectivityStatusValues.offline) {
      state = const WeatherState(
        errorMessage: 'Pas de connexion. Donnees meteo indisponibles.',
      );
    } else {
      state = const WeatherState(
        errorMessage: 'Impossible de charger la meteo.',
      );
    }
  }

  /// Force le rafraichissement depuis l'API (pull-to-refresh).
  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);

    final forecast = await _repo.refreshForecast(
      trailId: _params.trailId,
      stageNumber: _params.stageNumber,
    );

    if (forecast != null) {
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

/// Provider famille pour la meteo d'une etape.
///
/// Auto-refresh via select() sur la connectivite :
/// quand le statut change (offline -> online), le build() est relance
/// et recharge les donnees depuis l'API.
final stageWeatherProvider = NotifierProvider.family<StageWeatherNotifier,
    WeatherState, WeatherStageParams>(StageWeatherNotifier.new);

// ---------------------------------------------------------------------------
// Providers derives avec select() pour performance UI
// ---------------------------------------------------------------------------

/// Provider derive : prevision seule (sans alertes ni loading).
/// Evite de reconstruire le widget si seules les alertes changent.
final weatherForecastProvider =
    Provider.family<WeatherForecast?, WeatherStageParams>((ref, params) {
  return ref.watch(
    stageWeatherProvider(params).select((s) => s.forecast),
  );
});

/// Provider derive : alertes seules.
/// Evite de reconstruire le widget si seule la prevision change.
final weatherAlertsProvider =
    Provider.family<List<WeatherAlert>, WeatherStageParams>((ref, params) {
  return ref.watch(
    stageWeatherProvider(params).select((s) => s.alerts),
  );
});

/// Provider derive : indicateur de chargement.
final weatherLoadingProvider =
    Provider.family<bool, WeatherStageParams>((ref, params) {
  return ref.watch(
    stageWeatherProvider(params).select((s) => s.isLoading),
  );
});

/// Provider derive : indicateur de donnees depuis le cache.
final weatherFromCacheProvider =
    Provider.family<bool, WeatherStageParams>((ref, params) {
  return ref.watch(
    stageWeatherProvider(params).select((s) => s.isFromCache),
  );
});

/// Toggle « alertes orage » de l'ecran meteo (RF-1, P7).
///
/// Etat leger en memoire (defaut : active). Quand desactive, le bandeau
/// n'affiche pas les alertes de type orage (les autres restent visibles).
final stormAlertsEnabledProvider = StateProvider<bool>((ref) => true);
