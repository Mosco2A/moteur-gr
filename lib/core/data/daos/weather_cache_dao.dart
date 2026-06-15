import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/weather_cache_table.dart';

part 'weather_cache_dao.g.dart';

/// DAO pour le cache météo.
///
/// Gère le stockage et la récupération des prévisions météo
/// avec un système de TTL (3 heures par défaut).
@DriftAccessor(tables: [WeatherCache])
class WeatherCacheDao extends DatabaseAccessor<AppDatabase>
    with _$WeatherCacheDaoMixin {
  WeatherCacheDao(super.db);

  /// TTL du cache météo en heures
  static const int cacheTtlHours = 3;

  /// Récupère la prévision en cache pour une étape (si non expirée)
  Future<WeatherCacheData?> getValidCache(
      String trailId, int stageNumber) async {
    final now = DateTime.now();
    final result = await (select(weatherCache)
          ..where((t) =>
              t.trailId.equals(trailId) &
              t.stageNumber.equals(stageNumber) &
              t.expiresAt.isBiggerThanValue(now))
          ..orderBy([(t) => OrderingTerm.desc(t.fetchedAt)])
          ..limit(1))
        .getSingleOrNull();
    return result;
  }

  /// Insère ou met à jour le cache météo pour une étape
  Future<void> upsertForecast({
    required String trailId,
    required int stageNumber,
    required String forecastJson,
  }) async {
    final now = DateTime.now();
    final expires = now.add(const Duration(hours: cacheTtlHours));

    // Supprimer l'ancien cache pour cette étape
    await (delete(weatherCache)
          ..where((t) =>
              t.trailId.equals(trailId) &
              t.stageNumber.equals(stageNumber)))
        .go();

    // Insérer le nouveau
    await into(weatherCache).insert(WeatherCacheCompanion(
      trailId: Value(trailId),
      stageNumber: Value(stageNumber),
      forecastJson: Value(forecastJson),
      fetchedAt: Value(now),
      expiresAt: Value(expires),
    ));
  }

  /// Supprime tout le cache expiré (expiresAt < [now]).
  ///
  /// [now] est injectable pour rester déterministe en test et pour partager
  /// la même horloge que la purge de rétention (D4B-02). Par défaut,
  /// l'horloge système. Ne supprime JAMAIS une entrée encore valide
  /// (expiresAt >= now) : le TTL de chaque entrée fait foi.
  Future<int> clearExpired([DateTime? now]) {
    final cutoff = now ?? DateTime.now();
    return (delete(weatherCache)
          ..where((t) => t.expiresAt.isSmallerThanValue(cutoff)))
        .go();
  }

  /// Supprime tout le cache d'un sentier
  Future<int> clearByTrailId(String trailId) {
    return (delete(weatherCache)
          ..where((t) => t.trailId.equals(trailId)))
        .go();
  }
}
