import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/config/feature_flags.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/network/connectivity_monitor.dart';
import 'package:moteur_gr/core/services/monetization_service.dart';
import 'package:moteur_gr/core/services/wallet_iap_service.dart';
import 'package:moteur_gr/core/services/wallet_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Faux moniteur de connectivite : online/offline pilotable en test.
///
/// `MonetizationService.buyTrail` exige le reseau pour le complement store
/// (spec §5) ; on override `checkStatus` pour simuler l'etat reseau sans
/// dependre du plugin natif.
class _FakeConnectivityMonitor extends ConnectivityMonitor {
  _FakeConnectivityMonitor({required this.online});

  bool online;

  @override
  Future<ConnectivityStatus> checkStatus() async => online
      ? ConnectivityStatusValues.online
      : ConnectivityStatusValues.offline;
}

/// Tests ST4 — refonte `MonetizationService` (StepWays LOT 1, le CŒUR).
///
/// Modele DEUX POCHES : compte-etapes (wallet) + droits par trek. On verifie :
///   - ownsTrail / accessFor (3 niveaux free/subscriber/owned) ;
///   - grille de prix (stepPrice / eurPrice / packs) ;
///   - buyTrail : wallet suffisant -> owned ; complement hors-ligne -> rollback ;
///     complement en ligne (IAP stub) -> rollback + complementFailed ;
///   - reward sans-pub 24 h via horloge injectee (Clock) ;
///   - abo (onSubscriptionValidated) + isSubscriberActive ;
///   - abandon / reprise (rachat du seul complement restant, acquis conserves) ;
///   - isNoAdsActive (matrice #99404) ;
///   - migration legacy (2 cles prefs) idempotente ;
///   - vitrine (parite GR20) preservee ;
///   - reset.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late WalletStore wallet;
  late DateTime now;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FeatureFlags.clearOverrides();
    db = AppDatabase(NativeDatabase.memory());
    wallet = WalletStore(db: db, prefs: await SharedPreferences.getInstance());
    addTearDown(wallet.dispose);
    now = DateTime(2026, 9, 8, 12);
  });

  tearDown(() async {
    FeatureFlags.clearOverrides();
    await db.close();
  });

  /// Fabrique un service cable sur la DB en memoire.
  ///
  /// [walletSteps] credite le compte-etapes au demarrage ; [online] pilote le
  /// faux moniteur ; [showcase] injecte les sentiers vitrine.
  Future<MonetizationService> makeService({
    int walletSteps = 0,
    bool online = true,
    Set<String>? showcase,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final iap = WalletIapService(
      walletStore: wallet,
      noAdsDao: db.noAdsDao,
      testMode: true,
    );
    addTearDown(iap.stopListening);
    final svc = MonetizationService(
      walletStore: wallet,
      entitlementsDao: db.trekEntitlementsDao,
      noAdsDao: db.noAdsDao,
      iapService: iap,
      connectivityMonitor: _FakeConnectivityMonitor(online: online),
      nowFn: () => now,
      prefs: prefs,
      showcaseTrailIds: showcase ?? const {},
    );
    await svc.load();
    if (walletSteps > 0) await wallet.credit(walletSteps);
    return svc;
  }

  group('ST4 access / ownership', () {
    test('trek non achete = free (demo + pub)', () async {
      final svc = await makeService();
      expect(await svc.ownsTrail('gr20'), isFalse);
      expect(await svc.accessFor('gr20'), TrailAccess.free);
      expect(await svc.isDemoMode('gr20'), isTrue);
      expect(TrailAccess.free.showAds, isTrue);
      expect(await svc.isNoAdsActive('gr20'), isFalse);
    });

    test('abo actif = subscriber (jouable, sans pub) sur trek non possede',
        () async {
      final svc = await makeService();
      await svc.onSubscriptionValidated();

      expect(await svc.isSubscriberActive(), isTrue);
      expect(await svc.accessFor('gr20'), TrailAccess.subscriber);
      expect(TrailAccess.subscriber.showAds, isFalse);
      expect(await svc.isDemoMode('gr20'), isFalse);
      expect(await svc.isNoAdsActive('gr20'), isTrue);
    });

    test('trek possede = owned (prioritaire sur l abo)', () async {
      final svc = await makeService(walletSteps: 10);
      final outcome = await svc.buyTrail('gr20', totalStages: 10);

      expect(outcome.isOwned, isTrue);
      expect(await svc.ownsTrail('gr20'), isTrue);
      expect(await svc.accessFor('gr20'), TrailAccess.owned);
      expect(TrailAccess.owned.showAds, isFalse);
      expect(await svc.isNoAdsActive('gr20'), isTrue);
      // Le cache synchrone FeatureFlags est aligne (gardes de routes).
      expect(FeatureFlags.isPremiumEnabled('gr20'), isTrue);
    });
  });

  group('ST4 grille de prix', () {
    test('stepPriceForTrail = nombre d etapes', () async {
      final svc = await makeService();
      expect(svc.stepPriceForTrail(totalStages: 15), 15);
      expect(svc.stepPriceForTrail(totalStages: 7), 7);
    });

    test('eurPriceForSteps = etapes x kStepTierEur (0,99)', () async {
      final svc = await makeService();
      expect(kStepTierEur, 0.99);
      expect(svc.eurPriceForSteps(10), closeTo(9.90, 1e-9));
      expect(svc.eurPriceForSteps(1), closeTo(0.99, 1e-9));
    });

    test('grille packs 11/25/50 + plus petit pack couvrant', () async {
      final svc = await makeService();
      expect(kStepPacks.map((p) => p.steps).toList(), [11, 25, 50]);
      expect(kStepPacks.map((p) => p.priceEur).toList(), [9.99, 19.99, 34.99]);
      // Complement : plus petit pack couvrant le manque (reco §3.1).
      expect(svc.smallestPackCovering(3).steps, 11);
      expect(svc.smallestPackCovering(11).steps, 11);
      expect(svc.smallestPackCovering(12).steps, 25);
      expect(svc.smallestPackCovering(40).steps, 50);
      // Au-dela du plus gros pack : retombe sur le plus gros.
      expect(svc.smallestPackCovering(999).steps, 50);
      expect(svc.packSteps(kStepPacks.first), 11);
      expect(svc.packPriceEur(kStepPacks.first), 9.99);
    });
  });

  group('ST4 buyTrail — wallet suffisant', () {
    test('wallet couvre tout : owned pose, wallet debite, complement nul',
        () async {
      final svc = await makeService(walletSteps: 12);

      final quote = await svc.quoteTrail('gr20', totalStages: 10);
      expect(quote.stepsNeeded, 10);
      expect(quote.stepsFromWallet, 10);
      expect(quote.complementSteps, 0);
      expect(quote.complementPack, isNull);

      final outcome = await svc.buyTrail('gr20', totalStages: 10);
      expect(outcome.status, PurchaseStatusResult.owned);
      expect(outcome.stepsFromWallet, 10);
      expect(svc.walletSteps, 2, reason: '12 - 10 debitees');
      expect(await svc.ownsTrail('gr20'), isTrue);
    });

    test('deja possede : idempotent, rien debite', () async {
      final svc = await makeService(walletSteps: 20);
      await svc.buyTrail('gr20', totalStages: 10);
      final before = svc.walletSteps;

      final again = await svc.buyTrail('gr20', totalStages: 10);
      expect(again.status, PurchaseStatusResult.alreadyOwned);
      expect(svc.walletSteps, before, reason: 'aucun re-debit');
    });
  });

  group('ST4 buyTrail — complement store', () {
    test('hors-ligne : complement requis -> ROLLBACK wallet, pas de owned',
        () async {
      final svc = await makeService(walletSteps: 4, online: false);

      final quote = await svc.quoteTrail('gr20', totalStages: 10);
      expect(quote.stepsFromWallet, 4);
      expect(quote.complementSteps, 6);
      expect(quote.complementPack!.steps, 11);

      final outcome = await svc.buyTrail('gr20', totalStages: 10);
      expect(outcome.status, PurchaseStatusResult.offlineComplementRequired);
      expect(outcome.complementSteps, 6);
      // Jamais de wallet debite sans contrepartie : le debit est annule.
      expect(svc.walletSteps, 4, reason: 'rollback du debit wallet');
      expect(await svc.ownsTrail('gr20'), isFalse);
    });

    test('en ligne mais IAP stub : rollback + complementFailed, pas de owned',
        () async {
      final svc = await makeService(walletSteps: 4, online: true);

      final outcome = await svc.buyTrail('gr20', totalStages: 10);
      // Le complement store est asynchrone (boucle completion) : pas de
      // confirmation synchrone en stub -> rollback + echec, owned NON pose.
      expect(outcome.status, PurchaseStatusResult.complementFailed);
      expect(outcome.complementSteps, 6);
      expect(svc.walletSteps, 4, reason: 'rollback du debit wallet');
      expect(await svc.ownsTrail('gr20'), isFalse);
    });
  });

  group('ST4 reward sans-pub 24 h (Clock injecte)', () {
    test('grantRewardNoAds actif < 24 h, expire apres', () async {
      final svc = await makeService();
      expect(await svc.isRewardNoAdsActive(), isFalse);

      await svc.grantRewardNoAds();
      expect(await svc.isRewardNoAdsActive(), isTrue);
      expect(await svc.isNoAdsActive('gr20'), isTrue,
          reason: 'reward couvre le sans-pub meme sans achat');

      // Avance l'horloge de 25 h : le reward a expire.
      now = now.add(const Duration(hours: 25));
      expect(await svc.isRewardNoAdsActive(), isFalse);
      expect(await svc.isNoAdsActive('gr20'), isFalse);
    });

    test('reward encore actif juste avant 24 h', () async {
      final svc = await makeService();
      await svc.grantRewardNoAds();

      now = now.add(const Duration(hours: 23, minutes: 59));
      expect(await svc.isRewardNoAdsActive(), isTrue);
    });
  });

  group('ST4 abonnement', () {
    test('onSubscriptionValidated -> abo actif + sans-pub', () async {
      final svc = await makeService();
      expect(await svc.isSubscriberActive(), isFalse);

      await svc.onSubscriptionValidated();
      expect(await svc.isSubscriberActive(), isTrue);
      expect(await svc.isNoAdsActive('sentier-x'), isTrue);
    });

    test('subscribe en stub ne pose pas d abo (aucun paiement reel)', () async {
      final svc = await makeService();
      final initiated = await svc.subscribe();
      expect(initiated, isFalse, reason: 'kill-switch IAP off');
      expect(await svc.isSubscriberActive(), isFalse);
    });
  });

  group('ST4 abandon / reprise', () {
    test('reprise ne rachete que le complement restant (acquis conserves)',
        () async {
      // Achat initial couvert par le wallet : 10/10 acquis, owned.
      final svc = await makeService(walletSteps: 30);
      await svc.buyTrail('gr20', totalStages: 10);
      expect(await svc.acquiredStagesFor('gr20'), 10);

      // Abandon : owned retombe a false, acquis conserves comme base de rachat.
      await svc.onTrailAbandoned('gr20');
      expect(await svc.ownsTrail('gr20'), isFalse);
      expect(await svc.acquiredStagesFor('gr20'), 10);
      expect(FeatureFlags.isPremiumEnabled('gr20'), isFalse);

      // Devis de reprise : plus rien a payer (tout deja acquis).
      final resumeQuote = await svc.quoteResume('gr20', totalStages: 10);
      expect(resumeQuote.stepsNeeded, 0, reason: 'les 10 etapes sont acquises');
      expect(resumeQuote.complementSteps, 0);

      final walletBefore = svc.walletSteps;
      final outcome = await svc.resumeTrail('gr20', totalStages: 10);
      expect(outcome.status, PurchaseStatusResult.owned);
      expect(outcome.stepsFromWallet, 0, reason: 'rien re-debite a la reprise');
      expect(svc.walletSteps, walletBefore);
      expect(await svc.ownsTrail('gr20'), isTrue);
    });

    test('reprise partielle : ne facture que les etapes non acquises', () async {
      // Trek de 10 etapes dont 4 deja acquises (posees via abandon d'un achat
      // partiel simule : on part d'un etat acquis=4 sans owned).
      final svc = await makeService(walletSteps: 30);
      final now2 = now;
      await db.trekEntitlementsDao.upsert(
        TrekEntitlementsCompanion.insert(
          trailId: 'gr20',
          owned: const Value(false),
          acquiredStages: const Value(4),
          totalStages: const Value(10),
          updatedAt: now2,
        ),
      );

      final quote = await svc.quoteResume('gr20', totalStages: 10);
      expect(quote.acquiredStages, 4);
      expect(quote.stepsNeeded, 6, reason: '10 - 4 acquises');
    });
  });

  group('ST4 migration legacy (idempotente)', () {
    test('migre les 2 cles prefs legacy vers owned=true', () async {
      SharedPreferences.setMockInitialValues({
        kPurchasedTrailsPrefsKey: ['gr20'],
        kDemoModePurchasedTrailsPrefsKey: ['gr20', 'volcans'],
      });
      final svc = await makeService(); // load() -> migrateLegacyPurchases()

      expect(await svc.ownsTrail('gr20'), isTrue);
      expect(await svc.ownsTrail('volcans'), isTrue);
      expect(FeatureFlags.isPremiumEnabled('gr20'), isTrue);

      // Idempotent : relancer ne casse rien, reste owned.
      await svc.migrateLegacyPurchases();
      expect(await svc.ownsTrail('gr20'), isTrue);
      final all = await db.trekEntitlementsDao.getAll();
      expect(all.where((e) => e.trailId == 'gr20'), hasLength(1));
    });
  });

  group('ST4 vitrine (parite GR20) preservee', () {
    test('vitrine = owned/jouable sans achat, autre sentier reste free',
        () async {
      final svc = await makeService(showcase: {'vitrine-demo'});

      expect(svc.isShowcaseTrail('vitrine-demo'), isTrue);
      expect(await svc.ownsTrail('vitrine-demo'), isFalse,
          reason: 'jouable sans etre "achetee"');
      expect(await svc.accessFor('vitrine-demo'), TrailAccess.owned);
      expect(await svc.isDemoMode('vitrine-demo'), isFalse);
      expect(await svc.isNoAdsActive('vitrine-demo'), isTrue);

      // GARDE-FOU : un autre sentier non achete reste en demo (modele intact).
      expect(await svc.isDemoMode('sentier-payant'), isTrue);
      expect(await svc.accessFor('sentier-payant'), TrailAccess.free);
    });
  });

  group('ST4 reset', () {
    test('reset efface droits + sans-pub + cache FeatureFlags', () async {
      final svc = await makeService(walletSteps: 30);
      await svc.buyTrail('gr20', totalStages: 10);
      await svc.onSubscriptionValidated();
      await svc.grantRewardNoAds();

      await svc.reset();

      expect(await svc.ownsTrail('gr20'), isFalse);
      expect(await svc.isSubscriberActive(), isFalse);
      expect(await svc.isRewardNoAdsActive(), isFalse);
      expect(FeatureFlags.isPremiumEnabled('gr20'), isFalse);
    });
  });

  group('ST4 features (retro-compat)', () {
    test('gratuit = pub + demo ; premium = complet sans pub', () async {
      final svc = await makeService();
      final trial = svc.getTrialFeatures();
      expect(trial.hasAds, isTrue);
      expect(trial.isDemo, isTrue);
      expect(trial.hasGpsTracking, isFalse);

      final premium = svc.getPremiumFeatures();
      expect(premium.hasAds, isFalse);
      expect(premium.hasGpsTracking, isTrue);
      expect(premium.freeFollowerSlots, 2);
    });

    test('featuresForTrail suit accessFor (owned -> premium)', () async {
      final svc = await makeService(walletSteps: 10);
      expect((await svc.featuresForTrail('gr20')).isDemo, isTrue);
      await svc.buyTrail('gr20', totalStages: 10);
      expect((await svc.featuresForTrail('gr20')).isDemo, isFalse);
      expect((await svc.featuresForTrail('gr20')).hasGpsTracking, isTrue);
    });
  });
}
