import 'dart:convert';

import 'package:logger/logger.dart';

import '../../../core/data/daos/weather_cache_dao.dart';
import '../models/weather_forecast.dart';

final _log = Logger(printer: PrettyPrinter(methodCount: 0));

/// Cache meteo avec rate limit 1h (#81812 I6).
///
/// Encapsule le [WeatherCacheDao] Drift avec un TTL de 1 heure.
/// Toute requete API dans la fenetre de 1h est servie depuis le cache.
class WeatherCache {
  WeatherCache({
    required WeatherCacheDao dao,
    Duration? cacheTtl,
  })  : _dao = dao,
        _cacheTtl = cacheTtl ?? const Duration(hours: 1);

  final WeatherCacheDao _dao;

  /// Duree de validite du cache (rate limit 1h par defaut)
  final Duration _cacheTtl;

  /// Duree de validite du cache exposee pour les tests
  Duration get cacheTtl => _cacheTtl;

  /// Recupere la prevision en cache pour une etape (si non expiree).
  ///
  /// Retourne null si le cache est vide ou expire (> 1h).
  Future<WeatherForecast?> getCachedForecast({
    required String trailId,
    required int stageNumber,
  }) async {
    try {
      final cached = await _dao.getValidCache(trailId, stageNumber);
      if (cached == null) return null;

      // Verifier le TTL 1h (rate limit #81812 I6)
      final age = DateTime.now().difference(cached.fetchedAt);
      if (age > _cacheTtl) {
        _log.d('[WeatherCache] Cache expire pour $trailId/$stageNumber');
        return null;
      }

      final json = jsonDecode(cached.forecastJson) as Map<String, dynamic>;
      return WeatherForecast.fromJson(json);
    } catch (e) {
      _log.w('[WeatherCache] Erreur lecture cache: $e');
      return null;
    }
  }

  /// Sauvegarde une prevision en cache avec le TTL 1h.
  Future<void> saveForecast({
    required String trailId,
    required int stageNumber,
    required WeatherForecast forecast,
  }) async {
    try {
      await _dao.upsertForecast(
        trailId: trailId,
        stageNumber: stageNumber,
        forecastJson: jsonEncode(forecast.toJson()),
      );
    } catch (e) {
      _log.w('[WeatherCache] Erreur sauvegarde cache: $e');
    }
  }

  /// Supprime tout le cache expire
  Future<int> clearExpired() => _dao.clearExpired();

  /// Supprime le cache d'un sentier
  Future<int> clearByTrailId(String trailId) =>
      _dao.clearByTrailId(trailId);
}
