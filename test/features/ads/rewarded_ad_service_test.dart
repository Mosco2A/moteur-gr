import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:moteur_gr/features/ads/data/rewarded_ad_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RewardedAdService — pub recompensee (A6, PAS d\'interstitiel)', () {
    test('desactive (SDK non pret) -> unavailable, aucun chargement reel',
        () async {
      var loadCalled = false;
      final svc = RewardedAdService(
        enabled: false,
        loadRewarded: ({
          required adUnitId,
          required request,
          required rewardedAdLoadCallback,
        }) async {
          loadCalled = true;
        },
      );

      expect(await svc.showRewarded(), RewardedOutcome.unavailable);
      await svc.preload();
      expect(loadCalled, isFalse, reason: 'aucun load si desactive');
    });

    test('active mais chargement echoue -> unavailable (jamais de crash)',
        () async {
      final svc = RewardedAdService(
        enabled: true,
        loadRewarded: ({
          required adUnitId,
          required request,
          required rewardedAdLoadCallback,
        }) async {
          // Le SDK appelle TOUJOURS un callback : ici, echec de chargement.
          rewardedAdLoadCallback.onAdFailedToLoad(
            LoadAdError(3, 'test', 'no fill', null),
          );
        },
      );

      expect(await svc.showRewarded(), RewardedOutcome.unavailable);
    });
  });
}
