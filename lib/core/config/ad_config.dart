import 'dart:io' show Platform;

/// Configuration centrale des identifiants publicitaires AdMob (StepWays L6/A6).
///
/// DOCTRINE (identique a l'App ID du `AndroidManifest`) : le MOTEUR ne porte
/// QUE les ad-unit IDs de TEST officiels Google (documentes, libres d'usage en
/// debug). Les ad-units de PRODUCTION sont injectes au build de release via
/// `--dart-define` (`ADMOB_BANNER_ANDROID`, `ADMOB_REWARDED_IOS`, ...), jamais
/// codes en dur dans le depot. Ainsi « brancher les vrais identifiants AdMob »
/// = le cablage complet + le point d'injection prod, sans fuite de SKU reel.
///
/// FORMATS AUTORISES (decision Chris #99305/#99370) : BANNIERES + RECOMPENSEES
/// UNIQUEMENT. PAS d'interstitiel — aucune API interstitielle n'est exposee ici.
abstract final class AdConfig {
  // --- Ad-units de TEST officiels Google (sandbox, surchargeables en prod) ---

  /// Banniere de test officielle (Android).
  static const String _testBannerAndroid =
      'ca-app-pub-3940256099942544/6300978111';

  /// Banniere de test officielle (iOS).
  static const String _testBannerIos = 'ca-app-pub-3940256099942544/2934735716';

  /// Recompensee de test officielle (Android).
  static const String _testRewardedAndroid =
      'ca-app-pub-3940256099942544/5224354917';

  /// Recompensee de test officielle (iOS).
  static const String _testRewardedIos =
      'ca-app-pub-3940256099942544/1712485313';

  // --- Injection PROD via --dart-define (vide par defaut => test) -----------

  static const String _prodBannerAndroid = String.fromEnvironment(
    'ADMOB_BANNER_ANDROID',
  );
  static const String _prodBannerIos = String.fromEnvironment(
    'ADMOB_BANNER_IOS',
  );
  static const String _prodRewardedAndroid = String.fromEnvironment(
    'ADMOB_REWARDED_ANDROID',
  );
  static const String _prodRewardedIos = String.fromEnvironment(
    'ADMOB_REWARDED_IOS',
  );

  // --- PUBS DE TEST VISIBLES SUR LE CANAL DE TEST (tache 639, DEM-260930-1224)

  /// Injecte par `--dart-define STEPWAYS_TEST_ADS=true` sur les builds du canal
  /// de test interne. JAMAIS en production — voir [testAdsForced], qui l'annule
  /// des qu'un ad-unit de prod est present.
  static const bool _testAdsRequested = bool.fromEnvironment(
    'STEPWAYS_TEST_ADS',
  );

  /// LE MODE « JE VEUX VOIR LES PUBS DE TEST » (tache 639, DEM-260930-1224).
  ///
  /// LA DEMANDE DE CHRISTOPHE, MOT POUR MOT (30/09 12:23) : « Et j aimerais voir
  /// les pubs sur la version de test ».
  ///
  /// CE QUI L'EN EMPECHAIT, MESURE. Trois verrous se combinaient, tous corrects
  /// pris un par un :
  ///   1. la regle d'or #99404 eteint la banniere sur un sentier ACHETE et
  ///      pendant les 24 h d'une recompense. Sans sentier gratuit au catalogue et
  ///      avec un sentier achete pour tester, il ne reste aucun ecran ou une
  ///      publicite soit autorisee ;
  ///   2. un build de test ne demande AUCUN consentement publicitaire
  ///      ([AdsConsentService], verrou 3 de la tache 560 : on ne pose pas une
  ///      question RGPD pour une regie qui n'est pas branchee). Dans l'EEE, sans
  ///      consentement enregistre, `canRequestAds()` rend `false` — donc aucune
  ///      publicite, meme de test. C'etait ECRIT comme consequence assumee ;
  ///   3. le budget d'amorce de 6 s abandonne la publicite hors ligne.
  /// Christophe avait vu une publicite le 29/09 parce qu'il testait le sentier de
  /// DEMONSTRATION, gratuit : le seul endroit ou la regle l'autorisait encore.
  ///
  /// CE QUE CE MODE FAIT, ET SES DEUX LIMITES. Il leve le verrou 1 pour tout sauf
  /// l'abonnement (« banniere et video de test visibles sur tout sentier tant
  /// qu'on n'est pas abonne ») et le verrou 2 en autorisant le formulaire de
  /// consentement avec une geographie de DEBUG. Il ne touche pas au verrou 3 :
  /// hors ligne, il n'y a pas de publicite, et c'est tres bien.
  ///
  /// IL NE PEUT PAS ETRE ACTIF EN PRODUCTION, ET CE N'EST PAS UNE PROMESSE MAIS
  /// UNE CONDITION : des qu'un ad-unit de PROD est injecte
  /// ([hasProductionUnits]), ce mode rend `false`, quel que soit le
  /// `--dart-define`. Un build de release porte ses vrais identifiants ; il ne
  /// peut donc pas emporter ce mode par accident, meme si la commande de build
  /// garde le drapeau.
  static bool get testAdsForced => _testAdsRequested && !hasProductionUnits;

  /// Vrai si au moins un ad-unit de prod a ete injecte (release).
  static bool get hasProductionUnits =>
      _prodBannerAndroid.isNotEmpty ||
      _prodBannerIos.isNotEmpty ||
      _prodRewardedAndroid.isNotEmpty ||
      _prodRewardedIos.isNotEmpty;

  /// Ad-unit BANNIERE pour la plateforme courante (prod si injecte, sinon test).
  static String bannerUnitId() {
    if (_isIos) {
      return _prodBannerIos.isNotEmpty ? _prodBannerIos : _testBannerIos;
    }
    return _prodBannerAndroid.isNotEmpty
        ? _prodBannerAndroid
        : _testBannerAndroid;
  }

  /// Ad-unit RECOMPENSEE pour la plateforme courante (prod si injecte, sinon test).
  static String rewardedUnitId() {
    if (_isIos) {
      return _prodRewardedIos.isNotEmpty ? _prodRewardedIos : _testRewardedIos;
    }
    return _prodRewardedAndroid.isNotEmpty
        ? _prodRewardedAndroid
        : _testRewardedAndroid;
  }

  /// Plateforme iOS ? (defaut Android hors iOS ; jamais d'exception en test).
  static bool get _isIos {
    try {
      return Platform.isIOS;
    } on Object {
      // Hors runtime natif (tests unitaires) : Android par defaut.
      return false;
    }
  }
}
