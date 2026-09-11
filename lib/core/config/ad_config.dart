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
