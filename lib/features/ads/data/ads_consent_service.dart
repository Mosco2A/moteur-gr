import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:logger/logger.dart';

import '../../../core/config/ad_config.dart';
import '../../../core/error/error_handler.dart';

final _log = Logger(printer: PrettyPrinter(methodCount: 0));

/// Service de CONSENTEMENT publicitaire (UMP/CMP) + init du SDK AdMob (A6).
///
/// Encapsule le User Messaging Platform de Google (RGPD/consentement pub, écran
/// de consentement) et l'initialisation `MobileAds`. Le flux (reco Google) :
///   1. `requestConsentInfoUpdate` (met à jour l'état de consentement) ;
///   2. `loadAndShowConsentFormIfRequired` (affiche l'écran CMP SI requis) ;
///   3. `canRequestAds()` décide si l'on a le droit de charger des pubs ;
///   4. `MobileAds.instance.initialize()` (une fois le consentement résolu).
///
/// Testable : les collaborateurs UMP/MobileAds sont injectables. En test, on
/// fournit un fake qui simule « consentement obtenu / non requis » sans réseau.
/// ZERO catch silencieux — toute erreur UMP est loggée via [ErrorHandler].
///
/// LE FORMULAIRE NE RECOUVRE PLUS L'APPLI EN PLEINE SESSION (tache 560, N3).
/// La campagne personas 559 l'a photographié par-dessus les Réglages, le
/// cockpit, le Programme et la carte de navigation — une vue NATIVE, donc
/// invisible à tout test Flutter : seules les captures l'ont montré. Trois
/// causes, trois verrous, et un constat mesuré plutôt que supposé.
///
///  1. IL ARRIVAIT TROP TARD. La séquence d'amorce est bornée à
///     [_bootTimeout] ; passé ce délai, `Future.timeout` rend la main mais
///     N'ANNULE PAS l'appel natif (l'API UMP n'offre aucune annulation). Le
///     formulaire finissait donc par s'afficher quand il voulait — et à ce
///     moment-là le randonneur était déjà sur un écran de travail. Le
///     formulaire n'est désormais demandé QUE SI le budget d'amorce n'est pas
///     déjà consommé quand on arrive à cette étape ([_formWithinBootWindow]) ;
///     sinon il est REPORTÉ au prochain démarrage, où il retombera sur l'écran
///     de chargement, à sa place.
///  2. IL POUVAIT ÊTRE DEMANDÉ PLUSIEURS FOIS. [ensureConsentAndInit] est
///     désormais À UN SEUL COUP par instance : le `Future` est mémorisé, donc
///     deux appels (deux `watch`, une re-souscription) partagent la MÊME
///     séquence UMP au lieu d'en lancer une seconde. Ce que le code seul
///     établit : `adsReadyProvider` est un `FutureProvider` legacy, donc
///     `isAutoDispose = false` sous Riverpod 3.3.2, et il est observé par une
///     garde qui ne se démonte jamais — la séquence tourne donc une fois par
///     PROCESSUS. Les quatre apparitions de la campagne viennent de onze
///     lancements, pas d'une boucle : un formulaire jamais répondu reste
///     « requis » et revient au lancement suivant.
///  3. IL DEMANDAIT UN CONSENTEMENT POUR UNE PUBLICITÉ QUI N'EXISTE PAS. Le
///     dépôt ne porte que les ad-units de TEST officiels Google et
///     l'App ID de TEST du manifeste ; les identifiants de production sont
///     injectés au build de release par `--dart-define`
///     ([AdConfig.hasProductionUnits]). Tout build de test — l'APK de Chris, les
///     onze runs de la campagne — posait donc une vraie question RGPD sur une
///     régie qui n'est pas branchée. C'est ce qu'établit le code, et c'est
///     vérifiable : le formulaire photographié s'intitule « Publisher Test
///     Ads ». Sans identifiants de production, plus aucun formulaire n'est
///     demandé. CONSÉQUENCE ASSUMÉE ET ÉCRITE : dans l'EEE, un build de test
///     sans consentement déjà enregistré n'affichera pas de bannière de test —
///     mieux vaut pas de bannière en debug qu'un formulaire par-dessus la carte.
class AdsConsentService {
  AdsConsentService({
    ConsentInformation? consentInformation,
    Future<void> Function(OnConsentFormDismissedListener)?
    loadAndShowIfRequired,
    Future<InitializationStatus> Function()? initializeAds,
    Future<void> Function(RequestConfiguration)? updateRequestConfiguration,
    List<String> testDeviceIds = const <String>[],
    Duration bootTimeout = _bootTimeout,
    bool? consentFormEnabled,
  }) : _bootBudget = bootTimeout,
       _consentInformation = consentInformation ?? ConsentInformation.instance,
       _loadAndShowIfRequired =
           loadAndShowIfRequired ??
           ConsentForm.loadAndShowConsentFormIfRequired,
       _initializeAds =
           initializeAds ?? (() => MobileAds.instance.initialize()),
       _updateRequestConfiguration =
           updateRequestConfiguration ??
           MobileAds.instance.updateRequestConfiguration,
       _testDeviceIds = testDeviceIds,
       _consentFormEnabled = consentFormEnabled ?? AdConfig.hasProductionUnits;

  final ConsentInformation _consentInformation;
  final Future<void> Function(OnConsentFormDismissedListener)
  _loadAndShowIfRequired;
  final Future<InitializationStatus> Function() _initializeAds;
  final Future<void> Function(RequestConfiguration) _updateRequestConfiguration;
  final List<String> _testDeviceIds;

  /// Vrai si ce build a le droit de MONTRER le formulaire de consentement pub.
  ///
  /// Par défaut [AdConfig.hasProductionUnits] : un build qui ne porte que les
  /// ad-units de test ne demande rien à personne. Injectable pour que le
  /// comportement des DEUX branches soit testable sans build de release.
  final bool _consentFormEnabled;

  /// Séquence d'amorce mémorisée : une seule par instance (verrou 2).
  Future<bool>? _boot;

  /// Nombre de fois que le formulaire UMP a réellement été DEMANDÉ.
  ///
  /// Sert de preuve mesurable : « demandé une fois, au bon moment, jamais
  /// par-dessus un écran de travail » ne se vérifie pas autrement depuis un
  /// test Flutter, puisque le formulaire lui-même est une vue native.
  int _consentFormRequests = 0;

  /// Voir [_consentFormRequests].
  int get consentFormRequests => _consentFormRequests;

  /// Vrai si le formulaire a été VOLONTAIREMENT reporté (hors fenêtre d'amorce,
  /// ou build sans identifiants de production). Aucun formulaire n'a alors été
  /// affiché, et rien n'est cassé : il sera redemandé au prochain démarrage.
  bool get consentFormDeferred => _consentFormDeferred;
  bool _consentFormDeferred = false;

  /// Délai réellement appliqué (cf. [_bootTimeout]). Injectable pour que le
  /// comportement d'un UMP/AdMob qui répond APRÈS l'échéance soit testable sans
  /// faire durer un test six secondes (FIX-2, finding M2).
  final Duration _bootBudget;

  bool _adsInitialized = false;

  /// Vrai une fois `MobileAds.initialize()` appelé avec succès.
  bool get adsInitialized => _adsInitialized;

  /// Délai maximum GLOBAL de la résolution consentement + init AdMob au boot.
  ///
  /// OFFLINE-FIRST (garde-fou boot) : les appels UMP
  /// (`requestConsentInfoUpdate`) et l'init native `MobileAds.initialize()`
  /// contactent les serveurs Google. HORS-LIGNE, l'API UMP à callbacks peut ne
  /// JAMAIS rappeler (ni succès, ni erreur) et l'init AdMob peut PENDRE — un
  /// `try/catch` ne rattrape pas un HANG. Sans borne, le `Future` d'amorce pub
  /// resterait pendant indéfiniment (fuite de ressource au boot, et risque de
  /// stalle si un jour ce provider était attendu). On borne donc TOUTE la
  /// séquence : au-delà du délai, on abandonne proprement (aucune pub, jamais de
  /// crash) — l'app est déjà rendue, la pub n'est pas critique offline.
  static const Duration _bootTimeout = Duration(seconds: 6);

  /// Résout le consentement pub (UMP/CMP) PUIS initialise le SDK si autorisé.
  ///
  /// Retourne `true` si les pubs peuvent être demandées ([canRequestAds]).
  /// Best-effort : une panne UMP ne bloque pas le démarrage de l'app — on
  /// n'initialise simplement pas les pubs (aucune pub affichée, jamais de crash).
  ///
  /// BORNÉ ([_bootTimeout], offline-first) : un UMP/AdMob qui pend hors-ligne ne
  /// laisse pas ce `Future` pendant — au-delà du délai on retourne `false`
  /// (pubs désactivées) sans crash.
  ///
  /// FIX-2 (finding M2) — AUCUNE ERREUR ASYNCHRONE NON GÉRÉE. `Future.timeout`
  /// ne « débranche » pas le `Future` source : quand celui-ci échoue APRÈS que
  /// le délai a expiré (cas normal en réseau lent — l'init AdMob finit par
  /// rendre une erreur alors que le timeout a déjà rendu la main), le résultat
  /// est déjà complété, et Dart signale cette erreur tardive à la zone comme
  /// erreur NON CAPTURÉE. Le `try/catch` ci-dessous ne la voyait pas : il
  /// n'attrapait que la `TimeoutException`. Résultat observé : une erreur
  /// silencieuse à chaque démarrage en réseau lent (remontée via Riverpod).
  /// On NEUTRALISE donc les erreurs du cœur AVANT de poser le délai
  /// ([_ensureConsentAndInitGuarded] ne se termine JAMAIS en erreur, qu'elle
  /// arrive avant ou après l'échéance) : il ne reste plus qu'une seule erreur
  /// possible, la `TimeoutException` du wrapper, et elle est attrapée ici.
  ///
  /// A UN SEUL COUP (tache 560, N3) : le `Future` est memorise. Deux appels sur
  /// la meme instance partagent la meme sequence UMP — jamais deux formulaires.
  /// Un resultat `false` est donc DEFINITIF pour ce processus : c'est voulu, la
  /// pub n'est pas critique et un formulaire ne se re-tente pas dans le dos du
  /// randonneur.
  Future<bool> ensureConsentAndInit() => _boot ??= _ensureConsentAndInitBounded();

  Future<bool> _ensureConsentAndInitBounded() async {
    _bootClock.reset();
    _bootClock.start();
    try {
      return await _ensureConsentAndInitGuarded().timeout(_bootBudget);
    } on TimeoutException {
      // ISSUE NORMALE ET PRÉVUE, PAS UNE PANNE (FIX-2, finding M2). Hors-ligne
      // ou en réseau lent, dépasser le budget d'amorce est le comportement
      // VOULU : on abandonne la pub et l'app démarre. La journaliser comme une
      // ERREUR réseau, pile d'appel comprise, faisait apparaître à CHAQUE
      // démarrage lent un pavé rouge indiscernable d'un plantage — c'est ce
      // pavé qui a été relevé comme « erreur silencieuse au boot ». On en fait
      // donc une ligne d'information explicite, sans pile.
      _log.i(
        '[AdsConsentService] Amorce pub abandonnée : budget de démarrage '
        '(${_bootBudget.inSeconds} s) dépassé — aucune publicité, démarrage '
        'normal. Cas attendu hors-ligne ou en réseau lent.',
      );
      return false;
    } on Object catch (e, st) {
      // Tout le reste = réellement inattendu : best-effort, on n'affiche pas de
      // pub et on ne casse jamais le boot, mais on le trace comme une erreur.
      ErrorHandler.log(
        e,
        stackTrace: st,
        context: 'AdsConsentService.ensureConsentAndInit',
      );
      return false;
    }
  }

  /// Cœur non borné, RENDU INFAILLIBLE : logue et retourne `false` au lieu de
  /// se terminer en erreur — y compris quand l'échec survient après l'échéance
  /// du délai posé par [ensureConsentAndInit] (sinon : erreur asynchrone non
  /// gérée, finding M2).
  Future<bool> _ensureConsentAndInitGuarded() {
    return _ensureConsentAndInitUnbounded().catchError(
      (Object e, StackTrace st) {
        ErrorHandler.log(
          e,
          stackTrace: st,
          context: 'AdsConsentService.ensureConsentAndInit',
        );
        return false;
      },
    );
  }

  /// Cœur non borné de la résolution consentement + init (cf. wrapper borné).
  Future<bool> _ensureConsentAndInitUnbounded() async {
    try {
      await _requestConsentInfoUpdate();
      await _loadFormIfRequired();
    } on Object catch (e, st) {
      ErrorHandler.log(
        e,
        stackTrace: st,
        context: 'AdsConsentService.ensureConsentAndInit',
      );
      // On tente quand même canRequestAds (un état caché peut exister).
    }

    final canRequest = await canRequestAds();
    if (canRequest && !_adsInitialized) {
      // L'init native AdMob peut échouer (réseau) : best-effort, jamais de pub
      // plutôt qu'une erreur remontée au boot. Sans ce garde, un échec survenu
      // APRÈS l'échéance du budget était purement PERDU (`Future.timeout`
      // abandonne l'erreur tardive du `Future` source, sans la signaler à
      // personne) : une panne réelle d'AdMob ne laissait aucune trace.
      try {
        await _initialize();
      } on Object catch (e, st) {
        ErrorHandler.log(
          e,
          stackTrace: st,
          context: 'AdsConsentService.initialize',
        );
        return false;
      }
    }
    return canRequest;
  }

  /// Met à jour l'état de consentement UMP (API à callbacks -> `Future`).
  Future<void> _requestConsentInfoUpdate() {
    final completer = Completer<void>();
    _consentInformation.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      completer.complete,
      (error) {
        // Échec UMP loggé mais NON bloquant (best-effort) : on complète.
        ErrorHandler.log(
          StateError('UMP update failed: ${error.message}'),
          context: 'AdsConsentService.requestConsentInfoUpdate',
        );
        if (!completer.isCompleted) completer.complete();
      },
    );
    return completer.future;
  }

  /// Chronomètre de la séquence d'amorce : sert à savoir si l'on est ENCORE à
  /// l'heure pour montrer un formulaire (verrou 1 de N3).
  final Stopwatch _bootClock = Stopwatch();

  /// Vrai si l'on est encore DANS la fenêtre d'amorce, donc si un formulaire
  /// afficherait par-dessus l'écran de chargement et non par-dessus un écran de
  /// travail.
  ///
  /// La marge (un quart du budget) tient compte du fait que le formulaire lui
  /// -même met du temps à se charger : arriver ici à 5,9 s sur un budget de 6 s,
  /// c'est arriver trop tard.
  bool get _formWithinBootWindow =>
      _bootClock.elapsed * 4 < _bootBudget * 3;

  /// Affiche l'écran de consentement (CMP) si l'UMP l'exige — ET SEULEMENT SI
  /// c'est le bon moment et le bon build (tache 560, N3).
  ///
  /// Deux refus possibles, tous deux tracés et JAMAIS silencieux :
  ///  - build sans identifiants de production : on ne demande pas un
  ///    consentement publicitaire pour une régie qui n'est pas branchée ;
  ///  - budget d'amorce déjà consommé : le formulaire tomberait sur un écran de
  ///    travail, on le reporte au prochain démarrage.
  Future<void> _loadFormIfRequired() async {
    if (!_consentFormEnabled) {
      _consentFormDeferred = true;
      _log.i(
        '[AdsConsentService] Formulaire de consentement pub NON demandé : ce '
        'build ne porte que des ad-units de TEST (aucun identifiant de '
        'production injecté). Aucune question RGPD posée pour une régie non '
        'branchée.',
      );
      return;
    }
    if (!_formWithinBootWindow) {
      _consentFormDeferred = true;
      _log.i(
        '[AdsConsentService] Formulaire de consentement pub REPORTÉ : le budget '
        "d'amorce (${_bootBudget.inSeconds} s) est déjà consommé "
        '(${_bootClock.elapsed.inMilliseconds} ms). L\'afficher maintenant le '
        "poserait par-dessus l'écran en cours d'utilisation ; il sera redemandé "
        'au prochain démarrage.',
      );
      return;
    }
    _consentFormRequests++;
    await _loadAndShowIfRequired((formError) {
      if (formError != null) {
        ErrorHandler.log(
          StateError('UMP form error: ${formError.message}'),
          context: 'AdsConsentService.loadForm',
        );
      }
    });
  }

  /// Vrai si l'app a le droit de charger des pubs (consentement résolu, UMP).
  Future<bool> canRequestAds() async {
    try {
      return await _consentInformation.canRequestAds();
    } on Object catch (e, st) {
      ErrorHandler.log(
        e,
        stackTrace: st,
        context: 'AdsConsentService.canRequestAds',
      );
      return false;
    }
  }

  /// Vrai si un point d'entrée « options de confidentialité » doit être proposé.
  Future<bool> isPrivacyOptionsRequired() async {
    try {
      final status = await _consentInformation
          .getPrivacyOptionsRequirementStatus();
      return status == PrivacyOptionsRequirementStatus.required;
    } on Object catch (e, st) {
      ErrorHandler.log(
        e,
        stackTrace: st,
        context: 'AdsConsentService.privacyOptions',
      );
      return false;
    }
  }

  /// Ré-ouvre l'écran des options de confidentialité pub (CMP).
  Future<void> showPrivacyOptionsForm() async {
    try {
      await ConsentForm.showPrivacyOptionsForm((formError) {
        if (formError != null) {
          ErrorHandler.log(
            StateError('UMP privacy form error: ${formError.message}'),
            context: 'AdsConsentService.privacyForm',
          );
        }
      });
    } on Object catch (e, st) {
      ErrorHandler.log(
        e,
        stackTrace: st,
        context: 'AdsConsentService.showPrivacyOptions',
      );
    }
  }

  /// Initialise le SDK AdMob (avec les test devices éventuels).
  Future<void> _initialize() async {
    if (_testDeviceIds.isNotEmpty) {
      await _updateRequestConfiguration(
        RequestConfiguration(testDeviceIds: _testDeviceIds),
      );
    }
    await _initializeAds();
    _adsInitialized = true;
  }
}
