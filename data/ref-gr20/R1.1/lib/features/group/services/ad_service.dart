import 'package:flutter/foundation.dart';

/// Service de gestion publicitaire pour les suiveurs.
///
/// Monetisation au-dela de 2 suiveurs gratuits via interstitielle AdMob.
/// Les 2 premiers suiveurs (index 0 et 1) sont gratuits.
/// A partir du 3eme (index >= 2), une pub interstitielle est affichee
/// sauf si le suiveur a paye (isPaid).
class AdService {
  /// Nombre maximum de suiveurs gratuits (sans pub).
  static const int maxFreeFollowers = 2;

  /// ID d interstitielle AdMob (test en dev, production en release).
  @visibleForTesting
  static const String testAdUnitId =
      'ca-app-pub-3940256099942544/1033173712';

  /// Determine si une pub doit etre affichee avant l acces suivi.
  ///
  /// Retourne true si [followerIndex] >= 2 ET [isPaid] est false.
  /// Les index 0 et 1 sont toujours gratuits.
  static bool shouldShowAd({
    required int followerIndex,
    required bool isPaid,
  }) {
    if (isPaid) return false;
    return followerIndex >= maxFreeFollowers;
  }

  /// Charge et affiche une interstitielle AdMob.
  ///
  /// Appeler avant de donner acces au suivi pour le 3eme+ suiveur.
  /// En mode test, utilise [testAdUnitId].
  /// Retourne true si la pub a ete affichee, false sinon.
  Future<bool> showInterstitialAd() async {
    // Integration Google Mobile Ads (AdMob).
    // Le chargement reel est delegue au SDK google_mobile_ads
    // qui sera initialise dans main.dart via MobileAds.instance.initialize().
    //
    // Pattern:
    // 1. InterstitialAd.load(adUnitId, request, callback)
    // 2. Sur onAdLoaded -> ad.show()
    // 3. Sur onAdDismissedFullScreenContent -> continuer navigation
    //
    // Stub pour compilation sans SDK -- sera connecte quand
    // google_mobile_ads est ajoute au pubspec (#E4.13).
    return false;
  }
}
