import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../core/data/daos/stages_dao.dart';
import '../../../core/data/daos/trail_meteo_dao.dart';
import '../../../core/network/connectivity_monitor.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/services/ordonnanceur_de_synchronisation.dart';
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

/// Provider du DAO de la meteo deposee par le serveur (lot 625).
final trailMeteoDaoProvider = Provider<TrailMeteoDao>((ref) {
  return TrailMeteoDao(ref.watch(databaseProvider));
});

/// Provider du repository meteo — UNE LECTURE DE BASE, PLUS AUCUN APPEL SORTANT.
///
/// LE GESTE DE MISE A JOUR EST BRANCHE SUR L ORDONNANCEUR EXISTANT, pas sur un
/// second mecanisme. `OrdonnanceurDeSynchronisation` porte deja les deux reveils de
/// Christophe (retour du reseau, puis toutes les 4 heures), son verrou anti-chevauchement
/// et son perimetre « sentiers TELECHARGES ». La meteo etant une famille de donnees
/// de sentier depuis ce lot, elle descend dans ces passes sans qu on ait rien a
/// cadencer de plus.
final weatherRepositoryProvider = Provider<WeatherRepository>((ref) {
  return WeatherRepository(
    dao: ref.watch(trailMeteoDaoProvider),
    demanderUnePasse: () async {
      final ordonnanceur = ref.read(ordonnanceurDeSynchronisationProvider);
      // `passesExecutees` NE MONTE QUE SUR UNE PASSE REELLEMENT EXECUTEE : ni hors
      // ligne, ni pendant qu une autre passe tient deja le verrou. C est donc la
      // mesure exacte de « quelque chose a-t-il ete tente », et elle vient de
      // l ordonnanceur lui-meme plutot que d une seconde interrogation du reseau.
      final avant = ordonnanceur.passesExecutees;
      await ordonnanceur.passer('geste de mise a jour de la meteo');
      return ordonnanceur.passesExecutees > avant;
    },
  );
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
    this.jamaisRecue = false,
    this.errorMessage,
    this.refreshFailed = false,
    this.derniereIssue,
  });

  final WeatherForecast? forecast;
  final List<WeatherAlert> alerts;
  final bool isLoading;

  /// LE SERVEUR N A ENCORE RIEN DEPOSE POUR CETTE ETAPE SUR CE TELEPHONE.
  ///
  /// C EST LE CAS DU RANDONNEUR QUI N A JAMAIS EU DE RESEAU DEPUIS L INSTALLATION,
  /// et il doit etre PROPRE. Il remplace l ancien `isFromCache`, qui posait une
  /// question devenue sans objet (« ces chiffres viennent-ils du reseau ou du
  /// cache ? ») : ils viennent TOUJOURS de la base, puisque le serveur les y depose.
  /// La seule question qui reste est « en ai-je un, et de quand ? ».
  final bool jamaisRecue;

  /// Ce que la derniere demande de mise a jour a produit. `null` si aucune.
  final IssueMiseAJourMeteo? derniereIssue;

  /// Cause technique du dernier echec (journal). Jamais affichee brute : l'ecran
  /// en tire un message i18n (voir [refreshFailed]).
  final String? errorMessage;

  /// LA DERNIERE MISE A JOUR A ECHOUE — et l'ecran doit le DIRE (tache 572, U2).
  ///
  /// `errorMessage` existait deja, mais AUCUN widget du module ne le lisait :
  /// un rafraichissement rate etait donc visuellement identique a un
  /// rafraichissement reussi. Ce drapeau est la question que l'UI pose
  /// reellement (« dois-je afficher un echec ? ») et il est rendu a l'ecran.
  final bool refreshFailed;

  /// Copie. `errorMessage` et `refreshFailed` ne sont PAS conserves par defaut :
  /// un echec appartient a l'operation qui l'a produit, il ne doit pas survivre
  /// silencieusement a l'operation suivante (le passer explicitement le garde).
  WeatherState copyWith({
    WeatherForecast? forecast,
    List<WeatherAlert>? alerts,
    bool? isLoading,
    bool? jamaisRecue,
    String? errorMessage,
    bool refreshFailed = false,
    IssueMiseAJourMeteo? derniereIssue,
  }) {
    return WeatherState(
      forecast: forecast ?? this.forecast,
      alerts: alerts ?? this.alerts,
      isLoading: isLoading ?? this.isLoading,
      jamaisRecue: jamaisRecue ?? this.jamaisRecue,
      errorMessage: errorMessage,
      refreshFailed: refreshFailed,
      derniereIssue: derniereIssue ?? this.derniereIssue,
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

  @override
  WeatherState build() {
    // select() sur le repository — ne reconstruit que si l'instance change
    _repo = ref.watch(
      weatherRepositoryProvider.select((repo) => repo),
    );

    // LA CONNECTIVITE EST TOUJOURS OBSERVEE, MAIS ELLE NE DECLENCHE PLUS D APPEL —
    // ELLE DECLENCHE UNE RELECTURE. Au retour du reseau, l ordonnanceur lance sa
    // passe de son cote (c est SON evenement, lot 616) ; ce que cet ecran doit
    // faire, c est relire la base pour voir arriver ce que la passe y a pose. Deux
    // mecanismes qui reveilleraient le reseau au meme evenement, c est precisement
    // le second chemin que ce lot supprime.
    ref.watch(
      connectivityProvider.select(
        (asyncVal) => asyncVal.value ?? ConnectivityStatusValues.offline,
      ),
    );

    _lireLeBulletin();
    return const WeatherState(isLoading: true);
  }

  /// LIT LE BULLETIN EN BASE. AUCUN APPEL SORTANT, MEME EN LIGNE.
  Future<void> _lireLeBulletin() async {
    final bulletin = await _repo.bulletinDeLEtape(
      trailId: _params.trailId,
      stageNumber: _params.stageNumber,
    );

    if (bulletin != null) {
      state = WeatherState(
        forecast: bulletin,
        alerts: WeatherAlert.fromForecast(bulletin),
      );
      return;
    }

    // LE SERVEUR N A RIEN DEPOSE POUR CETTE ETAPE. Ce n est pas une erreur de
    // chargement, et l appeler ainsi serait faux : il n y a rien a charger. Le cas
    // est NOMME (`jamaisRecue`) pour que l ecran puisse expliquer au randonneur ce
    // qui va se passer — la meteo arrivera avec les donnees du sentier — au lieu de
    // lui montrer une roue ou un message d echec.
    state = const WeatherState(jamaisRecue: true);
  }

  /// DEMANDE AU SERVEUR CE QU IL A DE PLUS RECENT (bouton « Actualiser »,
  /// tire-pour-rafraichir).
  ///
  /// Rend `true` quand l operation a abouti — reception d un bulletin plus recent
  /// OU confirmation qu il n y a rien de plus recent. Les deux sont des succes, et
  /// c est la correction que ce lot apporte a la tache 572 : le cas le plus
  /// frequent d une cadence de quatre heures est « rien de neuf », et l annoncer
  /// comme un echec apprendrait au randonneur a ignorer le message.
  Future<bool> refresh() async {
    state = state.copyWith(isLoading: true);

    final resultat = await _repo.demanderLaMiseAJour(
      trailId: _params.trailId,
      stageNumber: _params.stageNumber,
    );

    final bulletin = resultat.bulletin;
    state = WeatherState(
      forecast: bulletin,
      alerts: bulletin == null ? const [] : WeatherAlert.fromForecast(bulletin),
      jamaisRecue: bulletin == null,
      refreshFailed: resultat.echoue,
      errorMessage: resultat.cause,
      derniereIssue: resultat.issue,
    );
    return !resultat.echoue;
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

// TACHE 572 — `weatherAlertsProvider`, `weatherLoadingProvider` et
// `weatherFromCacheProvider` ont ete RETIRES : trois providers derives
// « pour la performance UI » que RIEN dans l'application ne lisait. Le reaudit
// demandait de dire ce qui sert et de retirer le reste plutot que de le garder
// par prudence. Seul `weatherForecastProvider` a un consommateur reel
// (`all_stages_weather_list.dart`).

/// Toggle « alertes orage » de l'ecran meteo (RF-1, P7).
///
/// Etat leger en memoire (defaut : active). Quand desactive, le bandeau
/// n'affiche pas les alertes de type orage (les autres restent visibles).
final stormAlertsEnabledProvider = StateProvider<bool>((ref) => true);
