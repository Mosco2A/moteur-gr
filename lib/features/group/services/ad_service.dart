import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:logger/logger.dart';

import '../../../core/services/monetization_service.dart';

final _log = Logger(printer: PrettyPrinter(methodCount: 0));

/// Seuil de suiveurs gratuits (index 0 et 1 = gratuits, 2+ = pub).
/// Decision #81759.
const kFreeFollowerThreshold = 2;

/// Service de gestion publicitaire pour les suiveurs (E4.13).
///
/// Monetisation au-dela de 2 suiveurs gratuits via interstitielle
/// Google Mobile Ads (AdMob). Le 3eme suiveur et au-dela voient
/// une pub interstitielle avant d acceder au suivi, sauf s ils
/// ont paye (isPaid).
///
/// SANDBOX UNIQUEMENT : l ad unit par defaut est l ID de test
/// officiel AdMob — aucun chargement de pub reelle tant que
/// l application hote n injecte pas son propre adUnitId.
///
/// E4.13 — Dependances: E4.11 (FollowService).
class AdService {
  AdService({
    this.testMode = false,
  });

  /// Mode test pour desactiver le chargement reel des pubs.
  final bool testMode;

  InterstitialAd? _interstitialAd;
  bool _isAdLoaded = false;

  /// Determine si une pub doit etre affichee pour un suiveur.
  ///
  /// Retourne `true` si [followerIndex] >= 2 ET [isPaid] est `false`.
  /// Les index 0 et 1 sont gratuits, sans pub (#81759).
  ///
  /// [isPaid] est la DECISION sans-pub deja resolue — il NE doit PAS etre
  /// recalcule ici. La source unique app-wide (#99404) est
  /// [MonetizationService.isNoAdsActive] ; passer par [shouldShowAdForTrail]
  /// (ST7) pour resoudre cette decision a partir d'un [trailId] sans dupliquer
  /// la regle.
  bool shouldShowAd({
    required int followerIndex,
    required bool isPaid,
  }) {
    if (isPaid) return false;
    return followerIndex >= kFreeFollowerThreshold;
  }

  /// Variante app-wide branchee sur la SOURCE UNIQUE sans-pub (#99404, ST7).
  ///
  /// Resout la decision sans-pub via [MonetizationService.isNoAdsActive]
  /// (= `ownsTrail || isSubscriberActive || isRewardNoAdsActive`, vitrine
  /// incluse) puis delegue a [shouldShowAd]. AUCUNE regle recalculee ici : la
  /// seule verite est portee par [MonetizationService]. Le contrat rewarded
  /// (`grantRewardNoAds` / `isRewardNoAdsActive`, cote MonetizationService) est
  /// conserve pour le futur widget rewarded (L6).
  ///
  /// Async car [MonetizationService.isNoAdsActive] lit les droits Drift.
  Future<bool> shouldShowAdForTrail({
    required int followerIndex,
    required String trailId,
    required MonetizationService monetization,
  }) async {
    final noAds = await monetization.isNoAdsActive(trailId);
    return shouldShowAd(followerIndex: followerIndex, isPaid: noAds);
  }

  /// Pre-charge une interstitielle AdMob.
  ///
  /// A appeler en amont (ex: quand un 3eme suiveur rejoint)
  /// pour eviter les temps de chargement.
  Future<void> preloadInterstitial({String? adUnitId}) async {
    if (testMode) return;

    final unitId = adUnitId ?? _testAdUnitId;

    await InterstitialAd.load(
      adUnitId: unitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isAdLoaded = true;
          _log.i('[AdService] Interstitielle chargee');
        },
        onAdFailedToLoad: (error) {
          _isAdLoaded = false;
          _log.e('[AdService] Echec chargement interstitielle: '
              '${error.message}');
        },
      ),
    );
  }

  /// Affiche l interstitielle pre-chargee si disponible.
  ///
  /// Retourne `true` si la pub a ete affichee, `false` sinon.
  /// Apres affichage, l ad est consommee et doit etre rechargee.
  Future<bool> showInterstitial() async {
    if (testMode || !_isAdLoaded || _interstitialAd == null) {
      return false;
    }

    await _interstitialAd!.show();
    _interstitialAd = null;
    _isAdLoaded = false;
    _log.i('[AdService] Interstitielle affichee');
    return true;
  }

  /// Libere les ressources publicitaires.
  void dispose() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _isAdLoaded = false;
  }

  /// Ad unit ID de TEST officiel AdMob (interstitielle sandbox).
  /// Jamais d ID de production en dur dans le moteur.
  static const _testAdUnitId = 'ca-app-pub-3940256099942544/1033173712';
}

/// Provider Riverpod pour le [AdService].
final adServiceProvider = Provider<AdService>((ref) {
  final svc = AdService();
  ref.onDispose(svc.dispose);
  return svc;
});
