import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/config/feature_flags.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/network/connectivity_monitor.dart';
import 'package:moteur_gr/core/services/monetization_service.dart';
import 'package:moteur_gr/core/services/wallet_iap_service.dart';
import 'package:moteur_gr/core/services/wallet_store.dart';
import 'package:moteur_gr/i18n/translations.g.dart';
import 'package:moteur_gr/shared/widgets/paywall_sheet.dart';
import 'package:moteur_gr/shared/widgets/purchase_gate_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tests widget E4.17 / StepWays LOT 1 — purchase gate + ecran paywall.
///
/// Verifie : bandeau demo en gratuit (free), contenu nu en jouable (owned),
/// ouverture du paywall et achat via le compte-etapes (buyTrail) qui debloque
/// le trek quand le wallet couvre le prix.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late WalletStore wallet;
  late MonetizationService svc;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FeatureFlags.clearOverrides();
    db = AppDatabase(NativeDatabase.memory());
    final prefs = await SharedPreferences.getInstance();
    wallet = WalletStore(db: db, prefs: prefs);
    addTearDown(wallet.dispose);
    final iap = WalletIapService(
      walletStore: wallet,
      noAdsDao: db.noAdsDao,
      testMode: true,
    );
    addTearDown(iap.stopListening);
    svc = MonetizationService(
      walletStore: wallet,
      entitlementsDao: db.trekEntitlementsDao,
      noAdsDao: db.noAdsDao,
      iapService: iap,
      connectivityMonitor: ConnectivityMonitor(),
      prefs: prefs,
      showcaseTrailIds: const {},
    );
    await svc.load();
    // Wallet approvisionne pour que l'achat du paywall soit couvert (12 etapes).
    await wallet.credit(50);
  });

  tearDown(() async {
    FeatureFlags.clearOverrides();
    await db.close();
  });

  Widget wrap(Widget child) {
    return ProviderScope(
      overrides: [
        monetizationServiceProvider.overrideWithValue(svc),
        // Service deja charge : le gate rebuild sur cet etat resolu.
        monetizationReadyProvider.overrideWith((ref) async => svc),
      ],
      child: MaterialApp(home: Scaffold(body: child)),
    );
  }

  // Le gate observe desormais un StreamProvider adosse a un stream Drift
  // (isDemoModeProvider). Il faut demonter l'arbre AVANT la fin du corps de
  // test pour que Riverpod annule la souscription Drift : sinon le timer de la
  // query-stream reste pendant a la destruction de l'arbre (assertion
  // !timersPending). On demonte puis on laisse les annulations se resorber.
  Future<void> tearDownTree(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  }

  group('PurchaseGateWidget', () {
    testWidgets('trek non achete : bandeau demo affiche', (tester) async {
      await tester.pumpWidget(wrap(
        const PurchaseGateWidget(
          trailId: 'volcans',
          totalStages: 12,
          child: Text('Contenu du trek'),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text(t.monetization.demoBanner), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
      expect(find.text('Contenu du trek'), findsOneWidget);
      await tearDownTree(tester);
    });

    testWidgets('trek achete : contenu nu, pas de bandeau', (tester) async {
      await svc.buyTrail('volcans', totalStages: 12);

      await tester.pumpWidget(wrap(
        const PurchaseGateWidget(
          trailId: 'volcans',
          totalStages: 12,
          child: Text('Contenu du trek'),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text(t.monetization.demoBanner), findsNothing);
      expect(find.byIcon(Icons.lock_outline), findsNothing);
      expect(find.text('Contenu du trek'), findsOneWidget);
      await tearDownTree(tester);
    });

    testWidgets(
        'achat pendant affichage : le bandeau demo disparait sans remount '
        '(reserve QA)', (tester) async {
      await tester.pumpWidget(wrap(
        const PurchaseGateWidget(
          trailId: 'volcans',
          totalStages: 12,
          child: Text('Contenu du trek'),
        ),
      ));
      await tester.pumpAndSettle();

      // Etat initial : trek en demo -> bandeau visible.
      expect(find.text(t.monetization.demoBanner), findsOneWidget);

      // L'achat aboutit PENDANT que le gate est monte (aucun remount du widget).
      await svc.buyTrail('volcans', totalStages: 12);
      await tester.pumpAndSettle();

      // isDemoModeProvider relance via le stream d'entitlements : bandeau parti.
      expect(find.text(t.monetization.demoBanner), findsNothing);
      expect(find.byIcon(Icons.lock_outline), findsNothing);
      expect(find.text('Contenu du trek'), findsOneWidget);
      await tearDownTree(tester);
    });

    testWidgets('tap bandeau ouvre le paywall, achat debloque via wallet',
        (tester) async {
      await tester.pumpWidget(wrap(
        const PurchaseGateWidget(
          trailId: 'volcans',
          totalStages: 12,
          child: Text('Contenu du trek'),
        ),
      ));
      await tester.pumpAndSettle();

      // Ouvrir le paywall via le bandeau.
      await tester.tap(find.text(t.monetization.demoBanner));
      await tester.pumpAndSettle();

      // Ecran paywall affiche : titre + avantages + prix EUR (12 x 0,99).
      expect(find.byType(PaywallSheet), findsOneWidget);
      expect(find.text(t.monetization.paywallTitle), findsOneWidget);
      expect(find.text(t.monetization.featureNoAds), findsOneWidget);
      expect(
        find.text(t.monetization.buyCtaWithPrice(price: '11.88')),
        findsOneWidget,
      );

      // Achat via le compte-etapes (wallet suffisant).
      await tester.tap(find.byKey(const Key('paywall-buy-button')));
      await tester.pumpAndSettle();

      // Trek debloque : paywall ferme, possede, cache premium actif.
      expect(find.byType(PaywallSheet), findsNothing);
      expect(await svc.ownsTrail('volcans'), isTrue);
      expect(FeatureFlags.isPremiumEnabled('volcans'), isTrue);
      await tearDownTree(tester);
    });
  });
}
