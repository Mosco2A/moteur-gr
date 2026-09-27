// SENTIER DEMO (tache 601) — DEUX ENTREES AU CATALOGUE, ET LE DRAPEAU INVENTE
// DISPARAIT.
//
// DECISION DE CHRIS, 27/09 12:24, verbatim : « il faut un sentier demo, pas un
// sentier bride demo. Les donnees peuvent etre celle de mare a mare. Mais il y
// a mare a mare ET mare a mare demo des le catalogue ».
//
// CE QUE CE FICHIER MESURE, ET POURQUOI CHAQUE POINT COMPTE.
//
//  D1 — le catalogue porte DEUX entrees : le Mare a Mare payant et le Mare a
//       Mare demo gratuit. Le sentier demo est un sentier A PART ENTIERE : son
//       identifiant, son nom, ses donnees.
//  D2 — le vrai Mare a Mare redevient VENDABLE. Il ne l etait PAS : le drapeau
//       `isShowcaseTrail` le rendait `owned` sans achat, donc jamais payant.
//  D3 — la demo fonctionne ENTIEREMENT, sans achat : realisation comprise,
//       rien de bride, rien de grise.
//  D4 — la demo ne donne AUCUN droit sur le vrai sentier, et la progression
//       faite sur l une ne se melange pas avec celle de l autre.
//  D5 — LA PUB. Un sentier gratuit n est pas un sentier ACHETE : il n herite
//       donc PAS du sans-pub permanent reserve a l achat. Mais « EN MODE TREK
//       JAMAIS » tient aussi sur lui.
//  D6 — ANNULER L ABONNEMENT : la pub revient PARTOUT SAUF sur les sentiers
//       achetes (regle de Chris, 27/09 12:27). Le scenario complet n etait
//       teste NULLE PART.
//  D7 — LA CAGNOTTE VAUT 2 ETAPES PAR MOIS (Chris, 27/09 12:26), c est un
//       VERSEMENT PERIODIQUE et non un cadeau unique, et les etapes versees
//       restent acquises A VIE meme apres l arret de l abonnement.
//
// CHAQUE TEST A ETE ECRIT ROUGE AVANT SA CORRECTION (regle du lot).
library;

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/config/feature_flags.dart';
import 'package:moteur_gr/core/config/trail_catalog.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/network/connectivity_monitor.dart';
import 'package:moteur_gr/core/services/monetization_service.dart';
import 'package:moteur_gr/core/services/wallet_iap_service.dart';
import 'package:moteur_gr/core/services/wallet_store.dart';
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

/// Identifiant du sentier PAYANT (donnee du catalogue, jamais une localite
/// inventee par le test).
const kPayant = 'mare-a-mare-centre';

/// Identifiant du sentier DEMO GRATUIT.
const kDemo = 'mare-a-mare-centre-demo';

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
    now = DateTime(2026, 9, 27, 12);
  });

  tearDown(() async {
    FeatureFlags.clearOverrides();
    await db.close();
  });

  Future<MonetizationService> makeService({
    int walletSteps = 0,
    bool online = true,
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
    );
    await svc.load();
    if (walletSteps > 0) await wallet.credit(walletSteps);
    return svc;
  }

  // =========================================================================
  // D1 — DEUX ENTREES AU CATALOGUE
  // =========================================================================

  group('D1 — le catalogue porte le sentier payant ET le sentier demo', () {
    test('les DEUX entrees sont visibles au catalogue', () {
      expect(TrailCatalog.ids, contains(kPayant),
          reason: 'le Mare a Mare payant reste au catalogue');
      expect(TrailCatalog.ids, contains(kDemo),
          reason: 'Chris : « il y a mare a mare ET mare a mare demo des le '
              'catalogue » — deux entrees, pas une entree bridee');
    });

    test('le sentier demo a son PROPRE identifiant, distinct du payant', () {
      expect(kDemo, isNot(kPayant));
      final demo = TrailCatalog.byId(kDemo);
      expect(demo, isNotNull, reason: 'le sentier demo est une entree du '
          'catalogue, pas un mode d affichage du sentier payant');
      expect(demo!.id, isNot(TrailCatalog.byId(kPayant)!.id));
    });

    test('le sentier demo porte les DEUX PREMIERES etapes du Mare a Mare', () {
      final demo = TrailCatalog.byId(kDemo)!;
      expect(demo.totalStages, 2,
          reason: 'assez pour vivre le parcours entier, trop peu pour '
              'remplacer un sentier de sept etapes');
      expect(demo.region, TrailCatalog.byId(kPayant)!.region,
          reason: 'ses donnees sont REPRISES du Mare a Mare (Chris)');
    });
  });

  // =========================================================================
  // D2 — LE VRAI MARE A MARE EST VENDABLE
  // =========================================================================

  group('D2 — le vrai Mare a Mare est VENDABLE', () {
    test('sans achat, le vrai Mare a Mare n est PAS possede', () async {
      final svc = await makeService();
      expect(await svc.ownsTrail(kPayant), isFalse);
      expect(await svc.accessFor(kPayant), TrailAccess.free,
          reason: 'LE DEFAUT MESURE : le drapeau isShowcaseTrail rendait ce '
              'sentier `owned` sans le moindre achat — il n etait donc PAS '
              'vendable. Un sentier payant qu on ne peut pas vendre est un '
              'trou dans le modele, pas une vitrine');
    });

    test('sans achat, le vrai Mare a Mare n est PAS realisable', () async {
      final svc = await makeService();
      expect(await svc.canRealizeTrail(kPayant), isFalse,
          reason: 'le modele reserve la REALISATION au trek achete');
    });

    test('sans achat, le vrai Mare a Mare est en mode demo bride', () async {
      final svc = await makeService();
      expect(await svc.isDemoMode(kPayant), isTrue,
          reason: 'outils bridés, grisés, visibles — le niveau gratuit du '
              'modele eco §2 sur un sentier PAYANT');
    });

    test('achete avec le compte-etapes, il devient possede et realisable',
        () async {
      final svc = await makeService(walletSteps: 7);
      final outcome = await svc.buyTrail(kPayant, totalStages: 7);
      expect(outcome.isOwned, isTrue,
          reason: '7 etapes au compte-etapes couvrent les 7 etapes du sentier');
      expect(await svc.accessFor(kPayant), TrailAccess.owned);
      expect(await svc.canRealizeTrail(kPayant), isTrue);
      expect(svc.walletSteps, 0, reason: 'le prix a REELLEMENT ete debite');
    });
  });

  // =========================================================================
  // D3 — LA DEMO FONCTIONNE ENTIEREMENT
  // =========================================================================

  group('D3 — la demo fonctionne ENTIEREMENT, sans achat', () {
    test('la demo est jouable sans achat et sans compte-etapes', () async {
      final svc = await makeService();
      expect(await svc.accessFor(kDemo), TrailAccess.freeTrail,
          reason: 'un sentier GRATUIT est une ENTREE du modele — pas une '
              'exemption posee sur un sentier payant');
      expect((await svc.accessFor(kDemo)).isPlayable, isTrue);
    });

    test('la demo est REALISABLE sans achat', () async {
      final svc = await makeService();
      expect(await svc.canRealizeTrail(kDemo), isTrue,
          reason: 'Chris : « rien de bride, rien de grise, rien de '
              'verrouille, realisation comprise »');
    });

    test('la demo n est JAMAIS en mode demo bride', () async {
      final svc = await makeService();
      expect(await svc.isDemoMode(kDemo), isFalse,
          reason: 'aucun bridage : ni sac, ni entrainement, ni journal en '
              'lecture seule, ni bandeau');
    });

    test('on ne VEND pas un sentier gratuit : rien n est debite', () async {
      final svc = await makeService(walletSteps: 5);
      final outcome = await svc.buyTrail(kDemo, totalStages: 2);
      expect(outcome.status, PurchaseStatusResult.alreadyOwned,
          reason: 'l acces est deja acquis : l appel est idempotent et le dit');
      expect(svc.walletSteps, 5,
          reason: 'un sentier gratuit ne coute RIEN — aucune etape debitee');
      expect(await svc.ownsTrail(kDemo), isFalse,
          reason: 'et il ne devient pas un sentier ACHETE pour autant : '
              'aucun droit d achat n est pose, donc aucun privilege d achat');
    });
  });

  // =========================================================================
  // D4 — AUCUN DROIT CROISE, AUCUNE PROGRESSION MELANGEE
  // =========================================================================

  group('D4 — la demo ne donne AUCUN droit sur le vrai sentier', () {
    test('jouer la demo ne rend pas le vrai sentier realisable', () async {
      final svc = await makeService();
      expect(await svc.canRealizeTrail(kDemo), isTrue);
      expect(await svc.canRealizeTrail(kPayant), isFalse,
          reason: 'le sentier demo est un AUTRE sentier : il ne porte aucun '
              'droit sur celui qu il fait decouvrir');
      expect(await svc.ownsTrail(kPayant), isFalse);
      expect(await svc.accessFor(kPayant), TrailAccess.free);
    });

    test('acheter le vrai sentier ne change rien au statut de la demo',
        () async {
      final svc = await makeService(walletSteps: 7);
      await svc.buyTrail(kPayant, totalStages: 7);
      expect(await svc.accessFor(kPayant), TrailAccess.owned);
      expect(await svc.accessFor(kDemo), TrailAccess.freeTrail,
          reason: 'la demo reste ce qu elle est : un sentier gratuit');
    });

    test('la progression ne se melange pas : etapes acquises par sentier',
        () async {
      final svc = await makeService(walletSteps: 7);
      await svc.buyTrail(kPayant, totalStages: 7);
      expect(await svc.acquiredStagesFor(kPayant), 7);
      expect(await svc.acquiredStagesFor(kDemo), 0,
          reason: 'identifiants distincts = droits distincts = progressions '
              'distinctes. Rien ne coule d un sentier vers l autre');
    });

    test('les droits sont stockes sous des identifiants DISTINCTS', () async {
      final svc = await makeService(walletSteps: 7);
      await svc.buyTrail(kPayant, totalStages: 7);
      final droits = await db.trekEntitlementsDao.owned();
      expect(droits, contains(kPayant));
      expect(droits, isNot(contains(kDemo)),
          reason: 'le sentier gratuit n a pas de droit d ACHAT a son nom : '
              'sa gratuite est une propriete du catalogue, pas une ligne '
              'de droit posee en base');
    });
  });

  // =========================================================================
  // D5 — LA PUB SUR LE SENTIER DEMO
  // =========================================================================

  group('D5 — la pub sur le sentier demo', () {
    test('un sentier GRATUIT n herite PAS du sans-pub d un sentier ACHETE',
        () async {
      final svc = await makeService();
      expect(await svc.isNoAdsActive(kDemo), isFalse,
          reason: 'ARBITRAGE DU LOT : le modele eco §3 lie le sans-pub a un '
              'ETAT PAYANT ACTIF — « trek achete = sans pub sur ce trek ». Un '
              'sentier gratuit n a rien paye : il tombe donc dans le niveau '
              'gratuit du §2, « avec pub ». Le drapeau vitrine lui donnait le '
              'sans-pub PERMANENT reserve a l achat, et ce privilege offrait '
              'gratuitement ce que l abonnement fait payer');
      expect((await svc.accessFor(kDemo)).showAds, isTrue);
    });

    test('un ABONNE actif n a de pub NULLE PART, demo comprise', () async {
      final svc = await makeService();
      await svc.onSubscriptionValidated();
      expect(await svc.isNoAdsActive(kDemo), isTrue,
          reason: 'l abonnement a 2 euros donne le sans-pub PARTOUT tant qu il '
              'est actif — un sentier gratuit n y fait pas exception');
      expect(await svc.isNoAdsActive(kPayant), isTrue);
    });

    test('la demo reste JOUABLE pour un abonne (l abo ne debloque rien, '
        'mais un sentier gratuit n a rien a debloquer)', () async {
      final svc = await makeService();
      await svc.onSubscriptionValidated();
      expect(await svc.canRealizeTrail(kDemo), isTrue);
      expect(await svc.canRealizeTrail(kPayant), isFalse,
          reason: 'l arbitrage du 08/09 tient : l abo ne debloque pas la '
              'realisation d un sentier PAYANT');
    });
  });

  // =========================================================================
  // D6 — ANNULER L ABONNEMENT : PUB PARTOUT SAUF SUR LES SENTIERS ACHETES
  // =========================================================================

  group('D6 — annulation de l abonnement (regle de Chris, 27/09 12:27)', () {
    test('apres annulation : pub PARTOUT, SAUF sur le sentier achete',
        () async {
      final svc = await makeService(walletSteps: 7);

      // 1. Le randonneur ACHETE le Mare a Mare.
      expect((await svc.buyTrail(kPayant, totalStages: 7)).isOwned, isTrue);

      // 2. Il s abonne : sans pub PARTOUT.
      await svc.onSubscriptionValidated();
      expect(await svc.isNoAdsActive(kPayant), isTrue);
      expect(await svc.isNoAdsActive(kDemo), isTrue);
      expect(await svc.isNoAdsActive('gr-pyrenees'), isTrue);

      // 3. Il ARRETE l abonnement.
      await svc.onSubscriptionCanceled();
      expect(await svc.isSubscriberActive(), isFalse);

      // 4. LA REGLE : « il revoit la pub partout sauf sur les sentiers
      //    achetes ». Verbatim de Chris, 27/09 12:27.
      expect(await svc.isNoAdsActive(kPayant), isTrue,
          reason: 'le sentier ACHETE garde son sans-pub : la propriete d un '
              'sentier est permanente, elle ne depend pas de l abonnement');
      expect(await svc.isNoAdsActive(kDemo), isFalse,
          reason: 'le sentier gratuit n a rien paye : la pub revient');
      expect(await svc.isNoAdsActive('gr-pyrenees'), isFalse,
          reason: 'un sentier ni achete ni gratuit : la pub revient');
    });

    test('les etapes de la cagnotte deja versees RESTENT apres annulation',
        () async {
      final svc = await makeService();
      await svc.onSubscriptionValidated();
      expect(await svc.grantSubscriberAllowance(),
          SubscriberAllowanceOutcome.granted);
      final apresVersement = svc.walletSteps;
      expect(apresVersement, kSubscriberStepsAllowance);

      await svc.onSubscriptionCanceled();
      expect(svc.walletSteps, apresVersement,
          reason: 'REGLE D OR #99404 : les credits sont acquis A VIE, le '
              'sans-pub est lie a un etat actif. Arreter l abonnement retire '
              'le sans-pub, JAMAIS les etapes deja versees');
      expect(await svc.isSubscriberActive(), isFalse);
    });
  });

  // =========================================================================
  // D7 — LA CAGNOTTE : 2 ETAPES, PAR MOIS
  // =========================================================================

  group('D7 — la cagnotte vaut 2 etapes par mois (Chris, 27/09 12:26)', () {
    test('le montant est DECIDE et vaut 2 etapes', () {
      expect(kSubscriberStepsAllowance, 2,
          reason: 'Chris, 27/09 12:26 : « Le prix on l avait fixe a 2 euros '
              'mous = pub nul part et 2 etapes cagnottes par mois »');
    });

    test('le prix de l abonnement est DECLARE et vaut 2 euros par mois', () {
      expect(kSubscriptionPriceEur, 2.0,
          reason: 'un prix qui vit a l oral et nulle part dans le code est un '
              'prix qu on affiche faux le jour ou on l affiche');
    });

    test('sans abonnement, rien n est verse', () async {
      final svc = await makeService();
      expect(await svc.grantSubscriberAllowance(),
          SubscriberAllowanceOutcome.notSubscriber);
      expect(svc.walletSteps, 0);
    });

    test('LE VERSEMENT EST PERIODIQUE, PAS UN CADEAU UNIQUE', () async {
      final svc = await makeService();

      // Premier mois : versement.
      await svc.onSubscriptionValidated();
      expect(await svc.grantSubscriberAllowance(),
          SubscriberAllowanceOutcome.granted);
      expect(svc.walletSteps, 2);

      // Deuxieme appel DANS LA MEME PERIODE : rien (anti double-credit).
      expect(await svc.grantSubscriberAllowance(),
          SubscriberAllowanceOutcome.alreadyGranted);
      expect(svc.walletSteps, 2, reason: 'une cagnotte versee deux fois dans la '
          'meme periode serait un credit gratuit');

      // Mois suivant : le store reconduit l abonnement -> NOUVELLE echeance,
      // donc NOUVELLE periode, donc NOUVEAU versement.
      now = now.add(const Duration(days: 31));
      await svc.onSubscriptionValidated();
      expect(await svc.grantSubscriberAllowance(),
          SubscriberAllowanceOutcome.granted,
          reason: 'la cagnotte se verse TANT QUE l abonnement est actif : '
              'c est un versement mensuel, pas un cadeau de bienvenue');
      expect(svc.walletSteps, 4);
    });

    test('la cagnotte s ARRETE avec l abonnement', () async {
      final svc = await makeService();
      await svc.onSubscriptionValidated();
      await svc.grantSubscriberAllowance();
      await svc.onSubscriptionCanceled();

      now = now.add(const Duration(days: 31));
      expect(await svc.grantSubscriberAllowance(),
          SubscriberAllowanceOutcome.notSubscriber,
          reason: 'elle se verse tant que l abonnement est actif, et elle '
              's arrete avec lui');
      expect(svc.walletSteps, 2, reason: 'les 2 etapes du mois paye restent');
    });
  });
}
