import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../../core/config/ad_config.dart';
import '../../../core/error/error_handler.dart';

/// Résultat d'une tentative de pub RÉCOMPENSÉE (rewarded).
enum RewardedOutcome {
  /// L'utilisateur a regardé la pub jusqu'à la récompense (sans-pub à créditer).
  earned,

  /// Pub fermée sans récompense (abandon avant la fin).
  dismissedWithoutReward,

  /// Aucune pub disponible / échec de chargement (jamais de crash).
  unavailable,
}

/// Service de pub RÉCOMPENSÉE (rewarded) — StepWays L6/A6.
///
/// Charge et affiche UNE pub rewarded (format AUTORISÉ, avec les bannières) ;
/// PAS d'interstitiel (#99305/#99370). Sur récompense effective, l'appelant
/// crédite le sans-pub 24 h (`MonetizationService.grantRewardNoAds`) — ce
/// service NE connaît PAS la monétisation, il ne fait que la mécanique pub.
///
/// [enabled] = false (mode test / SDK non initialisé) court-circuite tout
/// chargement réel : [showRewarded] renvoie alors [RewardedOutcome.unavailable]
/// sans effet de bord. Injection de [loadRewarded] pour les tests.
class RewardedAdService {
  RewardedAdService({
    bool enabled = true,
    String? adUnitId,
    Future<void> Function({
      required String adUnitId,
      required AdRequest request,
      required RewardedAdLoadCallback rewardedAdLoadCallback,
    })?
    loadRewarded,
  }) : _enabled = enabled,
       _adUnitId = adUnitId ?? AdConfig.rewardedUnitId(),
       _loadRewarded = loadRewarded ?? RewardedAd.load;

  final bool _enabled;
  final String _adUnitId;
  final Future<void> Function({
    required String adUnitId,
    required AdRequest request,
    required RewardedAdLoadCallback rewardedAdLoadCallback,
  })
  _loadRewarded;

  RewardedAd? _ad;

  /// Délai de garde du chargement (le SDK appelle normalement un callback ;
  /// ce timeout évite tout blocage si aucun ne vient — jamais d'attente infinie).
  static const Duration _loadTimeout = Duration(seconds: 15);

  /// Précharge une pub rewarded (best-effort). No-op si [enabled] est faux.
  Future<void> preload() async {
    if (!_enabled || _ad != null) return;
    final completer = Completer<void>();
    try {
      await _loadRewarded(
        adUnitId: _adUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            _ad = ad;
            if (!completer.isCompleted) completer.complete();
          },
          onAdFailedToLoad: (error) {
            ErrorHandler.log(
              StateError('rewarded load failed: ${error.message}'),
              context: 'RewardedAdService.preload',
            );
            if (!completer.isCompleted) completer.complete();
          },
        ),
      );
    } on Object catch (e, st) {
      ErrorHandler.log(e, stackTrace: st, context: 'RewardedAdService.preload');
      if (!completer.isCompleted) completer.complete();
    }
    // Garde anti-blocage : si aucun callback ne vient, on abandonne proprement.
    await completer.future.timeout(_loadTimeout, onTimeout: () {});
  }

  /// Affiche la pub rewarded et RÉSOUT l'issue (récompense / abandon / indispo).
  ///
  /// Charge à la volée si aucune pub préchargée. Consomme l'instance après
  /// affichage (une rewarded ne se rejoue pas). Jamais d'exception propagée.
  Future<RewardedOutcome> showRewarded() async {
    if (!_enabled) return RewardedOutcome.unavailable;
    if (_ad == null) {
      await preload();
    }
    final ad = _ad;
    if (ad == null) return RewardedOutcome.unavailable;
    _ad = null; // consommée

    final completer = Completer<RewardedOutcome>();
    var earned = false;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        if (!completer.isCompleted) {
          completer.complete(
            earned
                ? RewardedOutcome.earned
                : RewardedOutcome.dismissedWithoutReward,
          );
        }
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ErrorHandler.log(
          StateError('rewarded show failed: ${error.message}'),
          context: 'RewardedAdService.showRewarded',
        );
        ad.dispose();
        if (!completer.isCompleted) {
          completer.complete(RewardedOutcome.unavailable);
        }
      },
    );

    try {
      await ad.show(
        onUserEarnedReward: (ad, reward) {
          earned = true;
        },
      );
    } on Object catch (e, st) {
      ErrorHandler.log(e, stackTrace: st, context: 'RewardedAdService.show');
      if (!completer.isCompleted) {
        completer.complete(RewardedOutcome.unavailable);
      }
    }
    return completer.future;
  }

  /// Libère la pub préchargée éventuelle.
  void dispose() {
    _ad?.dispose();
    _ad = null;
  }
}
