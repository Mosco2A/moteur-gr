import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/group/services/ad_service.dart';

/// Tests du AdService (E4.13).
///
/// Verifie la logique shouldShowAd: true pour index 2+,
/// false pour 0-1 et pour tout follower paye (#81759).
void main() {
  late AdService svc;

  setUp(() {
    svc = AdService(testMode: true);
  });

  group('shouldShowAd', () {
    test('retourne false pour index 0 et 1 (suiveurs gratuits)', () {
      // Index 0 — premier suiveur gratuit
      expect(
        svc.shouldShowAd(followerIndex: 0, isPaid: false),
        isFalse,
      );

      // Index 1 — deuxieme suiveur gratuit
      expect(
        svc.shouldShowAd(followerIndex: 1, isPaid: false),
        isFalse,
      );
    });

    test('retourne true pour index 2+ non paye (interstitielle)', () {
      // Index 2 — troisieme suiveur, pub
      expect(
        svc.shouldShowAd(followerIndex: 2, isPaid: false),
        isTrue,
      );

      // Index 5 — sixieme suiveur, pub aussi
      expect(
        svc.shouldShowAd(followerIndex: 5, isPaid: false),
        isTrue,
      );
    });

    test('retourne false pour tout suiveur paye quel que soit l index', () {
      // Index 0 paye — pas de pub
      expect(
        svc.shouldShowAd(followerIndex: 0, isPaid: true),
        isFalse,
      );

      // Index 3 paye — pas de pub non plus
      expect(
        svc.shouldShowAd(followerIndex: 3, isPaid: true),
        isFalse,
      );

      // Index 10 paye — toujours pas
      expect(
        svc.shouldShowAd(followerIndex: 10, isPaid: true),
        isFalse,
      );
    });

    test('showInterstitial retourne false en testMode', () async {
      final result = await svc.showInterstitial();
      expect(result, isFalse);
    });
  });
}
