import 'package:logger/logger.dart';

import '../../../core/data/daos/stages_dao.dart';
import '../models/weather_forecast.dart';
import 'weather_api_service.dart';
import 'weather_cache.dart';

final _log = Logger(printer: PrettyPrinter(methodCount: 0));

/// Resultat NOMME d'un rafraichissement force (tache 572, U2/U3).
///
/// `Future<WeatherForecast?>` ne suffisait pas : `null` confondait « le reseau a
/// echoue » et « cette etape n'existe pas », et un bulletin non nul ne disait pas
/// s'il venait d'etre releve ou s'il sortait du cache faute de reseau. L'ecran
/// avait donc besoin d'une information qu'il n'avait pas pour dire la verite au
/// randonneur — et il se taisait.
class WeatherRefreshResult {
  const WeatherRefreshResult({
    required this.forecast,
    required this.failed,
    this.reason,
  });

  /// Rafraichissement reussi : bulletin neuf.
  const WeatherRefreshResult.refreshed(WeatherForecast forecast)
      : this(forecast: forecast, failed: false);

  /// Echec du rafraichissement. [forecast] porte le dernier bulletin connu s'il
  /// en existe un (l'ecran garde son contenu et affiche son age), `null` sinon.
  const WeatherRefreshResult.failure({
    WeatherForecast? lastKnown,
    required String reason,
  }) : this(forecast: lastKnown, failed: true, reason: reason);

  /// Bulletin a afficher apres l'operation (neuf, ou dernier connu).
  final WeatherForecast? forecast;

  /// Vrai si la mise a jour n'a PAS abouti — l'ecran doit le DIRE.
  final bool failed;

  /// Cause technique de l'echec (journal / diagnostic, jamais affichee brute).
  final String? reason;

  /// Vrai si l'ecran a quand meme quelque chose a montrer.
  bool get hasData => forecast != null;
}

/// Repository meteo : orchestre API + cache + coordonnees dynamiques.
///
/// LE POINT ECHANTILLONNE EST L'ARRIVEE DE L'ETAPE (tache 572, U1). Avant, la
/// prevision etait demandee aux coordonnees de DEPART (`startLat`/`startLng`).
/// Ce que le randonneur veut savoir, verbatim de Chris, c'est « la meteo a
/// l'endroit ou on est cense se trouver le lendemain » : l'endroit ou il DORT au
/// bout de la journee, celui qui porte un nom (`arrivalName`) et qu'on affiche a
/// l'ecran. Echantillonner le depart tout en nommant l'arrivee aurait donne un
/// bulletin pour un autre lieu — en montagne, quinze kilometres et huit cents
/// metres de denivele plus loin, ce n'est pas la meme temperature. Le nom affiche
/// et les coordonnees interrogees decrivent desormais le MEME point.
///
/// Strategie de lecture (tache 572) :
///   1. cache FRAIS -> retour direct, aucun appel reseau ;
///   2. sinon appel Open-Meteo, mise en cache, retour ;
///   3. si l'appel echoue -> DERNIER bulletin connu, quel que soit son age, avec
///      son instant de releve pour que l'ecran affiche sa fraicheur.
///      L'etape 3 est la reponse au « pas de reseau sur le sentier » : le TTL
///      gouverne le re-telechargement, jamais le droit d'afficher.
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

  /// Recupere la prevision meteo d'une etape, au point d'ARRIVEE de l'etape.
  ///
  /// Coordonnees dynamiques depuis Drift (endLat/endLng). Cache-first avec
  /// repli sur le dernier bulletin connu quand le reseau manque. Retourne null
  /// seulement si l'etape n'existe pas en base ET qu'aucun bulletin n'a jamais
  /// ete enregistre pour elle.
  Future<WeatherForecast?> getForecast({
    required String trailId,
    required int stageNumber,
  }) async {
    // 1. Cache encore frais : aucun appel reseau (rate limit #81812 I6).
    final fresh = await _cache.getFreshForecast(
      trailId: trailId,
      stageNumber: stageNumber,
    );
    if (fresh != null) {
      _log.d('[WeatherRepository] Cache frais pour $trailId/$stageNumber');
      return fresh;
    }

    // 2. Coordonnees dynamiques depuis Drift, point d'ARRIVEE de l'etape.
    final stage = await _stagesDao.getByStageNumber(trailId, stageNumber);
    if (stage == null) {
      _log.w('[WeatherRepository] Etape $trailId/$stageNumber introuvable');
      // L'etape est inconnue mais un bulletin a peut-etre ete enregistre avant
      // (base rechargee) : on ne jette pas ce qu'on a.
      return _cache.getLastKnownForecast(
        trailId: trailId,
        stageNumber: stageNumber,
      );
    }

    final forecast = await _apiService.fetchForecast(
      latitude: stage.endLat,
      longitude: stage.endLng,
    );

    // 3. Appel echoue : le DERNIER bulletin connu vaut mieux qu'un ecran vide.
    if (forecast == null) {
      _log.w('[WeatherRepository] API echec pour $trailId/$stageNumber, '
          'repli sur le dernier bulletin connu');
      return _cache.getLastKnownForecast(
        trailId: trailId,
        stageNumber: stageNumber,
      );
    }

    await _cache.saveForecast(
      trailId: trailId,
      stageNumber: stageNumber,
      forecast: forecast,
    );

    _log.d('[WeatherRepository] API + cache OK pour $trailId/$stageNumber');
    return forecast;
  }

  /// Force le rafraichissement en ignorant le cache (bouton « Actualiser » et
  /// pull-to-refresh).
  ///
  /// Rend un resultat NOMME : l'ecran doit pouvoir distinguer une mise a jour
  /// reussie d'une mise a jour ratee, sinon un bouton qui echoue est
  /// indistinguable d'un bouton qui reussit — et c'est exactement le « ne
  /// produit rien » de Chris.
  Future<WeatherRefreshResult> refreshForecast({
    required String trailId,
    required int stageNumber,
  }) async {
    Future<WeatherForecast?> lastKnown() => _cache.getLastKnownForecast(
          trailId: trailId,
          stageNumber: stageNumber,
        );

    final stage = await _stagesDao.getByStageNumber(trailId, stageNumber);
    if (stage == null) {
      return WeatherRefreshResult.failure(
        lastKnown: await lastKnown(),
        reason: 'etape $trailId/$stageNumber introuvable en base',
      );
    }

    final forecast = await _apiService.fetchForecast(
      latitude: stage.endLat,
      longitude: stage.endLng,
    );

    if (forecast == null) {
      return WeatherRefreshResult.failure(
        lastKnown: await lastKnown(),
        reason: 'appel Open-Meteo sans reponse exploitable',
      );
    }

    await _cache.saveForecast(
      trailId: trailId,
      stageNumber: stageNumber,
      forecast: forecast,
    );
    return WeatherRefreshResult.refreshed(forecast);
  }

  /// Libere les ressources
  void dispose() {
    _apiService.dispose();
  }
}
