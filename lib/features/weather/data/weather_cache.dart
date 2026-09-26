import 'dart:convert';

import 'package:logger/logger.dart';

import '../../../core/data/daos/weather_cache_dao.dart';
import '../models/weather_forecast.dart';

final _log = Logger(printer: PrettyPrinter(methodCount: 0));

/// Cache meteo : decide QUAND rappeler le fournisseur, jamais CE QU'ON AFFICHE.
///
/// Encapsule le [WeatherCacheDao] Drift. Deux lectures, et la distinction est
/// tout l'objet de la tache 572 :
///
///   * [getFreshForecast] — le bulletin s'il est encore FRAIS ([cacheTtl]).
///     Sert a economiser un appel reseau (rate limit #81812 I6).
///   * [getLastKnownForecast] — le DERNIER bulletin connu, frais ou pas.
///     Sert a ne jamais laisser le randonneur devant un ecran vide alors qu'il a
///     le bulletin dans son telephone. L'age est joint au bulletin
///     ([WeatherForecast.fetchedAt]) et l'ecran l'affiche : un bulletin de trois
///     jours ANNONCE comme tel est une information ; le meme bulletin affiche
///     comme frais serait le mensonge que Chris a nomme.
///
/// UN SEUL TTL (tache 572). Il y en avait DEUX, et ils ne disaient pas la meme
/// chose : `WeatherCache` filtrait a 1 h, `WeatherCacheDao` ecrivait
/// `expiresAt = fetchedAt + 3 h` et filtrait dessus. Le plus court gagnait en
/// silence, donc les trois heures ecrites dans la table n'ont jamais rien
/// gouverne. Le TTL est desormais celui du DAO ([WeatherCacheDao.cacheTtlHours])
/// et il n'y en a plus qu'un.
class WeatherCache {
  WeatherCache({
    required WeatherCacheDao dao,
    Duration? cacheTtl,
  })  : _dao = dao,
        _cacheTtl = cacheTtl ??
            const Duration(hours: WeatherCacheDao.cacheTtlHours);

  final WeatherCacheDao _dao;

  /// Fenetre pendant laquelle on NE RAPPELLE PAS le fournisseur.
  final Duration _cacheTtl;

  /// Duree de validite du cache exposee pour les tests
  Duration get cacheTtl => _cacheTtl;

  /// Recupere la prevision en cache pour une etape SI elle est encore fraiche.
  ///
  /// Retourne null si le cache est vide ou depasse [cacheTtl]. Ne sert qu'a
  /// decider d'un appel reseau — pour l'affichage, voir [getLastKnownForecast].
  Future<WeatherForecast?> getFreshForecast({
    required String trailId,
    required int stageNumber,
  }) async {
    final last = await getLastKnownForecast(
      trailId: trailId,
      stageNumber: stageNumber,
    );
    if (last?.fetchedAt == null) return null;
    final age = DateTime.now().difference(last!.fetchedAt!);
    if (age > _cacheTtl) {
      _log.d('[WeatherCache] Cache expire pour $trailId/$stageNumber '
          '(age ${age.inMinutes} min)');
      return null;
    }
    return last;
  }

  /// Recupere le DERNIER bulletin connu d'une etape, frais ou perime.
  ///
  /// L'instant du releve vient de la colonne `fetchedAt` de la ligne Drift : la
  /// DB fait autorite sur l'age, meme pour une ligne ecrite avant la tache 572
  /// (dont le JSON ne porte pas encore le champ).
  Future<WeatherForecast?> getLastKnownForecast({
    required String trailId,
    required int stageNumber,
  }) async {
    try {
      final cached = await _dao.getLastCache(trailId, stageNumber);
      if (cached == null) return null;
      final json = jsonDecode(cached.forecastJson) as Map<String, dynamic>;
      return WeatherForecast.fromJson(json).withFetchedAt(cached.fetchedAt);
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

  // TACHE 572 — `clearExpired()` et `clearByTrailId()` ont ete RETIREES : aucun
  // appelant dans toute l'application (la purge de retention passe directement
  // par le DAO). Le reaudit demandait de retirer ce qui ne sert a rien plutot
  // que de le garder par prudence.
}
