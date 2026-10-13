// L'ABONNE RECOIT SES DEUX ETAPES — ET IL NE LES RECEVAIT PAS (tache 813).
//
// CE QUI ETAIT LIVRE LE 11/10/2026. `grantSubscriberAllowance` etait ecrite EN
// ENTIER et juste : abonne ACTIF seulement, rien en demo, une seule fois par
// periode, credit du compte-etapes, ligne de journal.
// `kSubscriberStepsAllowance` valait bien 2. Ses tests passaient au vert. Et
// AUCUN fichier de `lib/` ne l'appelait : ses seuls appelants etaient
// `argent_594_test` et `demo_n_ecrit_rien_634_test`, plus la delegation de
// facade qui ne fait que passer l'appel.
//
// CE QUE CELA COUTAIT A UN VRAI ABONNE. Il payait deux euros par mois, ne
// recevait JAMAIS une seule etape, et l'ecran d'abonnement lui annoncait
// pourtant « 2 etapes creditees chaque mois ». L'application promettait ce
// qu'elle ne faisait pas — et aucun test ne pouvait le voir, parce que tous
// appelaient le mecanisme eux-memes. UN TEST QUI APPELLE LE MECANISME NE
// PROUVE JAMAIS QUE L'APPLICATION L'APPELLE.
//
// C'EST POURQUOI CES TESTS PARTENT DU RECU DU STORE, ET NON DE LA METHODE.
// Ils entrent par `debugHandlePurchases` — la boucle de completion, seul chemin
// par lequel un recu d'abonnement est honore en production — et par
// `MonetizationService.load()`, le chargement au boot. Si le cablage saute, ils
// rougissent ; si l'on se contentait d'appeler `grantSubscriberAllowance`, ils
// resteraient verts sur le trou.
//
// LES DEUX POINTS DE BRANCHEMENT, ET POURQUOI LES DEUX SONT NECESSAIRES :
//   1. la boucle de completion, pour le versement IMMEDIAT a la confirmation —
//      et le meme chemin porte le renouvellement automatique de la boutique et
//      la restauration d'achat, qui arrivent tous par un recu ;
//   2. le chargement au boot, pour RATTRAPER la periode courante quand aucun
//      recu n'arrive : l'abonne deja en cours au moment de ce lot, le
//      renouvellement dont le recu n'est pas redescendu, la reinstallation.
library;

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:moteur_gr/core/config/feature_flags.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/network/connectivity_monitor.dart';
import 'package:moteur_gr/core/services/monetization_service.dart';
import 'package:moteur_gr/core/services/wallet_iap_service.dart';
import 'package:moteur_gr/core/services/wallet_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Faux moniteur de connectivite (le complement store exige le reseau).
class _FakeConnectivityMonitor extends ConnectivityMonitor {
  _FakeConnectivityMonitor();

  @override
  Future<ConnectivityStatus> checkStatus() async =>
      ConnectivityStatusValues.online;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late WalletStore wallet;
  late WalletIapService iap;
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

  /// Le service MONTE COMME EN PRODUCTION : le validateur de recus accepte
  /// (sinon rien n'est livre du tout), et `load()` arme le cablage.
  ///
  /// `charger: false` laisse le service NON charge : c'est l'etat d'avant la
  /// tache 813, celui ou le crochet n'est pas encore branche.
  Future<MonetizationService> service({
    bool enDemo = false,
    bool charger = true,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    iap = WalletIapService(
      walletStore: wallet,
      noAdsDao: db.noAdsDao,
      testMode: true,
      receiptValidator: const LocalSanityReceiptValidator(
        serverValidationAvailable: true,
      ),
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
      freeTrailIds: const {},
      stagesOf: (id) => 0,
      enDemo: () => enDemo,
    );
    if (charger) await svc.load();
    return svc;
  }

  PurchaseDetails recu({
    required String productId,
    String id = 'p-1',
    PurchaseStatus status = PurchaseStatus.purchased,
  }) => PurchaseDetails(
    purchaseID: id,
    productID: productId,
    verificationData: PurchaseVerificationData(
      localVerificationData: 'jeton-store',
      serverVerificationData: 'jeton-store',
      source: 'test',
    ),
    transactionDate: '0',
    status: status,
  );

  group('813 — la souscription verse la cagnotte', () {
    test('le recu d abonnement du store credite les etapes promises', () async {
      final svc = await service();
      expect(wallet.balanceSteps, 0, reason: 'rien avant la souscription');

      await iap.debugHandlePurchases([recu(productId: kWalletSubNoAdsMonthly)]);

      expect(await svc.isSubscriberActive(), isTrue);
      expect(
        wallet.balanceSteps,
        kSubscriberStepsAllowance,
        reason:
            'L ECRAN D ABONNEMENT ANNONCE « 2 etapes creditees chaque mois ». '
            'Avant la tache 813 le solde restait a ZERO : le mecanisme '
            'existait, personne ne l appelait, et l abonne payait pour rien.',
      );
    });

    test('le crochet de versement est arme par load(), en meme temps que la '
        'boucle de completion', () async {
      // LE CABLAGE EST LA PREUVE QUE LE RESTE NE PEUT PAS DONNER. Un recu ne
      // doit pas pouvoir arriver avant que sa consequence soit branchee : les
      // deux s ouvrent dans le meme geste, `load()`.
      await service(charger: false);
      expect(
        iap.onSubscriptionDelivered,
        isNull,
        reason: 'service non charge : la boucle n est pas ouverte non plus',
      );
      final svc = await service();
      expect(
        iap.onSubscriptionDelivered,
        isNotNull,
        reason:
            'load() demarre startListening ET arme le versement — si le '
            'crochet restait nul, la boucle livrerait le sans-pub sans '
            'jamais verser une etape, exactement comme avant la tache 813',
      );
      expect(svc.isLoaded, isTrue);
    });

    test(
      'la cagnotte n est pas versee deux fois dans la meme periode',
      () async {
        final svc = await service();
        await iap.debugHandlePurchases([
          recu(productId: kWalletSubNoAdsMonthly),
        ]);
        expect(wallet.balanceSteps, kSubscriberStepsAllowance);

        // LA GARDE DE PERIODE EXISTAIT DEJA ET N A PAS ETE REFAITE : la cle de
        // preferences porte l echeance de l abo. Un second versement demande
        // dans la MEME periode est refuse, et il le DIT.
        final second = await svc.grantSubscriberAllowance();
        expect(second, SubscriberAllowanceOutcome.alreadyGranted);
        expect(
          wallet.balanceSteps,
          kSubscriberStepsAllowance,
          reason: 'une cagnotte versee deux fois est un credit gratuit',
        );
      },
    );

    test('une seconde ouverture de l application ne reverse rien', () async {
      final svc = await service();
      await iap.debugHandlePurchases([recu(productId: kWalletSubNoAdsMonthly)]);
      expect(wallet.balanceSteps, kSubscriberStepsAllowance);

      // DEUX PORTES DE PRODUCTION, UN SEUL VERSEMENT. Le rattrapage du boot ne
      // doit pas doubler ce que la boucle de completion vient de verser.
      await svc.load();
      await svc.load();
      expect(
        wallet.balanceSteps,
        kSubscriberStepsAllowance,
        reason:
            'le rattrapage du boot et la boucle du store se croisent a chaque '
            'ouverture : ils partagent la garde de periode, donc ils ne se '
            'doublent pas',
      );
    });

    test('le meme recu rejoue par le store ne credite pas deux fois', () async {
      await service();
      final unique = recu(productId: kWalletSubNoAdsMonthly);
      await iap.debugHandlePurchases([unique]);
      await iap.debugHandlePurchases([unique]);
      expect(
        wallet.balanceSteps,
        kSubscriberStepsAllowance,
        reason:
            'le store re-emet ses evenements (restauration, redemarrage) : '
            'l idempotence par purchaseID les absorbe avant le versement',
      );
    });
  });

  group('813 — la reouverture rattrape ce qu aucun recu n apporte', () {
    test('un abonne actif jamais credite recoit ses etapes au chargement '
        'suivant', () async {
      // L ETAT EXACT DU 11/10 AVANT CE LOT : un abonnement actif, et une
      // periode jamais payee. C est la situation de tout abonne deja souscrit
      // au moment de la livraison — il a paye des mois sans rien recevoir, et
      // aucun recu ne va revenir le lui rappeler.
      final svc = await service();
      await svc.onSubscriptionValidated();
      expect(await svc.isSubscriberActive(), isTrue);
      expect(
        wallet.balanceSteps,
        0,
        reason: 'la validation pose le sans-pub, elle ne verse pas',
      );

      await svc.load();
      expect(
        wallet.balanceSteps,
        kSubscriberStepsAllowance,
        reason:
            'sans ce rattrapage, l abonne deja en cours attendrait son '
            'prochain renouvellement pour toucher sa premiere etape',
      );
    });

    test('sans abonnement, le chargement ne verse rien', () async {
      final svc = await service();
      expect(await svc.isSubscriberActive(), isFalse);
      expect(wallet.balanceSteps, 0);
      expect(
        await svc.grantSubscriberAllowance(),
        SubscriberAllowanceOutcome.notSubscriber,
      );
    });
  });

  group('813 — ce que la cagnotte ne touche pas', () {
    test('en demo, aucune etape n est versee', () async {
      // BARRIERE D ECRITURE DE LA DEMO (tache 634) : une demonstration
      // n ecrit ni argent ni droit reel. Brancher le versement ne devait pas
      // ouvrir une porte dans cette barriere.
      final svc = await service(enDemo: true);
      await iap.debugHandlePurchases([recu(productId: kWalletSubNoAdsMonthly)]);
      expect(
        wallet.balanceSteps,
        0,
        reason: 'la demo ne credite pas un vrai compte-etapes',
      );
      expect(
        await svc.grantSubscriberAllowance(),
        SubscriberAllowanceOutcome.notSubscriber,
      );
    });

    test('un recu de RECHARGE ne declenche pas la cagnotte', () async {
      await service();
      await iap.debugHandlePurchases([recu(productId: kWalletCredits11)]);
      expect(
        wallet.balanceSteps,
        11,
        reason:
            'onze etapes achetees, onze etapes creditees : le versement de '
            'l abonne est accroche au recu d ABONNEMENT, pas a tout recu',
      );
    });
  });
}
