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

import '../../structurel/regie_pub_absente.dart';
import 'package:moteur_gr/core/branding/stepways_icons.dart';

/// Tests widget E4.17 / StepWays LOT 1 — purchase gate + ecran paywall.
///
/// Verifie : bandeau demo en gratuit (free), contenu nu en jouable (owned),
/// ouverture du paywall et achat via le compte-etapes (buyTrail) qui debloque
/// le trek quand le wallet couvre le prix.
///
/// LE SENTIER DE CE TEST EST UN VRAI SENTIER DU CATALOGUE (tache 614). Il
/// s appelait « volcans » — un identifiant qui n existe nulle part — et le
/// nombre d etapes qui fixait le prix etait ECRIT A LA MAIN dans le test, a
/// cote. Depuis que l achat passe par le geste unique [acheterSentier], le prix
/// est resolu depuis le CATALOGUE : le nombre d etapes n est plus quelque chose
/// qu un appelant declare, c est une propriete du sentier. On prend donc
/// `gr-pyrenees`, qui porte exactement les 12 etapes que ce test attendait —
/// le prix verifie (11,88 EUR) est le meme, mais il vient desormais de la
/// donnee au lieu d un nombre recopie.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // LE SEUL ROUGE QUE CE DEPOT PORTAIT, ET SA CAUSE EST TROUVEE (tache 595).
  //
  // Ce test echouait sur « A Timer is still pending even after the widget tree
  // was disposed », un message qui n accuse rien et qu on a longtemps subi.
  // La cause est la MEME que celle rencontree en branchant la banniere : la
  // vitrine ([PaywallSheet]) observe `adsReadyProvider` pour savoir si elle peut
  // proposer la video recompensee. Cela demarre l amorce du consentement
  // publicitaire, qui appelle le SDK Google Mobile Ads. Dans un test, ce SDK n
  // est branche a personne — et un canal muet ne rend pas `null`, il fait lever
  // `MissingPluginException` a un endroit que le SDK n attrape pas : ni le
  // callback de succes ni celui d echec ne sont appeles, et seul le garde-fou
  // de SIX SECONDES de `AdsConsentService` rend la main. Six secondes de temps
  // REEL, qu un test de widgets ne fait jamais s ecouler.
  //
  // L appareil de ce test declare donc honnetement qu il n a pas de regie
  // publicitaire. Rien n est masque : ce que ce test verifie — le bandeau, la
  // vitrine, l achat par le portefeuille — est intact, et la video recompensee
  // ne s affiche simplement pas, ce qui est le comportement CORRECT sur un
  // appareil sans regie.
  //
  // UNE SEULE CAUSE, DEUX DIAGNOSTICS, ET LA MESURE QUI LES REUNIT (tache 598).
  // Les lots 594 et 595 ont croise ce rouge separement et ont accuse deux
  // choses : `adsReadyProvider` (594) et le minuteur de six secondes d
  // `AdsConsentService` (595). CE N EST PAS DEUX CAUSES : c est la TETE et la
  // QUEUE d une seule chaine. `adsReadyProvider` est la PORTE par laquelle la
  // vitrine entre dans le module ; le garde-fou de six secondes est le MINUTEUR
  // qui reste pendant. Chronometre a la fusion, sur le depot reuni :
  //   * sans aucun garde-fou, `adsReadyProvider` rend `false` en 6030 ms — soit
  //     exactement `AdsConsentService._bootTimeout` — et la
  //     `MissingPluginException` du canal `.../ump` s echappe dans la zone ;
  //   * avec l appareil honnete ci-dessous, il rend `false` en 1 ms.
  // Six mille trente millisecondes contre une : le minuteur EST le defaut, et le
  // fermer a la source le SUPPRIME au lieu de le contourner.
  //
  // ON NE GARDE DONC QU UNE SEULE CORRECTION, et c est celle-ci. La surcharge de
  // `adsReadyProvider` que portait le lot 594 a ete RETIREE a la reunion : elle
  // fermait UNE porte alors que le lot 595 vient d en ouvrir d autres sur le
  // meme module (le cockpit, le catalogue, `bannerAdProvider`), et deux
  // corrections concurrentes du meme defaut fabriquent un troisieme bug. La
  // fondation structurelle, elle, porte deja cinq autres fichiers de test.
  setUp(brancherAucuneRegiePub);

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
      freeTrailIds: const {},
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
        // AUCUNE SURCHARGE DU MODULE PUBLICITAIRE ICI, ET C'EST VOULU
        // (tache 598). Le lot 594 posait a cette ligne
        // `adsReadyProvider.overrideWith(false)`. Son diagnostic etait juste —
        // c'est bien par ce provider que la vitrine entre dans le module — mais
        // c'etait la SECONDE correction du MEME defaut, deja ferme a sa source
        // par `brancherAucuneRegiePub` (voir la mesure en tete de ce fichier).
        // On garde la porte OUVERTE et l'appareil HONNETE : le CTA « regarder
        // une pub » suit donc le vrai chemin de decision et disparait parce que
        // l'appareil n'a pas de regie, pas parce qu'un test l'a debranche.
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
          trailId: 'gr-pyrenees',
          child: Text('Contenu du trek'),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text(t.monetization.demoBanner), findsOneWidget);
      expect(find.byWidgetPredicate((w) => w is StepIcon && w.asset == StepwaysIcons.cadenas), findsOneWidget);
      expect(find.text('Contenu du trek'), findsOneWidget);
      await tearDownTree(tester);
    });

    testWidgets('trek achete : contenu nu, pas de bandeau', (tester) async {
      await svc.buyTrail('gr-pyrenees');

      await tester.pumpWidget(wrap(
        const PurchaseGateWidget(
          trailId: 'gr-pyrenees',
          child: Text('Contenu du trek'),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text(t.monetization.demoBanner), findsNothing);
      expect(find.byWidgetPredicate((w) => w is StepIcon && w.asset == StepwaysIcons.cadenas), findsNothing);
      expect(find.text('Contenu du trek'), findsOneWidget);
      await tearDownTree(tester);
    });

    testWidgets(
        'achat pendant affichage : le bandeau demo disparait sans remount '
        '(reserve QA)', (tester) async {
      await tester.pumpWidget(wrap(
        const PurchaseGateWidget(
          trailId: 'gr-pyrenees',
          child: Text('Contenu du trek'),
        ),
      ));
      await tester.pumpAndSettle();

      // Etat initial : trek en demo -> bandeau visible.
      expect(find.text(t.monetization.demoBanner), findsOneWidget);

      // L'achat aboutit PENDANT que le gate est monte (aucun remount du widget).
      await svc.buyTrail('gr-pyrenees');
      await tester.pumpAndSettle();

      // isDemoModeProvider relance via le stream d'entitlements : bandeau parti.
      expect(find.text(t.monetization.demoBanner), findsNothing);
      expect(find.byWidgetPredicate((w) => w is StepIcon && w.asset == StepwaysIcons.cadenas), findsNothing);
      expect(find.text('Contenu du trek'), findsOneWidget);
      await tearDownTree(tester);
    });

    testWidgets('tap bandeau ouvre le paywall, achat debloque via wallet',
        (tester) async {
      await tester.pumpWidget(wrap(
        const PurchaseGateWidget(
          trailId: 'gr-pyrenees',
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
      expect(await svc.ownsTrail('gr-pyrenees'), isTrue);
      expect(FeatureFlags.isPremiumEnabled('gr-pyrenees'), isTrue);
      // ET L'ACHAT LE DIT (tache 594, A3) : le bouton jetait son resultat.
      expect(find.text(t.monetization.buyOutcomeOwned), findsOneWidget);
      // On laisse le message se retirer avant de demonter l'arbre.
      await tester.pump(const Duration(seconds: 5));
      await tearDownTree(tester);
    });
  });
}
