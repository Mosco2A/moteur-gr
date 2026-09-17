import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../../core/error/error_handler.dart';

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
class AdsConsentService {
  AdsConsentService({
    ConsentInformation? consentInformation,
    Future<void> Function(OnConsentFormDismissedListener)?
    loadAndShowIfRequired,
    Future<InitializationStatus> Function()? initializeAds,
    Future<void> Function(RequestConfiguration)? updateRequestConfiguration,
    List<String> testDeviceIds = const <String>[],
  }) : _consentInformation = consentInformation ?? ConsentInformation.instance,
       _loadAndShowIfRequired =
           loadAndShowIfRequired ??
           ConsentForm.loadAndShowConsentFormIfRequired,
       _initializeAds =
           initializeAds ?? (() => MobileAds.instance.initialize()),
       _updateRequestConfiguration =
           updateRequestConfiguration ??
           MobileAds.instance.updateRequestConfiguration,
       _testDeviceIds = testDeviceIds;

  final ConsentInformation _consentInformation;
  final Future<void> Function(OnConsentFormDismissedListener)
  _loadAndShowIfRequired;
  final Future<InitializationStatus> Function() _initializeAds;
  final Future<void> Function(RequestConfiguration) _updateRequestConfiguration;
  final List<String> _testDeviceIds;

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
  Future<bool> ensureConsentAndInit() async {
    try {
      return await _ensureConsentAndInitUnbounded().timeout(_bootTimeout);
    } on Object catch (e, st) {
      // TimeoutException (UMP/AdMob pendu hors-ligne) OU toute autre erreur :
      // best-effort, on n'affiche pas de pub et on ne casse jamais le boot.
      ErrorHandler.log(
        e,
        stackTrace: st,
        context: 'AdsConsentService.ensureConsentAndInit',
      );
      return false;
    }
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
      await _initialize();
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

  /// Affiche l'écran de consentement (CMP) si l'UMP l'exige.
  Future<void> _loadFormIfRequired() async {
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
