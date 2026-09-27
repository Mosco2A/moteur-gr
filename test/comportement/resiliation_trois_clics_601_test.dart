// ARRETER SON ABONNEMENT EN TROIS GESTES — tache 601, exigence de Chris.
//
// VERBATIM, 27/09 13:09 : « Et je veux un arreter votre abonnement en 3 clics
// comme le prevoit la loi, et pas planque au fin fond de l appli ».
//
// LE DROIT, SOURCE AVANT D'ECRIRE (base #100700). Article L215-1-1 du code de la
// consommation, cree par l'article 17 de la loi n° 2022-1158 du 16 aout 2022, en
// vigueur depuis le 1er JUIN 2023 (modalites : decret n° 2023-417 du 31 mai
// 2023). La fonctionnalite de resiliation doit etre GRATUITE, DIRECTE,
// PERMANENTE et FACILE D'ACCES, et l'interface visee inclut explicitement
// l'application mobile. Controle DGCCRF.
//
// LA CONTRAINTE TECHNIQUE QUI TIENT EN MEME TEMPS. Un abonnement vendu via
// Google Play ou l'App Store est facture PAR LA BOUTIQUE, et les deux
// plateformes interdisent un parcours d'annulation interne qui contournerait
// leur facturation. L'application ne peut donc PAS annuler elle-meme : elle doit
// OUVRIR la page de gestion de la boutique. Ces tests verifient donc exactement
// ca — et refusent l'inverse : un bouton qui pretendrait annuler sans rien
// ouvrir serait un faux succes sur le sujet le plus sensible.
//
// CE QUE CE FICHIER MESURE, EN DEUX ETAGES :
//
//  R1 — LE NOMBRE DE GESTES, COMPTE ET NON PROMIS. Depuis l'accueil reel de
//       l'application, on compte les gestes jusqu'au bouton d'arret. La reponse
//       doit tenir en TROIS. Ce test tombe si le bouton descend d'un niveau.
//
//  R2 — CE QUE LE BOUTON OUVRE VRAIMENT. Le lien profond de la boutique de
//       l'appareil, verifie sur les DEUX plateformes, et le message quand la
//       boutique ne s'ouvre pas — jamais un bouton muet (regle du LOT X).
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moteur_gr/core/config/store_subscription_links.dart';
import 'package:moteur_gr/core/services/wallet_iap_service.dart';
import 'package:moteur_gr/features/booking/providers/hebergement_peripherique_providers.dart';
import 'package:moteur_gr/features/monetization/presentation/subscription_screen.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

import '../structurel/parcours_reel.dart';

/// Faux lanceur de lien : enregistre ce qui a REELLEMENT ete demande.
///
/// On ne mesure pas des pixels : on compte les liens partis, comme le lot pub
/// compte les demandes parties a la regie.
class _LanceurEspion implements DeeplinkLauncher {
  _LanceurEspion({this.reussit = true});

  final bool reussit;
  final List<String> ouverts = <String>[];

  @override
  Future<bool> open(String url) async {
    ouverts.add(url);
    return reussit;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // =========================================================================
  // R1 — TROIS GESTES DEPUIS L'ACCUEIL, COMPTES
  // =========================================================================
  group('R1 — arreter son abonnement en trois gestes depuis l accueil', () {
    testWidgets('le chemin existe et ne coute que TROIS gestes', (tester) async {
      // L'ACCUEIL REEL : `depart` nul = exactement ou l'on arrive en ouvrant
      // l'icone de l'application. Aucun raccourci de route, aucun provider
      // simule : un bouton qui ne se trouve qu'avec six surcharges n'est pas un
      // bouton que le consommateur trouve.
      await monterAppliReelle(tester);

      var gestes = 0;

      // Geste 1 — les reglages, depuis l'accueil.
      final reglages = find.byIcon(Icons.settings_outlined);
      expect(reglages, findsWidgets,
          reason: 'l accueil doit offrir une entree vers les reglages');
      await tester.tap(reglages.first);
      await stabiliser(tester);
      gestes++;

      // Geste 2 — l'abonnement, depuis les reglages.
      final abonnement = find.byKey(const ValueKey('reglages-abonnement'));
      final atteignable = await amenerALEcran(tester, abonnement);
      expect(atteignable, isTrue,
          reason: 'l entree « abonnement » doit etre atteignable dans les '
              'reglages, pas enterree dans un sous-sous-menu');
      await tester.tap(abonnement);
      await stabiliser(tester);
      gestes++;

      // Geste 3 — arreter. LE BOUTON DOIT ETRE LA, SUR CET ECRAN.
      final arreter = find.byKey(const ValueKey('abo-arreter'));
      final visible = await amenerALEcran(tester, arreter);
      expect(visible, isTrue,
          reason: 'CE QUE LA LOI EXIGE : un acces DIRECT, PERMANENT et FACILE. '
              'Le bouton d arret doit vivre sur l ecran d abonnement lui-meme — '
              'celui qui dit deja ce que l abo donne et ce qu il ne donne pas. '
              'Un niveau de plus, et le compte passe a quatre');
      await tester.tap(arreter);
      await stabiliser(tester);
      gestes++;

      expect(gestes, lessThanOrEqualTo(3),
          reason: 'trois gestes au plus depuis l accueil (Chris, 27/09 13:09 : '
              '« en 3 clics comme le prevoit la loi, et pas planque au fin fond '
              'de l appli »). Mesure : $gestes');

      // ET LE GESTE PRODUIT QUELQUE CHOSE. Le telephone de ce harnais ne sait
      // ouvrir aucun lien (`url_launcher` rend false) : l ecran doit donc DIRE
      // que la boutique ne s ouvre pas, au lieu de rester muet.
      expect(
        find.text(t.monetization.cancelStoreUnavailable),
        findsOneWidget,
        reason: 'un appareil incapable d ouvrir la boutique doit l entendre '
            'dire — jamais un bouton muet (regle du LOT X)',
      );

      await demonterAppli(tester);
      erreursDeRendu(tester);
    });

    testWidgets('l ecran d abonnement dit comment arreter, au meme endroit '
        'qu il dit ce que l abo donne', (tester) async {
      await monterAppliReelle(tester, depart: '/subscription');

      // Les trois phrases doivent cohabiter sur le MEME ecran : ce que l abo
      // donne, ce qu il ne donne pas, et comment on l arrete. Un ecran qui vend
      // sans dire comment resilier est exactement ce que la loi vise.
      expect(find.text(t.monetization.subscriptionIncludesNoAds),
          findsOneWidget);
      expect(find.text(t.monetization.subscriptionExcludes), findsOneWidget);
      expect(find.text(t.monetization.cancelCta), findsOneWidget);
      expect(find.text(t.monetization.cancelExplains), findsOneWidget,
          reason: 'l ecran explique que l arret se fait dans la boutique qui '
              'facture, et que l acces court jusqu a la fin de la periode payee');

      await demonterAppli(tester);
      erreursDeRendu(tester);
    });
  });

  // =========================================================================
  // R2 — CE QUE LE BOUTON OUVRE VRAIMENT
  // =========================================================================
  group('R2 — le bouton ouvre la boutique, il ne pretend pas annuler', () {
    Future<_LanceurEspion> monterEcran(
      WidgetTester tester, {
      required TargetPlatform plateforme,
      bool boutiqueOuvrable = true,
    }) async {
      final espion = _LanceurEspion(reussit: boutiqueOuvrable);
      LocaleSettings.setLocaleRaw('fr');
      // LA REMISE A ZERO EST FAITE DANS LE CORPS DU TEST, PAS EN `addTearDown` :
      // le harnais verifie ses variables de debogage AVANT de derouler les
      // tear-downs, et laisser la surcharge en place fait echouer le test sur
      // « a foundation debug variable was changed » — un echec qui ne parle pas
      // du sujet.
      debugDefaultTargetPlatformOverride = plateforme;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            deeplinkLauncherProvider.overrideWithValue(espion),
          ],
          child: TranslationProvider(
            child: MaterialApp.router(
              routerConfig: GoRouter(
                initialLocation: '/subscription',
                routes: [
                  GoRoute(
                    path: '/subscription',
                    builder: (_, __) => const SubscriptionScreen(),
                  ),
                  GoRoute(
                      path: '/my-treks', builder: (_, __) => const SizedBox()),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return espion;
    }

    testWidgets('sur Android : la page Google Play de CET abonnement',
        (tester) async {
      final espion =
          await monterEcran(tester, plateforme: TargetPlatform.android);

      await tester.tap(find.byKey(const ValueKey('abo-arreter')));
      await tester.pumpAndSettle();

      expect(espion.ouverts, hasLength(1),
          reason: 'un lien part REELLEMENT — on ne mesure pas des pixels');
      expect(
        espion.ouverts.single,
        StoreSubscriptionLinks.googlePlay(productId: kWalletSubNoAdsMonthly),
        reason: 'forme documentee par Google : la page de gestion de CET '
            'abonnement, pas une liste ou il faut le retrouver',
      );
      expect(espion.ouverts.single, contains('sku=$kWalletSubNoAdsMonthly'));
      expect(espion.ouverts.single,
          contains('package=${StoreSubscriptionLinks.androidPackageName}'));
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('sur iOS : la page Abonnements de l App Store', (tester) async {
      final espion = await monterEcran(tester, plateforme: TargetPlatform.iOS);

      await tester.tap(find.byKey(const ValueKey('abo-arreter')));
      await tester.pumpAndSettle();

      expect(espion.ouverts, hasLength(1));
      expect(espion.ouverts.single, StoreSubscriptionLinks.appStore);
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('boutique injoignable : l ecran le DIT', (tester) async {
      final espion = await monterEcran(
        tester,
        plateforme: TargetPlatform.android,
        boutiqueOuvrable: false,
      );

      await tester.tap(find.byKey(const ValueKey('abo-arreter')));
      await tester.pumpAndSettle();

      expect(espion.ouverts, hasLength(1),
          reason: 'la tentative a bien eu lieu');
      expect(find.text(t.monetization.cancelStoreUnavailable), findsOneWidget,
          reason: 'et l echec se voit : le randonneur sait quoi faire');
      debugDefaultTargetPlatformOverride = null;
    });

    test('AUCUNE annulation interne : le lien sort vers la boutique', () {
      // LE FAUX SUCCES QU ON REFUSE D ECRIRE. Les deux boutiques interdisent un
      // parcours d annulation interne qui contournerait leur facturation, et un
      // bouton qui journaliserait une annulation sans rien annuler serait un
      // mensonge. Ce test verrouille la NATURE de l action : une sortie vers la
      // boutique, sur les deux plateformes.
      for (final lien in <String>[
        StoreSubscriptionLinks.googlePlay(productId: kWalletSubNoAdsMonthly),
        StoreSubscriptionLinks.googlePlayAll,
        StoreSubscriptionLinks.appStore,
      ]) {
        final uri = Uri.parse(lien);
        expect(uri.scheme, 'https');
        expect(
          uri.host,
          anyOf('play.google.com', 'apps.apple.com'),
          reason: 'la resiliation se fait chez celui qui facture',
        );
        expect(uri.path.toLowerCase(), contains('subscriptions'));
      }
    });

    test('le choix de la boutique suit la plateforme', () {
      expect(
        StoreSubscriptionLinks.pour(
          productId: kWalletSubNoAdsMonthly,
          plateforme: TargetPlatform.iOS,
        ),
        StoreSubscriptionLinks.appStore,
      );
      expect(
        StoreSubscriptionLinks.pour(
          productId: kWalletSubNoAdsMonthly,
          plateforme: TargetPlatform.android,
        ),
        StoreSubscriptionLinks.googlePlay(productId: kWalletSubNoAdsMonthly),
      );
    });
  });
}
