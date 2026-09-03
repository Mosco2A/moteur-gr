import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/config/feature_flags.dart';
import 'package:moteur_gr/core/services/monetization_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tests E4.17 — monetisation freemium a la carte (#81774).
///
/// Test 1 : gratuit = pub + demo (features limitees).
/// Test 2 : premium = pas de pub + complet.
/// + persistance SharedPreferences, prix par etapes,
///   propagation FeatureFlags, independance par trek.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MonetizationService svc;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FeatureFlags.clearOverrides();
    svc = MonetizationService(
      prefs: await SharedPreferences.getInstance(),
    );
  });

  tearDown(() {
    svc.clearPurchases();
    FeatureFlags.clearOverrides();
  });

  group('E4.17 mode gratuit', () {
    test('gratuit = pub + demo, features limitees', () {
      final features = svc.getTrialFeatures();

      expect(features.hasAds, isTrue, reason: 'gratuit = avec pub (#81774)');
      expect(features.isDemo, isTrue, reason: 'gratuit = mode demo');
      expect(features.hasPreparation, isTrue,
          reason: 'la preparation reste accessible en gratuit');
      expect(features.hasGpsTracking, isFalse);
      expect(features.hasJournal, isFalse);
      expect(features.hasDiploma, isFalse);
      expect(features.hasGoodies, isFalse);
      expect(features.freeFollowerSlots, 0);

      // Trek non achete -> features gratuit + demo
      expect(svc.isTrailPurchased('volcans'), isFalse);
      expect(svc.isDemoMode('volcans'), isTrue);
      expect(svc.getFeaturesForTrail('volcans').isDemo, isTrue);
    });
  });

  group('E4.17 mode premium', () {
    test('premium = pas de pub + complet apres achat', () async {
      final purchased = await svc.purchaseTrail('volcans');
      expect(purchased, isTrue);

      final features = svc.getFeaturesForTrail('volcans');
      expect(features.hasAds, isFalse, reason: 'premium = sans pub (#81774)');
      expect(features.isDemo, isFalse);
      expect(features.hasGpsTracking, isTrue);
      expect(features.hasJournal, isTrue);
      expect(features.hasDiploma, isTrue);
      expect(features.hasGoodies, isTrue);
      expect(features.freeFollowerSlots, 2,
          reason: '2 suiveurs gratuits inclus (#81774)');
      expect(svc.isDemoMode('volcans'), isFalse);
    });

    test('achat PAR TREK : un autre trek reste en demo (#81805)', () async {
      await svc.purchaseTrail('volcans');

      expect(svc.isTrailPurchased('volcans'), isTrue);
      expect(svc.isTrailPurchased('sentier-bleu'), isFalse);
      expect(svc.isDemoMode('sentier-bleu'), isTrue);
    });

    test('achat propage le flag premium dans FeatureFlags', () async {
      expect(FeatureFlags.isPremiumEnabled('volcans'), isFalse);

      await svc.purchaseTrail('volcans');

      expect(FeatureFlags.isPremiumEnabled('volcans'), isTrue);
      expect(FeatureFlags.isPremiumEnabled('sentier-bleu'), isFalse);
    });

    test('achat persiste puis recharge via SharedPreferences', () async {
      await svc.purchaseTrail('volcans');

      // Nouveau service sur les memes prefs (simulateur redemarrage)
      final prefs = await SharedPreferences.getInstance();
      final svc2 = MonetizationService(prefs: prefs);
      expect(svc2.isTrailPurchased('volcans'), isFalse,
          reason: 'pas encore charge');

      await svc2.loadPurchases();
      expect(svc2.isLoaded, isTrue);
      expect(svc2.isTrailPurchased('volcans'), isTrue,
          reason: 'achat restaure depuis SharedPreferences');
    });

    test('prix premium = nombre etapes x 1 EUR (#81774)', () {
      expect(svc.priceForTrail(totalStages: 15), 15.0);
      expect(svc.priceForTrail(totalStages: 7), 7.0);
      expect(kPricePerStageEur, 1.0);
    });
  });

  // PARITE GR20, LOT 2 (2.A, #99433) — vitrine debloquee cote monetisation.
  group('LOT 2 vitrine debloquee', () {
    test('vitrine = features premium sans achat, autre sentier reste en demo',
        () async {
      SharedPreferences.setMockInitialValues({});
      final svcShowcase = MonetizationService(
        prefs: await SharedPreferences.getInstance(),
        showcaseTrailIds: {'vitrine-demo'},
      );

      // Vitrine : non achetee mais PAS en demo -> features premium (jouable).
      expect(svcShowcase.isShowcaseTrail('vitrine-demo'), isTrue);
      expect(svcShowcase.isTrailPurchased('vitrine-demo'), isFalse);
      expect(svcShowcase.isDemoMode('vitrine-demo'), isFalse);
      final feats = svcShowcase.getFeaturesForTrail('vitrine-demo');
      expect(feats.isDemo, isFalse);
      expect(feats.hasGpsTracking, isTrue);
      expect(feats.hasJournal, isTrue);

      // GARDE-FOU : un autre sentier non achete reste en demo (modele intact).
      expect(svcShowcase.isDemoMode('sentier-payant'), isTrue);
      expect(svcShowcase.getFeaturesForTrail('sentier-payant').isDemo, isTrue);
    });
  });
}
