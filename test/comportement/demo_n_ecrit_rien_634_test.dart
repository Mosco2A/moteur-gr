import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/config/feature_flags.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/network/connectivity_monitor.dart';
import 'package:moteur_gr/core/services/monetization_service.dart';
import 'package:moteur_gr/core/services/wallet_iap_service.dart';
import 'package:moteur_gr/core/services/wallet_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// TACHE 634 — « ON EST EN MODE DEMO » : RIEN NE COMPTE (DEM-260929-1123).
///
/// Verbatim de Christophe, le 29/09 : en demo, « pas d etapes gagnees, pas de
/// diplome, pas de droits, rien en base ».
///
/// CE FICHIER VERROUILLE LA SURFACE QUI COMPTE LE PLUS : l'argent et les
/// droits. Une demonstration qui deduirait des etapes du compte du randonneur,
/// ou qui poserait un droit acquis sur un sentier, ne serait plus une
/// demonstration — ce serait une vente.
///
/// LES AUTRES SURFACES SONT BARREES AUX MEMES ENDROITS, et nommees ici pour que
/// la liste soit lisible d'un seul endroit : la session de trek et sa trace GPS
/// (`tracking_providers.dart`, deux persistances + les points de fond), la
/// progression historique (`tracking_provider.dart`), le journal
/// (`journal_providers.dart`, quatre gestes), le sac
/// (`checklist_provider.dart`, chaque ecriture), la capture GPS de fond, la
/// porte de demarrage du cockpit, et la demande d'avis sur le store a
/// l'ouverture du diplome.
class _FauxReseau extends ConnectivityMonitor {
  @override
  Future<ConnectivityStatus> checkStatus() async =>
      ConnectivityStatusValues.online;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late WalletStore wallet;
  var enDemo = false;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FeatureFlags.clearOverrides();
    enDemo = false;
    db = AppDatabase(NativeDatabase.memory());
    wallet = WalletStore(db: db, prefs: await SharedPreferences.getInstance());
    addTearDown(wallet.dispose);
  });

  tearDown(() async {
    FeatureFlags.clearOverrides();
    await db.close();
  });

  Future<MonetizationService> service({int etapes = 0}) async {
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
      connectivityMonitor: _FauxReseau(),
      prefs: prefs,
      stagesOf: (id) => id == 'sentier-payant' ? 5 : 0,
      // La barriere est une FONCTION : elle est interrogee a l'instant de
      // l'ecriture, donc entrer ou quitter la demo agit sans reconstruire le
      // service. C'est ce que fait le provider de production.
      enDemo: () => enDemo,
    );
    await svc.load();
    if (etapes > 0) await wallet.credit(etapes);
    return svc;
  }

  group('hors demo, rien ne change — le comportement d origine est intact', () {
    test('un achat finance par le compte passe normalement', () async {
      final svc = await service(etapes: 20);
      final resultat = await svc.buyTrail('sentier-payant');
      expect(resultat.status, PurchaseStatusResult.owned);
      expect(await svc.ownsTrail('sentier-payant'), isTrue);
      expect(wallet.snapshot.balanceSteps, 15);
    });
  });

  group('en demo, AUCUNE ecriture d argent ni de droit', () {
    test('acheter un sentier est REFUSE, et le refus se DIT', () async {
      final svc = await service(etapes: 20);
      enDemo = true;

      final resultat = await svc.buyTrail('sentier-payant');
      expect(resultat.status, PurchaseStatusResult.refuseEnDemo);

      // LES DEUX PREUVES QUI COMPTENT : aucun droit pose, aucune etape debitee.
      expect(await svc.ownsTrail('sentier-payant'), isFalse);
      expect(wallet.snapshot.balanceSteps, 20);
      expect(wallet.snapshot.lifetimeSpentSteps, 0);
      expect(
        await db.trekEntitlementsDao.getByTrailId('sentier-payant'),
        isNull,
      );
    });

    test('et l achat redevient possible en sortant de la demo', () async {
      // La barriere ne casse rien : elle suspend, elle n'ampute pas.
      final svc = await service(etapes: 20);
      enDemo = true;
      expect(
        (await svc.buyTrail('sentier-payant')).status,
        PurchaseStatusResult.refuseEnDemo,
      );
      enDemo = false;
      expect(
        (await svc.buyTrail('sentier-payant')).status,
        PurchaseStatusResult.owned,
      );
      expect(wallet.snapshot.balanceSteps, 15);
    });

    test('recharger le compte est refuse', () async {
      final svc = await service();
      enDemo = true;
      expect(await svc.rechargeWallet(kStepPacks.first), isFalse);
      expect(wallet.snapshot.balanceSteps, 0);
    });

    test('s abonner est refuse', () async {
      final svc = await service();
      enDemo = true;
      expect(await svc.subscribe(), isFalse);
    });

    test('la recompense video n ecrit rien en base', () async {
      final svc = await service();
      enDemo = true;
      await svc.grantRewardNoAds();
      expect(await svc.isRewardNoAdsActive(), isFalse);
      expect(await db.noAdsDao.getAll(), isEmpty);
    });

    test('la cagnotte d abonne n est pas versee', () async {
      final svc = await service();
      enDemo = true;
      expect(
        await svc.grantSubscriberAllowance(),
        SubscriberAllowanceOutcome.notSubscriber,
      );
      expect(wallet.snapshot.balanceSteps, 0);
    });

    test('restaurer des achats reels est refuse', () async {
      final svc = await service();
      enDemo = true;
      final r = await svc.restorePurchases();
      expect(r.status, PurchaseRestoreStatus.storeUnavailable);
      expect(r.itemsRestored, 0);
    });

    test('une demo n EFFACE pas les droits reels du randonneur', () async {
      // Effacer est encore une ecriture. Un randonneur qui possede un sentier
      // doit le retrouver intact en sortant de la demonstration.
      final svc = await service(etapes: 20);
      await svc.buyTrail('sentier-payant');
      expect(await svc.ownsTrail('sentier-payant'), isTrue);

      enDemo = true;
      await svc.reset();
      expect(
        await svc.ownsTrail('sentier-payant'),
        isTrue,
        reason: 'la demo a efface un droit REEL',
      );
    });
  });

  group('la barriere est ABSENTE par defaut', () {
    test('un service construit sans elle n est jamais en demo', () async {
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
        connectivityMonitor: _FauxReseau(),
        prefs: prefs,
        stagesOf: (_) => 5,
      );
      expect(
        svc.enDemo,
        isFalse,
        reason:
            'le comportement d origine doit etre strictement inchange '
            'pour tous les appelants qui ignorent ce mode',
      );
    });
  });
}
