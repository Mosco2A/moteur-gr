import 'package:logger/logger.dart';

import '../../../core/data/daos/stages_dao.dart';
import '../models/weather_forecast.dart';
import 'weather_api_service.dart';
import 'weather_cache.dart';

final _log = Logger(printer: PrettyPrinter(methodCount: 0));

/// Repository meteo : orchestre API + cache + coordonnees dynamiques.
///
/// Strategie cache-first avec rate limit 1h (#81812 I6) :
/// 1. Cherche en cache (si < 1h, retour direct)
/// 2. Sinon appel API Open-Meteo
/// 3. Sauvegarde en cache pour le rate limit
///
/// Les coordonnees sont lues dynamiquement depuis la table Drift
/// [Stages] (pas de coordonnees en dur).
class WeatherRepository {
  WeatherRepository({
    required WeatherApiService apiService,
    required WeatherCache cache,
    required StagesDao stagesDao,
  })  : _apiService = apiService,
        _cache = cache,
        _stagesDao = stagesDao;

  final WeatherApiService _apiService;
  final WeatherCache _cache;
  final StagesDao _stagesDao;

  /// Recupere la prevision meteo pour une etape.
  ///
  /// Coordonnees dynamiques depuis Drift (startLat/startLng de l'etape).
  /// Rate limit 1h via [WeatherCache].
  /// Retourne null si l'etape n'existe pas en base ou si l'API echoue.
  Future<WeatherForecast?> getForecast({
    required String trailId,
    required int stageNumber,
  }) async {
    // 1. Verifier le cache (rate limit 1h)
    final cached = await _cache.getCachedForecast(
      trailId: trailId,
      stageNumber: stageNumber,
    );
    if (cached != null) {
      _log.d('[WeatherRepository] Cache hit pour $trailId/$stageNumber');
      return cached;
    }

    // 2. Recuperer les coordonnees dynamiques depuis Drift
    final stage = await _stagesDao.getByStageNumber(trailId, stageNumber);
    if (stage == null) {
      _log.w('[WeatherRepository] Etape $trailId/$stageNumber introuvable');
      return null;
    }

    // 3. Appel API avec coordonnees dynamiques
    final forecast = await _apiService.fetchForecast(
      latitude: stage.startLat,
      longitude: stage.startLng,
    );

    if (forecast == null) {
      _log.w('[WeatherRepository] API echec pour $trailId/$stageNumber');
      return null;
    }

    // 4. Sauvegarder en cache (rate limit 1h)
    await _cache.saveForecast(
      trailId: trailId,
      stageNumber: stageNumber,
      forecast: forecast,
    );

    _log.d('[WeatherRepository] API + cache OK pour $trailId/$stageNumber');
    return forecast;
  }

  /// Force le rafraichissement en ignorant le cache.
  ///
  /// Utile pour le pull-to-refresh de l'utilisateur.
  Future<WeatherForecast?> refreshForecast({
    required String trailId,
    required int stageNumber,
  }) async {
    final stage = await _stagesDao.getByStageNumber(trailId, stageNumber);
    if (stage == null) return null;

    final forecast = await _apiService.fetchForecast(
      latitude: stage.startLat,
      longitude: stage.startLng,
    );

    if (forecast != null) {
      await _cache.saveForecast(
        trailId: trailId,
        stageNumber: stageNumber,
        forecast: forecast,
      );
    }

    return forecast;
  }

  /// Libere les ressources
  void dispose() {
    _apiService.dispose();
  }
}
