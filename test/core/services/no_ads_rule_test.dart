import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/config/feature_flags.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/network/connectivity_monitor.dart';
import 'package:moteur_gr/core/services/monetization_service.dart';
import 'package:moteur_gr/core/services/wallet_iap_service.dart';
import 'package:moteur_gr/core/services/wallet_store.dart';
import 'package:moteur_gr/features/group/services/ad_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Faux moniteur de connectivite (online par defaut, non exerce ici).
class _FakeConnectivityMonitor extends ConnectivityMonitor {
  @override
  Future<ConnectivityStatus> checkStatus() async =>
      ConnectivityStatusValues.online;
}

/// Tests ST7 — regle sans-pub app-wide (#99404).
///
/// Verifie que [AdService.shouldShowAdForTrail] est branche sur la SOURCE
/// UNIQUE [MonetizationService.isNoAdsActive] (`owned || abo || reward 24 h`,
/// vitrine incluse) et ne recalcule AUCUNE regle. Matrice etat sans-pub x
/// contexte trail -> showAds attendu. On croise aussi l'index de suiveur
/// (< seuil = jamais de pub, >= seuil = pub sauf si sans-pub actif).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late WalletStore wallet;
  late AdService ads;
  late DateTime now;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FeatureFlags.clearOverrides();
    db = AppDatabase(NativeDatabase.memory());
    wallet = WalletStore(db: db, prefs: await SharedPreferences.getInstance());
    addTearDown(wallet.dispose);
    ads = AdService(testMode: true);
    now = DateTime(2026, 9, 8, 12);
  });

  tearDown(() async {
    FeatureFlags.clearOverrides();
    await db.close();
  });

  /// Fabrique un MonetizationService cable sur la DB en memoire.
  Future<MonetizationService> makeService({Set<String>? showcase}) async {
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
      connectivityMonitor: _FakeConnectivityMonitor(),
      nowFn: () => now,
      prefs: prefs,
      showcaseTrailIds: showcase ?? const {},
    );
    await svc.load();
    return svc;
  }

  /// Raccourci : decision app-wide pour un suiveur au-dela du seuil gratuit
  /// (index 2 = 3e suiveur, celui qui declenche la pub sans sans-pub actif).
  Future<bool> showAdsFor(MonetizationService svc, String trailId) {
    return ads.shouldShowAdForTrail(
      followerIndex: kFreeFollowerThreshold,
      trailId: trailId,
      monetization: svc,
    );
  }

  group('ST7 matrice sans-pub x contexte trail', () {
    test('trek libre (ni owned/abo/reward) -> pub affichee', () async {
      final svc = await makeService();
      expect(await svc.isNoAdsActive('gr20'), isFalse);
      expect(await showAdsFor(svc, 'gr20'), isTrue);
    });

    test('trek possede -> sans-pub (source unique owned)', () async {
      final svc = await makeService();
      await db.trekEntitlementsDao.upsert(
        TrekEntitlementsCompanion.insert(
          trailId: 'gr20',
          owned: const Value(true),
          updatedAt: now,
        ),
      );
      expect(await svc.isNoAdsActive('gr20'), isTrue);
      expect(await showAdsFor(svc, 'gr20'), isFalse);
    });

    test('abo actif -> sans-pub sur TOUT trail (app-wide)', () async {
      final svc = await makeService();
      await svc.onSubscriptionValidated();
      // Trek non possede mais couvert par l'abo : sans-pub partout.
      expect(await svc.isNoAdsActive('gr20'), isTrue);
      expect(await svc.isNoAdsActive('mare-a-mare'), isTrue);
      expect(await showAdsFor(svc, 'gr20'), isFalse);
      expect(await showAdsFor(svc, 'mare-a-mare'), isFalse);
    });

    test('reward 24 h actif -> sans-pub ; expire -> pub revient', () async {
      final svc = await makeService();
      await svc.grantRewardNoAds(); // expiresAt = now + 24 h

      // Dans la fenetre de 24 h : sans-pub.
      expect(await svc.isRewardNoAdsActive(), isTrue);
      expect(await showAdsFor(svc, 'gr20'), isFalse);

      // Apres expiration (horloge avancee de 25 h) : la pub revient.
      now = now.add(const Duration(hours: 25));
      expect(await svc.isRewardNoAdsActive(), isFalse);
      expect(await showAdsFor(svc, 'gr20'), isTrue);
    });

    test('sentier vitrine (parite GR20) -> sans-pub sans achat', () async {
      final svc = await makeService(showcase: {'vitrine'});
      expect(await svc.isNoAdsActive('vitrine'), isTrue);
      expect(await showAdsFor(svc, 'vitrine'), isFalse);
      // Un autre trail reste soumis a la pub.
      expect(await showAdsFor(svc, 'gr20'), isTrue);
    });
  });

  group('ST7 croisement index suiveur x sans-pub', () {
    test('sous le seuil gratuit -> jamais de pub, meme trek libre', () async {
      final svc = await makeService();
      for (final index in [0, kFreeFollowerThreshold - 1]) {
        expect(
          await ads.shouldShowAdForTrail(
            followerIndex: index,
            trailId: 'gr20',
            monetization: svc,
          ),
          isFalse,
          reason: 'index $index est gratuit (#81759)',
        );
      }
    });

    test('au-dela du seuil -> pub si libre, pas de pub si owned', () async {
      final svc = await makeService();
      // Libre : pub des le 3e suiveur.
      expect(await showAdsFor(svc, 'gr20'), isTrue);
      // Devient possede : la meme position ne montre plus de pub.
      await db.trekEntitlementsDao.upsert(
        TrekEntitlementsCompanion.insert(
          trailId: 'gr20',
          owned: const Value(true),
          updatedAt: now,
        ),
      );
      expect(await showAdsFor(svc, 'gr20'), isFalse);
    });
  });
}
