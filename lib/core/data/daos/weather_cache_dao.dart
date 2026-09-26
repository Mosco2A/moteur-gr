import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/weather_cache_table.dart';

part 'weather_cache_dao.g.dart';

/// DAO pour le cache météo.
///
/// Gère le stockage et la récupération des prévisions météo
/// avec un système de TTL (3 heures par défaut).
///
/// TACHE 572 — LE TTL GOUVERNE LE RE-TELECHARGEMENT, PAS LE DROIT D'AFFICHER.
/// [getValidCache] filtre sur `expiresAt` : passe cette borne, la ligne devient
/// INVISIBLE. Pour un randonneur en montagne c'est la pire regle possible : il
/// telecharge sa meteo le matin au refuge, marche quatre heures sans reseau, et
/// l'application ne lui montre plus RIEN — pas meme le bulletin qu'il a dans le
/// telephone. [getLastCache] existe pour ca : elle rend la DERNIERE ligne connue
/// quel que soit son age, et c'est l'ECRAN qui affiche cet age (« releve il y a
/// 4 h, sans mise a jour depuis »). Un bulletin date n'est pas un mensonge ; un
/// bulletin absent oblige le randonneur a decider sans rien.
@DriftAccessor(tables: [WeatherCache])
class WeatherCacheDao extends DatabaseAccessor<AppDatabase>
    with _$WeatherCacheDaoMixin {
  WeatherCacheDao(super.db);

  /// TTL du cache météo en heures — borne du RE-TELECHARGEMENT.
  static const int cacheTtlHours = 3;

  /// Récupère la prévision en cache pour une étape (si non expirée).
  ///
  /// Sert la decision « faut-il rappeler le fournisseur ? ». Ne sert JAMAIS a
  /// decider de ce qu'on affiche (voir [getLastCache]).
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

  /// Récupère la DERNIERE prévision connue d'une étape, PERIMEE OU NON.
  ///
  /// C'est la lecture du hors-ligne (tache 572) : le dernier bulletin telecharge
  /// reste lisible, et son `fetchedAt` permet a l'ecran d'afficher son age. Ne
  /// jamais l'utiliser pour decider d'un appel reseau — c'est [getValidCache]
  /// qui porte le TTL.
  Future<WeatherCacheData?> getLastCache(
      String trailId, int stageNumber) async {
    return (select(weatherCache)
          ..where((t) =>
              t.trailId.equals(trailId) & t.stageNumber.equals(stageNumber))
          ..orderBy([(t) => OrderingTerm.desc(t.fetchedAt)])
          ..limit(1))
        .getSingleOrNull();
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

  /// Supprime les bulletins RELEVES avant [cutoff] (retention disque).
  ///
  /// TACHE 572 — REMPLACE `clearExpired` (qui purgeait sur `expiresAt`, donc
  /// trois heures apres le releve). LA POLITIQUE ECRITE ET LE CODE NE DISAIENT
  /// PAS LA MEME CHOSE : `RetentionPolicy.cartoCache` documente « caches
  /// carto/meteo : 7 jours » pendant que la purge effacait la meteo au bout de
  /// trois heures. C'est la politique ecrite qui a raison, et pas seulement sur
  /// le papier : effacer le bulletin trois heures apres son telechargement,
  /// c'est le retirer au randonneur precisement au moment ou il n'a plus de
  /// reseau pour le retelecharger.
  ///
  /// La purge porte donc sur `fetchedAt` (l'age reel du bulletin) et non sur
  /// `expiresAt` (la borne du re-telechargement). [cutoff] vient de l'appelant,
  /// qui partage son horloge avec le reste de la purge (D4B-02).
  Future<int> clearFetchedBefore(DateTime cutoff) {
    return (delete(weatherCache)
          ..where((t) => t.fetchedAt.isSmallerThanValue(cutoff)))
        .go();
  }
}
