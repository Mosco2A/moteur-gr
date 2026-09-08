import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/services/wallet_iap_service.dart';
import 'package:moteur_gr/core/services/wallet_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tests ST3 — `WalletIapService` + boucle de completion (StepWays LOT 1).
///
/// En l'etat, le kill-switch [kWalletIapRealModeEnabled] est `false` : le
/// service est STUB (aucun appel reel au store). On verifie le contrat de
/// stub demande par la spec :
///   - stub actif tant que le kill-switch est off ;
///   - productIds SANS prefixe `pack_` (deja pris par les packs de cartes) +
///     grille de credits ;
///   - `isAvailable` = false en stub ;
///   - `purchaseStream` VIDE en stub (aucun evenement) ;
///   - achats court-circuites (aucun paiement reel) en stub.
///
/// La boucle de completion reelle (verify -> applyDelivery -> completePurchase
/// + idempotence par purchaseID) ne se declenche qu'en mode reel (recus du
/// store) ; le cablage online (Cloud Function O1C) est un point d'extension
/// documente (stub tant que backend absent).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late WalletStore walletStore;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory());
    walletStore = WalletStore(
      db: db,
      prefs: await SharedPreferences.getInstance(),
    );
    addTearDown(walletStore.dispose);
    await walletStore.load();
  });

  tearDown(() async {
    await db.close();
  });

  WalletIapService makeService() {
    final service = WalletIapService(
      walletStore: walletStore,
      noAdsDao: db.noAdsDao,
      testMode: true,
    );
    addTearDown(service.stopListening);
    return service;
  }

  group('ST3 kill-switch / stub', () {
    test('le kill-switch reste OFF (aucun paiement reel a ce stade)', () {
      expect(kWalletIapRealModeEnabled, isFalse);
    });

    test('purchaseEnabled reflete le kill-switch (false = pas de bouton achat)',
        () {
      expect(makeService().purchaseEnabled, isFalse);
    });

    test('isAvailable = false en mode stub', () async {
      expect(await makeService().isAvailable(), isFalse);
    });

    test('purchaseStream est VIDE en mode stub', () async {
      final events = await makeService().purchaseStream.toList();
      expect(events, isEmpty);
    });

    test('queryProducts ne renvoie rien en mode stub', () async {
      expect(await makeService().queryProducts(), isEmpty);
    });

    test('les achats sont court-circuites en stub (aucun paiement reel)',
        () async {
      final service = makeService();
      expect(await service.buyCredits(kWalletCredits11), isFalse);
      expect(await service.buyNoAdsSubscription(), isFalse);
      // restore et startListening sont des no-op silencieux en stub.
      await service.restorePurchases();
      service.startListening();
      // Aucune livraison : wallet inchange, aucune source sans-pub.
      expect(walletStore.balanceSteps, 0);
      expect(await db.noAdsDao.getAll(), isEmpty);
    });
  });

  group('ST3 productIds (SANS prefixe pack_) + grille credits', () {
    test('les 4 productIds sont sans prefixe pack_ et bien nommes', () {
      expect(kWalletCredits11, 'stepways_credits_11');
      expect(kWalletCredits25, 'stepways_credits_25');
      expect(kWalletCredits50, 'stepways_credits_50');
      expect(kWalletSubNoAdsMonthly, 'stepways_sub_noads_monthly');
      for (final id in kWalletProductIds) {
        expect(id.startsWith('pack_'), isFalse,
            reason: 'prefixe pack_ deja pris par les packs de cartes');
      }
    });

    test('kWalletProductIds = 3 recharges + 1 abo', () {
      expect(kWalletProductIds, hasLength(4));
      expect(
        kWalletProductIds,
        containsAll(<String>{
          kWalletCredits11,
          kWalletCredits25,
          kWalletCredits50,
          kWalletSubNoAdsMonthly,
        }),
      );
    });

    test('la grille de credits mappe chaque recharge sur son nb d etapes', () {
      expect(kWalletCreditStepsByProduct[kWalletCredits11], 11);
      expect(kWalletCreditStepsByProduct[kWalletCredits25], 25);
      expect(kWalletCreditStepsByProduct[kWalletCredits50], 50);
      // L'abo ne credite pas d'etapes : absent de la grille.
      expect(
        kWalletCreditStepsByProduct.containsKey(kWalletSubNoAdsMonthly),
        isFalse,
      );
    });
  });
}
