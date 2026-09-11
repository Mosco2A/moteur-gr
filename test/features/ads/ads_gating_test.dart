import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/config/feature_flags.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/network/connectivity_monitor.dart';
import 'package:moteur_gr/core/providers/database_provider.dart';
import 'package:moteur_gr/core/services/monetization_service.dart';
import 'package:moteur_gr/core/services/wallet_iap_service.dart';
import 'package:moteur_gr/core/services/wallet_store.dart';
import 'package:moteur_gr/features/ads/providers/ads_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Verifie le GATING de la banniere (source unique #99404 + consentement UMP).
/// La banniere ne s'affiche QUE si le trek n'est pas sans-pub ET la pub est
/// autorisee (adsReady). Aucune regle sans-pub recalculee cote pub.
class _FakeConnectivityMonitor extends ConnectivityMonitor {
  @override
  Future<ConnectivityStatus> checkStatus() async =>
      ConnectivityStatusValues.online;
}

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
    now = DateTime(2026, 9, 11, 12);
  });

  tearDown(() async {
    FeatureFlags.clearOverrides();
    await db.close();
  });

  Future<ProviderContainer> makeContainer({required bool adsReady}) async {
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
      showcaseTrailIds: const {},
    );
    await svc.load();
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        monetizationServiceProvider.overrideWithValue(svc),
        monetizationReadyProvider.overrideWith((ref) async => svc),
        adsReadyProvider.overrideWith((ref) async => adsReady),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('shouldShowBannerProvider — gating pub', () {
    test('trek libre + pub autorisee -> banniere affichee', () async {
      final c = await makeContainer(adsReady: true);
      final show = await c.read(shouldShowBannerProvider('gr20').future);
      expect(show, isTrue);
    });

    test('trek libre mais pub NON consentie -> pas de banniere', () async {
      final c = await makeContainer(adsReady: false);
      final show = await c.read(shouldShowBannerProvider('gr20').future);
      expect(show, isFalse);
    });

    test('trek possede (sans-pub source unique) -> pas de banniere', () async {
      final c = await makeContainer(adsReady: true);
      await db.trekEntitlementsDao.upsert(
        TrekEntitlementsCompanion.insert(
          trailId: 'gr20',
          owned: const Value(true),
          updatedAt: now,
        ),
      );
      final show = await c.read(shouldShowBannerProvider('gr20').future);
      expect(show, isFalse);
    });
  });
}
