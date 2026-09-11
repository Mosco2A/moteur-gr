import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/monetization_service.dart';
import '../data/ads_consent_service.dart';
import '../data/rewarded_ad_service.dart';

/// Provider du service de consentement pub (UMP/CMP) + init AdMob (A6).
///
/// Instance unique app-wide. Surchargeable en test (fake sans réseau/SDK).
final adsConsentServiceProvider = Provider<AdsConsentService>(
  (ref) => AdsConsentService(),
);

/// Boot pub : résout le consentement UMP puis initialise le SDK si autorisé.
///
/// À `watch` au démarrage (après le bootstrap métier). Retourne `true` si les
/// pubs peuvent être demandées ([AdsConsentService.canRequestAds]). Best-effort
/// : un échec ne bloque pas l'app (aucune pub, jamais de crash).
final adsReadyProvider = FutureProvider<bool>((ref) async {
  return ref.watch(adsConsentServiceProvider).ensureConsentAndInit();
});

/// Provider du service de pub RÉCOMPENSÉE (rewarded).
///
/// Activé uniquement une fois le SDK initialisé ET le consentement obtenu
/// ([adsReadyProvider]). Sinon `enabled=false` (aucun chargement réel).
final rewardedAdServiceProvider = Provider<RewardedAdService>((ref) {
  final ready = ref.watch(adsReadyProvider).value ?? false;
  final svc = RewardedAdService(enabled: ready);
  ref.onDispose(svc.dispose);
  return svc;
});

/// Faut-il AFFICHER une bannière pour ce trek ? (source unique #99404 + UMP)
///
/// `true` seulement si : (1) le trek N'EST PAS sans-pub
/// ([MonetizationService.isNoAdsActive] — owned/abo/reward 24 h/vitrine) ET
/// (2) le consentement pub autorise les requêtes ([adsReadyProvider]). AUCUNE
/// règle sans-pub recalculée ici : on lit la source unique. En prépa gratuite
/// sans consentement pub, aucune bannière (conforme A6).
final shouldShowBannerProvider =
    FutureProvider.family<bool, String>((ref, trailId) async {
  final adsReady = await ref.watch(adsReadyProvider.future);
  if (!adsReady) return false;
  final monetization = await ref.watch(monetizationReadyProvider.future);
  final noAds = await monetization.isNoAdsActive(trailId);
  return !noAds;
});

/// Demande une pub rewarded et, si récompensée, crédite le sans-pub 24 h via la
/// SOURCE UNIQUE [MonetizationService.grantRewardNoAds].
///
/// Retourne `true` si le sans-pub 24 h a été crédité (récompense obtenue).
/// Encapsule la mécanique pub + le crédit métier pour l'UI (un seul appel).
final watchRewardedForNoAdsProvider =
    FutureProvider.autoDispose<bool>((ref) async {
  final rewarded = ref.watch(rewardedAdServiceProvider);
  final outcome = await rewarded.showRewarded();
  if (outcome == RewardedOutcome.earned) {
    final monetization = await ref.read(monetizationReadyProvider.future);
    await monetization.grantRewardNoAds();
    return true;
  }
  return false;
});
