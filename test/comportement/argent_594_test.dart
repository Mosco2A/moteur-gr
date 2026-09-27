// V1 ARGENT (tache 594) — CE QUE L APPLICATION DOIT REFUSER, ET CE QU ELLE
// DOIT DIRE QUAND ELLE REFUSE.
//
// La reference est `data/apport_stepways/MODELE_ECO.md` du 08/09, qui se
// declare SOURCE DE VERITE UNIQUE. Quatre de ses decisions etaient CONTREDITES
// par le code, toutes dans le meme sens : l application donnait plus que ce qui
// a ete decide.
//
//  A1 — realiser un trek ne coutait RIEN a personne. Le modele reserve la
//       realisation au trek ACHETE ; le demarrage ne regardait que l absence de
//       session active.
//  A2a — l abonne obtenait les outils complets ET la realisation de tous les
//       treks, alors que l arbitrage du 08/09 dit l inverse et PRIME sur
//       #99405 : l abo light donne le sans-pub partout et une cagnotte, rien de
//       plus.
//  A2b — le sans-pub de l abonne etait de fait A VIE, rien ne l expirait
//       jamais. La regle d or #99404 l interdit : jamais a vie, toujours lie a
//       un etat actif.
//  A2c — la demo bridee avait le sens INVERSE : l entrainement etait verrouille
//       au lieu d etre jouable bride, et le sac n avait aucun bridage.
//
// CHACUN DE CES TESTS A ETE ECRIT ROUGE, AVANT SA CORRECTION (regle du lot).
library;

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:moteur_gr/core/config/feature_flags.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/network/connectivity_monitor.dart';
import 'package:moteur_gr/core/providers/database_provider.dart';
import 'package:moteur_gr/core/services/monetization_service.dart';
import 'package:moteur_gr/core/services/wallet_iap_service.dart';
import 'package:moteur_gr/core/services/wallet_store.dart';
import 'package:moteur_gr/features/trek/providers/tracking_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Faux moniteur de connectivite (le complement store exige le reseau).
class _FakeConnectivityMonitor extends ConnectivityMonitor {
  _FakeConnectivityMonitor({this.online = true});

  bool online;

  @override
  Future<ConnectivityStatus> checkStatus() async => online
      ? ConnectivityStatusValues.online
      : ConnectivityStatusValues.offline;
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
    now = DateTime(2026, 9, 26, 12);
  });

  tearDown(() async {
    FeatureFlags.clearOverrides();
    await db.close();
  });

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

  // =========================================================================
  // A1 — LE VERROU DE LA REALISATION
  // =========================================================================

  group('A1 — realiser un trek n est plus gratuit', () {
    test('un trek non achete ne peut PAS etre realise', () async {
      final svc = await makeService();
      expect(await svc.canRealizeTrail('gr20'), isFalse,
          reason: 'le modele reserve la REALISATION au trek achete ; sans ce '
              'refus, n importe qui enregistre et termine le parcours entier');
    });

    test('un trek achete peut etre realise', () async {
      final svc = await makeService(walletSteps: 16);
      final outcome = await svc.buyTrail('gr20', totalStages: 16);
      expect(outcome.isOwned, isTrue);
      expect(await svc.canRealizeTrail('gr20'), isTrue);
    });

    test('un sentier VITRINE reste realisable sans achat (parite GR20)',
        () async {
      final svc = await makeService(showcase: {'gr20'});
      expect(await svc.canRealizeTrail('gr20'), isTrue);
    });

    test('un ABONNE ne peut pas realiser : l abo ne debloque PAS la realisation',
        () async {
      final svc = await makeService();
      await svc.onSubscriptionValidated();
      expect(await svc.isSubscriberActive(), isTrue);
      expect(await svc.canRealizeTrail('gr20'), isFalse,
          reason: 'arbitrage du 08/09, qui prime sur #99405 : l abo light ne '
              'debloque NI les outils complets NI la realisation');
    });

    test('le demarrage REFUSE un trek non achete, et ne cree aucune session',
        () async {
      final svc = await makeService();
      final container = ProviderContainer(overrides: [
        databaseProvider.overrideWithValue(db),
        monetizationServiceProvider.overrideWithValue(svc),
      ]);
      addTearDown(container.dispose);

      final notifier = container.read(trekSessionManagerProvider.notifier);
      final outcome = await notifier.ensureSingleActiveThenStart(
        'gr20',
        resolve: (_) async => ActiveTrekConflictChoice.cancel,
      );

      expect(outcome, StartOutcome.purchaseRequired,
          reason: 'le demarrage doit dire POURQUOI il refuse, pas echouer en '
              'silence ni demarrer quand meme');
      expect(container.read(trekSessionManagerProvider).session, isNull,
          reason: 'un refus ne laisse aucune session derriere lui');
      expect(await db.trekSessionsDao.findActiveSessions(), isEmpty);
    });
  });

  // =========================================================================
  // A2a — L ABONNE N OBTIENT PAS LES OUTILS COMPLETS
  // =========================================================================

  group('A2a — l abo light ne debloque ni les outils ni la realisation', () {
    test('TrailAccess.subscriber n est PAS jouable', () {
      expect(TrailAccess.subscriber.isPlayable, isFalse);
      expect(TrailAccess.owned.isPlayable, isTrue);
      expect(TrailAccess.free.isPlayable, isFalse);
    });

    test('l abonne reste en mode demo sur un trek non achete', () async {
      final svc = await makeService();
      await svc.onSubscriptionValidated();
      expect(await svc.accessFor('gr20'), TrailAccess.subscriber);
      expect(await svc.isDemoMode('gr20'), isTrue,
          reason: 'pour les outils complets d un trek, il faut l ACHETER '
              '(comme le gratuit)');
    });

    test('l abonne n a PAS les outils complets mais il n a PAS de pub non plus',
        () async {
      final svc = await makeService();
      await svc.onSubscriptionValidated();
      final f = await svc.featuresForTrail('gr20');
      expect(f.hasGpsTracking, isFalse);
      expect(f.hasJournal, isFalse);
      expect(f.hasDiploma, isFalse);
      expect(f.hasPreparation, isTrue, reason: 'la demo bridee reste jouable');
      expect(f.hasAds, isFalse,
          reason: 'l abo light donne le SANS-PUB PARTOUT — c est tout ce qu il '
              'donne, mais il le donne vraiment');
      expect(await svc.isNoAdsActive('gr20'), isTrue);
    });
  });

  // =========================================================================
  // A2b — LE SANS-PUB DE L ABONNE N EST PAS A VIE
  // =========================================================================

  group('A2b — regle d or #99404 : jamais a vie, toujours un etat actif', () {
    test('le sans-pub de l abonne EXPIRE si rien ne le renouvelle', () async {
      final svc = await makeService();
      await svc.onSubscriptionValidated();
      expect(await svc.isSubscriberActive(), isTrue);

      now = now.add(kSubscriptionNoAdsWindow + const Duration(minutes: 1));
      expect(await svc.isSubscriberActive(), isFalse,
          reason: 'rien n expirait jamais l abo : une fois pose, le sans-pub '
              'etait acquis A VIE, ce que la regle d or interdit');
      expect(await svc.isNoAdsActive('gr20'), isFalse);
    });

    test('un renouvellement repousse l echeance, il n en empile pas deux',
        () async {
      final svc = await makeService();
      await svc.onSubscriptionValidated();
      now = now.add(const Duration(days: 20));
      await svc.onSubscriptionValidated();

      final rows = await db.noAdsDao.getAll();
      final abos = rows.where((r) => r.source == 'subscription').toList();
      expect(abos.length, 1,
          reason: 'un abonnement est un ETAT, pas une collection de lignes');

      now = now.add(kSubscriptionNoAdsWindow - const Duration(days: 1));
      expect(await svc.isSubscriberActive(), isTrue);
    });

    test('une annulation revoque le sans-pub immediatement', () async {
      final svc = await makeService();
      await svc.onSubscriptionValidated();
      expect(await svc.isSubscriberActive(), isTrue);

      await svc.onSubscriptionCanceled();
      expect(await svc.isSubscriberActive(), isFalse,
          reason: 'PurchaseStatus.canceled ne faisait que journaliser');
    });

    test('une ligne d abo SANS echeance (legacy) n est plus acceptee', () async {
      final svc = await makeService();
      await db.noAdsDao.insertState(
        NoAdsStateCompanion.insert(
          source: 'subscription',
          startedAt: now,
          updatedAt: now,
          expiresAt: const Value(null),
        ),
      );
      expect(await svc.isSubscriberActive(), isFalse,
          reason: 'une ligne sans echeance, c est exactement le « a vie » que '
              'la regle d or interdit');
    });

    test('la purge des expires emporte aussi un abo echu', () async {
      final svc = await makeService();
      await svc.onSubscriptionValidated();
      final purge = await db.noAdsDao.deleteExpired(
        now.add(kSubscriptionNoAdsWindow + const Duration(days: 1)),
      );
      expect(purge, 1);
    });
  });

  // =========================================================================
  // A5 — LA CAGNOTTE : LE MECANISME EXISTE, LE MONTANT ATTEND CHRIS
  // =========================================================================

  group('A5 — la cagnotte de l abonne', () {
    test('sans abonnement, aucune cagnotte', () async {
      final svc = await makeService();
      final r = await svc.grantSubscriberAllowance();
      expect(r, SubscriberAllowanceOutcome.notSubscriber);
      expect(svc.walletSteps, 0);
    });

    test('abonne + montant NON DECIDE -> rien n est verse, et on le DIT',
        () async {
      final svc = await makeService();
      await svc.onSubscriptionValidated();
      final r = await svc.grantSubscriberAllowance();
      if (kSubscriberStepsAllowance == null) {
        expect(r, SubscriberAllowanceOutcome.pendingDecision,
            reason: 'le montant n est chiffre NI dans le code NI dans le '
                'modele : on ne l invente pas, on le signale');
        expect(svc.walletSteps, 0);
      } else {
        expect(r, SubscriberAllowanceOutcome.granted);
        expect(svc.walletSteps, kSubscriberStepsAllowance);
      }
    });

    test('la cagnotte n est versee qu une fois par periode', () async {
      final svc = await makeService();
      await svc.onSubscriptionValidated();
      await svc.grantSubscriberAllowance();
      final second = await svc.grantSubscriberAllowance();
      expect(
        second,
        anyOf(
          SubscriberAllowanceOutcome.pendingDecision,
          SubscriberAllowanceOutcome.alreadyGranted,
        ),
        reason: 'une cagnotte versee deux fois dans la meme periode est un '
            'credit gratuit',
      );
    });
  });

  // =========================================================================
  // A3 — LA VALIDATION DES RECUS N ACCEPTE PLUS TOUT
  // =========================================================================

  group('A3 — un recu non verifiable est REFUSE', () {
    PurchaseDetails recu({
      required String productId,
      String jeton = 'jeton-store',
      PurchaseStatus status = PurchaseStatus.purchased,
    }) {
      return PurchaseDetails(
        purchaseID: 'p-1',
        productID: productId,
        verificationData: PurchaseVerificationData(
          localVerificationData: jeton,
          serverVerificationData: jeton,
          source: 'test',
        ),
        transactionDate: '0',
        status: status,
      );
    }

    test('un recu sans jeton de verification est refuse', () async {
      const v = LocalSanityReceiptValidator(serverValidationAvailable: true);
      expect(
        await v.isValid(recu(productId: kWalletCredits11, jeton: '')),
        isFalse,
      );
    });

    test('un produit inconnu est refuse', () async {
      const v = LocalSanityReceiptValidator(serverValidationAvailable: true);
      expect(await v.isValid(recu(productId: 'produit_pirate')), isFalse);
    });

    test('un recu en erreur est refuse', () async {
      const v = LocalSanityReceiptValidator(serverValidationAvailable: true);
      expect(
        await v.isValid(
          recu(productId: kWalletCredits11, status: PurchaseStatus.error),
        ),
        isFalse,
      );
    });

    test(
        'sans validateur serveur, meme un recu bien forme est refuse — on ne '
        'credite pas sur une parole', () async {
      const v = LocalSanityReceiptValidator();
      expect(await v.isValid(recu(productId: kWalletCredits11)), isFalse);
    });

    test('un recu bien forme passe quand le serveur peut le valider', () async {
      const v = LocalSanityReceiptValidator(serverValidationAvailable: true);
      expect(await v.isValid(recu(productId: kWalletCredits11)), isTrue);
    });

    test('un achat non verifie ne credite RIEN', () async {
      final iap = WalletIapService(
        walletStore: wallet,
        noAdsDao: db.noAdsDao,
        testMode: true,
        receiptValidator: const LocalSanityReceiptValidator(),
      );
      addTearDown(iap.stopListening);
      await iap.debugHandlePurchases([recu(productId: kWalletCredits11)]);
      expect(wallet.balanceSteps, 0,
          reason: '`_verify` retournait `true` pour tout : n importe quel recu '
              'creditait le compte-etapes');
    });

    test('un achat verifie credite le compte-etapes une seule fois', () async {
      final iap = WalletIapService(
        walletStore: wallet,
        noAdsDao: db.noAdsDao,
        testMode: true,
        receiptValidator:
            const LocalSanityReceiptValidator(serverValidationAvailable: true),
      );
      addTearDown(iap.stopListening);
      await iap.debugHandlePurchases([recu(productId: kWalletCredits11)]);
      await iap.debugHandlePurchases([recu(productId: kWalletCredits11)]);
      expect(wallet.balanceSteps, 11);
    });

    test('un abo livre par le store porte une echeance, jamais nulle', () async {
      final iap = WalletIapService(
        walletStore: wallet,
        noAdsDao: db.noAdsDao,
        testMode: true,
        receiptValidator:
            const LocalSanityReceiptValidator(serverValidationAvailable: true),
      );
      addTearDown(iap.stopListening);
      await iap.debugHandlePurchases([
        recu(productId: kWalletSubNoAdsMonthly),
      ]);
      final rows = await db.noAdsDao.getAll();
      expect(rows.single.source, 'subscription');
      expect(rows.single.expiresAt, isNotNull,
          reason: 'le store posait `expiresAt = null` : sans-pub a vie');
    });
  });

  // =========================================================================
  // A3 — LA RESTAURATION DIT CE QU ELLE A PU FAIRE
  // =========================================================================

  group('A3 — restaurer mes achats', () {
    test('sans paiement in-app disponible, la restauration le DIT', () async {
      final svc = await makeService();
      final outcome = await svc.restorePurchases();
      expect(outcome.status, PurchaseRestoreStatus.storeUnavailable,
          reason: 'un bouton qui ne produit rien est un mensonge (LOT X)');
    });
  });
}
