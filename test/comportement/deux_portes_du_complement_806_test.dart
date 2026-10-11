// LES DEUX PORTES DU COMPLEMENT, ET LE PRIX EN ETAPES (tache 806).
//
// CE QUI SE PASSAIT, MESURE SUR LA TETE 994383d. Compte-etapes vide, le
// randonneur appuie sur « Acheter » : l application prenait D AUTORITE le plus
// petit pack couvrant le manque (`smallestPackCovering`). Pour le Mare a Mare
// Centre — sept etapes — cela voulait dire le pack de 11 a 9,99 EUR, alors que
// le manque exact vaut 6,93 EUR au tarif unite. L application engageait la
// depense la plus grosse sans demander, et ne montrait jamais l autre terme de
// l arbitrage.
//
// CE QUE CHRISTOPHE A DICTE LE 11/10, verbatim : « vous n avez pas assez d
// etapes cagnottees pour acheter ce circuit. acheter le complement ou achetez
// un pack ». Transpose au tutoiement (l application tutoie dans les cinq
// langues depuis le lot 757) et « circuit » rendu par « sentier », qui est le
// mot partout ailleurs.
//
// ET DEUX PORTES, PAS TROIS. L abonnement est ecarte NOMMEMENT : « on ne
// propose pas l abonnement pour le complement ». Il cagnotte des etapes chaque
// MOIS, il n en depose pas a l instant — le proposer a quelqu un a qui il
// manque trois etapes maintenant ne resout pas son probleme.
library;

import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moteur_gr/core/config/mare_a_mare_centre_trail_config.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/network/connectivity_monitor.dart';
import 'package:moteur_gr/core/providers/database_provider.dart';
import 'package:moteur_gr/core/services/monetization_service.dart';
import 'package:moteur_gr/core/services/wallet_iap_service.dart';
import 'package:moteur_gr/core/services/wallet_store.dart';
import 'package:moteur_gr/core/utils/montant_en_euros.dart';
import 'package:moteur_gr/features/ads/providers/ads_providers.dart';
import 'package:moteur_gr/i18n/translations.g.dart';
import 'package:moteur_gr/shared/widgets/paywall_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Le sentier de la demo : SEPT etapes, et c'est son prix.
const _sentier = mareAMareCentreTrailConfig;

class _EnLigne extends ConnectivityMonitor {
  @override
  Future<ConnectivityStatus> checkStatus() async =>
      ConnectivityStatusValues.online;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late WalletStore portefeuille;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    db = AppDatabase(NativeDatabase.memory());
    portefeuille = WalletStore(
      db: db,
      prefs: await SharedPreferences.getInstance(),
    );
    addTearDown(portefeuille.dispose);
  });

  tearDown(() async => db.close());

  Future<MonetizationService> service() async {
    final prefs = await SharedPreferences.getInstance();
    final iap = WalletIapService(
      walletStore: portefeuille,
      noAdsDao: db.noAdsDao,
      testMode: true,
    );
    addTearDown(iap.stopListening);
    final monetisation = MonetizationService(
      walletStore: portefeuille,
      entitlementsDao: db.trekEntitlementsDao,
      noAdsDao: db.noAdsDao,
      iapService: iap,
      connectivityMonitor: _EnLigne(),
      prefs: prefs,
    );
    await monetisation.load();
    return monetisation;
  }

  /// Une fenetre haute : la vitrine liste cinq avantages, puis le bouton, puis
  /// — en cas de rupture — le constat et les DEUX portes. Un ecran de test par
  /// defaut (800 x 600) deborde avant d avoir tout construit.
  void fenetreHaute(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
  }

  /// Ouvre la vitrine par le geste unique, et verifie qu'elle est bien la.
  Future<void> ouvrirLaVitrine(WidgetTester tester) async {
    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();
    expect(find.byType(PaywallSheet), findsOneWidget);
  }

  Widget monter(MonetizationService monetisation) {
    final conteneur = ProviderContainer(
      overrides: <Override>[
        databaseProvider.overrideWithValue(db),
        monetizationServiceProvider.overrideWithValue(monetisation),
        monetizationReadyProvider.overrideWith((ref) async => monetisation),
        // PUBLICITE COUPEE : le bouton « un jour sans publicite » de la
        // vitrine interroge sinon le vrai service de consentement, qui pose un
        // minuteur de six secondes que le temps simule du test ne fait jamais
        // tourner. Meme precaution que le banc du lot 614.
        adsReadyProvider.overrideWith((ref) async => false),
      ],
    );
    addTearDown(conteneur.dispose);
    return UncontrolledProviderScope(
      container: conteneur,
      child: TranslationProvider(
        child: MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: '/x',
            routes: <GoRoute>[
              // ON OUVRE LA VITRINE PAR LE GESTE UNIQUE, comme les trois
              // points d entree de l application (tache 614) : `buyTrail` est
              // la SEULE fonction de `lib/` a l ouvrir, et elle la pose en
              // feuille modale. Monter `PaywallSheet` directement en corps de
              // route ferait fermer la ROUTE a l achat reussi, au lieu de la
              // feuille — un banc qui ne ressemble plus a l application.
              GoRoute(
                path: '/x',
                builder: (_, __) => Consumer(
                  builder: (context, ref, _) => Scaffold(
                    body: Center(
                      child: ElevatedButton(
                        onPressed: () =>
                            buyTrail(context, ref, trailId: _sentier.id),
                        child: const Text('ouvrir'),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  group('Le prix d un sentier est un nombre d ETAPES (806)', () {
    test('le Mare a Mare Centre coute SEPT etapes', () {
      expect(
        _sentier.totalStages,
        7,
        reason:
            'c est le chiffre que Christophe a nomme, et celui que la carte '
            'doit annoncer a la place de « 6.93 € »',
      );
    });

    testWidgets('la vitrine annonce les etapes, jamais un montant', (
      tester,
    ) async {
      fenetreHaute(tester);
      final monetisation = await service();
      await tester.pumpWidget(monter(monetisation));
      await tester.pumpAndSettle();
      await ouvrirLaVitrine(tester);

      expect(
        find.text(t.monetization.buyCtaWithSteps(n: 7)),
        findsOneWidget,
        reason: 'le prix du sentier est son nombre d etapes',
      );
      expect(
        find.textContaining('€'),
        findsNothing,
        reason:
            'un montant en euros depend de la facon dont l acheteur a rempli '
            'sa cagnotte, donc de l acheteur et non du sentier',
      );
    });
  });

  group('Les DEUX portes quand la cagnotte ne suffit pas (806)', () {
    testWidgets('cagnotte vide : le constat et les deux portes', (
      tester,
    ) async {
      fenetreHaute(tester);
      final monetisation = await service();
      await tester.pumpWidget(monter(monetisation));
      await tester.pumpAndSettle();
      await ouvrirLaVitrine(tester);

      await tester.tap(find.byKey(const Key('paywall-buy-button')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('paywall-deux-portes')),
        findsOneWidget,
        reason: 'le randonneur doit voir qu il bute, et sur quoi',
      );
      expect(find.text(t.monetization.complementBody), findsOneWidget);
      expect(
        find.byKey(const Key('paywall-porte-complement')),
        findsOneWidget,
        reason: 'porte 1 : le complement exact, au tarif unite',
      );
      expect(
        find.byKey(const Key('paywall-porte-pack')),
        findsOneWidget,
        reason: 'porte 2 : le pack, au tarif degressif',
      );
      expect(
        monetisation.walletSteps,
        0,
        reason: 'un constat n engage RIEN : aucune etape debitee',
      );
      expect(
        await monetisation.ownsTrail(_sentier.id),
        isFalse,
        reason: 'et aucun droit pose',
      );
    });

    testWidgets('les deux portes chiffrent l arbitrage, en euros', (
      tester,
    ) async {
      // C EST ICI, ET SEULEMENT ICI, QUE L ON PAYE AVEC DE L ARGENT. Les deux
      // montants cote a cote SONT l arbitrage que Christophe veut montrer :
      // sept etapes a l unite (6,93 EUR) contre le pack de 11 (9,99 EUR).
      fenetreHaute(tester);
      final monetisation = await service();
      await tester.pumpWidget(monter(monetisation));
      await tester.pumpAndSettle();
      await ouvrirLaVitrine(tester);

      await tester.tap(find.byKey(const Key('paywall-buy-button')));
      await tester.pumpAndSettle();

      expect(
        find.text(montantEnEuros(7 * kStepTierEur, 'fr')),
        findsOneWidget,
        reason: 'le complement exact : sept etapes au tarif unite',
      );
      expect(
        find.text(montantEnEuros(kStepPacks.first.priceEur, 'fr')),
        findsOneWidget,
        reason: 'le pack qui couvre : onze etapes au tarif degressif',
      );
    });

    testWidgets('l ABONNEMENT n est PAS une des portes', (tester) async {
      // RESTRICTION DE CHRISTOPHE, 11/10 : « on ne propose pas l abonnement
      // pour le complement ». Il cagnotte chaque MOIS, il ne depose rien a
      // l instant : il ne repond pas au besoin de celui qui bute maintenant.
      fenetreHaute(tester);
      final monetisation = await service();
      await tester.pumpWidget(monter(monetisation));
      await tester.pumpAndSettle();
      await ouvrirLaVitrine(tester);

      await tester.tap(find.byKey(const Key('paywall-buy-button')));
      await tester.pumpAndSettle();

      expect(find.text(t.monetization.subscriptionCta), findsNothing);
      expect(find.text(t.monetization.subscriptionTitle), findsNothing);
    });

    testWidgets('la porte du complement exact ne PROMET rien qu elle ne '
        'puisse tenir', (tester) async {
      // Vendre exactement N etapes suppose un produit « une etape » achete en
      // QUANTITE, ou un produit par nombre d etapes. Aucun des deux n est
      // declare : les seuls consommables connus sont les packs 11, 16, 25 et
      // 50 (`kWalletCreditStepsByProduct`, le palier de seize est entre par la
      // tache 813). La porte existe et elle le DIT.
      expect(
        kWalletCreditStepsByProduct.keys.toSet(),
        <String>{
          kWalletCredits11,
          kWalletCredits16,
          kWalletCredits25,
          kWalletCredits50,
        },
        reason:
            'aucun produit « une etape » n est declare a ce jour : la porte 1 '
            'ne peut pas encore debiter',
      );

      fenetreHaute(tester);
      final monetisation = await service();
      await tester.pumpWidget(monter(monetisation));
      await tester.pumpAndSettle();
      await ouvrirLaVitrine(tester);
      await tester.tap(find.byKey(const Key('paywall-buy-button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('paywall-porte-complement')));
      await tester.pumpAndSettle();

      expect(
        find.text(t.monetization.complementExactPending),
        findsOneWidget,
        reason: 'elle dit ce qui lui manque au lieu de ne rien faire',
      );
      expect(monetisation.walletSteps, 0, reason: 'et elle ne debite rien');

      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });

    testWidgets('cagnotte suffisante : AUCUNE rupture, l achat passe', (
      tester,
    ) async {
      fenetreHaute(tester);
      final monetisation = await service();
      await portefeuille.credit(7);
      await tester.pumpWidget(monter(monetisation));
      await tester.pumpAndSettle();
      await ouvrirLaVitrine(tester);

      await tester.tap(find.byKey(const Key('paywall-buy-button')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('paywall-deux-portes')),
        findsNothing,
        reason:
            'on ne met pas une rupture devant quelqu un dont la cagnotte '
            'couvre le sentier',
      );
      expect(await monetisation.ownsTrail(_sentier.id), isTrue);
      expect(
        monetisation.walletSteps,
        0,
        reason: 'sept etapes prelevees, exactement le prix affiche',
      );

      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });
  });

  group('Le message de rupture existe dans les CINQ langues (806)', () {
    const List<String> langues = <String>['fr', 'en', 'de', 'it', 'es'];

    // LES TROIS CLES EN TEXTE SIMPLE. Les trois autres (les deux portes et le
    // libelle d achat) comptent des etapes : elles sont declarees en
    // `(plural)` et se verifient sur leur RENDU, plus bas.
    const List<String> clesDeTexte = <String>[
      'complementTitle',
      'complementBody',
      'complementExactPending',
    ];

    test('chaque langue porte les trois textes, sans parler d euros', () {
      final List<String> trouvailles = <String>[];
      for (final String langue in langues) {
        final Map<String, dynamic> bloc =
            (jsonDecode(
                      File('assets/i18n/$langue.i18n.json').readAsStringSync(),
                    )
                    as Map<String, dynamic>)['monetization']
                as Map<String, dynamic>;
        for (final String cle in clesDeTexte) {
          final Object? valeur = bloc[cle];
          if (valeur is! String || valeur.trim().isEmpty) {
            trouvailles.add('$langue : $cle manquante');
            continue;
          }
          if (valeur.contains('€')) {
            trouvailles.add('$langue : $cle porte un symbole euro');
          }
        }
      }
      expect(trouvailles, isEmpty, reason: trouvailles.join('\n'));
    });
  });

  // ==========================================================================
  // LE PLURIEL, LANGUE PAR LANGUE
  // ==========================================================================
  //
  // CE QUI ETAIT FAUX. Les trois libelles collaient le nombre a un mot
  // toujours au pluriel : « Acheter le complement — 1 etapes ». Et le
  // complement d UNE etape est le cas le plus FREQUENT du modele, celui du
  // randonneur a qui il manque juste de quoi finir — pas un cas limite.
  //
  // POURQUOI UN TEST PAR LANGUE, ET PAS UNE BOUCLE. Chaque langue a sa regle,
  // et c est precisement ce qu une concatenation a la main ne peut pas tenir.
  // Les ecrire une par une les rend LISIBLES : on voit « etape » devenir
  // « etapes », « Etappe » devenir « Etappen », « tappa » devenir « tappe ».
  // Une boucle generique aurait verifie que le code tourne, pas que le
  // francais est juste.
  group('Un nombre s accorde avec son nom (806)', () {
    test('fr : une etape, plusieurs etapes', () {
      final tr = AppLocale.fr.buildSync().monetization;
      expect(tr.buyCtaWithSteps(n: 1), 'Acheter — 1 étape');
      expect(tr.buyCtaWithSteps(n: 7), 'Acheter — 7 étapes');
      expect(tr.complementDoorExact(n: 1), 'Acheter le complément — 1 étape');
      expect(tr.complementDoorExact(n: 3), 'Acheter le complément — 3 étapes');
      expect(tr.complementDoorPack(n: 1), 'Prendre un pack — 1 étape');
      expect(tr.complementDoorPack(n: 11), 'Prendre un pack — 11 étapes');
      // LE FRANCAIS MET ZERO AU SINGULIER, et c est la regle CLDR, pas un
      // choix : la preuve que l accord vient de la LANGUE et non du code.
      expect(tr.buyCtaWithSteps(n: 0), 'Acheter — 0 étape');
    });

    test('en : one step, several steps', () {
      final tr = AppLocale.en.buildSync().monetization;
      expect(tr.buyCtaWithSteps(n: 1), 'Buy — 1 step');
      expect(tr.buyCtaWithSteps(n: 7), 'Buy — 7 steps');
      expect(tr.complementDoorExact(n: 1), 'Buy the complement — 1 step');
      expect(tr.complementDoorExact(n: 3), 'Buy the complement — 3 steps');
      expect(tr.complementDoorPack(n: 1), 'Get a pack — 1 step');
      expect(tr.complementDoorPack(n: 11), 'Get a pack — 11 steps');
      // ET L ANGLAIS MET ZERO AU PLURIEL, a l inverse du francais.
      expect(tr.buyCtaWithSteps(n: 0), 'Buy — 0 steps');
    });

    test('de : eine Etappe, mehrere Etappen', () {
      final tr = AppLocale.de.buildSync().monetization;
      expect(tr.buyCtaWithSteps(n: 1), 'Kaufen — 1 Etappe');
      expect(tr.buyCtaWithSteps(n: 7), 'Kaufen — 7 Etappen');
      expect(tr.complementDoorExact(n: 1), 'Fehlende Etappe kaufen — 1 Etappe');
      expect(
        tr.complementDoorExact(n: 3),
        'Fehlende Etappen kaufen — 3 Etappen',
      );
      expect(tr.complementDoorPack(n: 1), 'Ein Paket nehmen — 1 Etappe');
      expect(tr.complementDoorPack(n: 11), 'Ein Paket nehmen — 11 Etappen');
    });

    test('it : una tappa, piu tappe', () {
      final tr = AppLocale.it.buildSync().monetization;
      expect(tr.buyCtaWithSteps(n: 1), 'Acquista — 1 tappa');
      expect(tr.buyCtaWithSteps(n: 7), 'Acquista — 7 tappe');
      expect(tr.complementDoorExact(n: 1), 'Acquista il complemento — 1 tappa');
      expect(tr.complementDoorExact(n: 3), 'Acquista il complemento — 3 tappe');
      expect(tr.complementDoorPack(n: 1), 'Prendi un pacchetto — 1 tappa');
      expect(tr.complementDoorPack(n: 11), 'Prendi un pacchetto — 11 tappe');
    });

    test('es : una etapa, varias etapas', () {
      final tr = AppLocale.es.buildSync().monetization;
      expect(tr.buyCtaWithSteps(n: 1), 'Comprar — 1 etapa');
      expect(tr.buyCtaWithSteps(n: 7), 'Comprar — 7 etapas');
      expect(tr.complementDoorExact(n: 1), 'Comprar el complemento — 1 etapa');
      expect(tr.complementDoorExact(n: 3), 'Comprar el complemento — 3 etapas');
      expect(tr.complementDoorPack(n: 1), 'Coger un pack — 1 etapa');
      expect(tr.complementDoorPack(n: 11), 'Coger un pack — 11 etapas');
    });
  });

  // ==========================================================================
  // LE COMPTOIR ACCORDE SES NOMBRES LUI AUSSI
  // ==========================================================================
  //
  // LES TROIS CLES QUE J AVAIS SIGNALEES SANS LES CORRIGER, et la premiere
  // etait la plus genante parce qu elle vit DANS le chemin du complement :
  // un randonneur a qui il manque UNE etape et qui est hors ligne lisait
  // « Il manque 1 etapes ». Meme faute, meme endroit, meme jour.
  //
  // ET L ACCORD NE S ARRETE PAS AU NOM. Le verbe suit, et chaque langue a le
  // sien : « Il manque » reste invariable en francais, mais l allemand passe
  // de « Es fehlt » a « Es fehlen », l italien de « Manca » a « Mancano »,
  // l espagnol de « Te falta » a « Te faltan ». Le participe aussi s accorde
  // en francais (« creditee » / « creditees »), en italien (« accreditata » /
  // « accreditate ») et en espagnol (« abonada » / « abonadas »). Une
  // concatenation ne peut tenir aucun de ces trois accords a la fois.
  group('Le comptoir accorde ses nombres (806)', () {
    test('fr : le pack, la cagnotte et le refus hors-ligne', () {
      final tr = AppLocale.fr.buildSync().monetization;
      expect(tr.packSteps(n: 1), '1 étape');
      expect(tr.packSteps(n: 11), '11 étapes');
      expect(
        tr.subscriptionIncludesAllowance(n: 1),
        '1 étape créditée chaque mois',
      );
      expect(
        tr.subscriptionIncludesAllowance(n: 2),
        '2 étapes créditées chaque mois',
      );
      expect(
        tr.buyOutcomeOffline(n: 1),
        'Il manque 1 étape et le paiement exige une connexion. '
        "Rien n'a été débité.",
      );
      expect(
        tr.buyOutcomeOffline(n: 3),
        'Il manque 3 étapes et le paiement exige une connexion. '
        "Rien n'a été débité.",
      );
    });

    test('en : the pack, the allowance and the offline refusal', () {
      final tr = AppLocale.en.buildSync().monetization;
      expect(tr.packSteps(n: 1), '1 step');
      expect(tr.packSteps(n: 11), '11 steps');
      // ET LE MOT EST « step », PAS « stage » : la cagnotte credite des
      // unites de compte, pas des journees de marche.
      expect(
        tr.subscriptionIncludesAllowance(n: 1),
        '1 step credited every month',
      );
      expect(
        tr.subscriptionIncludesAllowance(n: 2),
        '2 steps credited every month',
      );
      expect(
        tr.buyOutcomeOffline(n: 1),
        'You are 1 step short and payment requires a connection. '
        'Nothing was charged.',
      );
      expect(
        tr.buyOutcomeOffline(n: 3),
        'You are 3 steps short and payment requires a connection. '
        'Nothing was charged.',
      );
    });

    test('de : das Paket, die Gutschrift und die Absage ohne Netz', () {
      final tr = AppLocale.de.buildSync().monetization;
      expect(tr.packSteps(n: 1), '1 Etappe');
      expect(tr.packSteps(n: 11), '11 Etappen');
      expect(
        tr.subscriptionIncludesAllowance(n: 1),
        '1 Etappe jeden Monat gutgeschrieben',
      );
      expect(
        tr.subscriptionIncludesAllowance(n: 2),
        '2 Etappen jeden Monat gutgeschrieben',
      );
      // LE VERBE SUIT : « Es fehlt » au singulier, « Es fehlen » au pluriel.
      expect(
        tr.buyOutcomeOffline(n: 1),
        'Es fehlt 1 Etappe und die Zahlung erfordert eine Verbindung. '
        'Es wurde nichts abgebucht.',
      );
      expect(
        tr.buyOutcomeOffline(n: 3),
        'Es fehlen 3 Etappen und die Zahlung erfordert eine Verbindung. '
        'Es wurde nichts abgebucht.',
      );
    });

    test('it : il pacchetto, l accredito e il rifiuto offline', () {
      final tr = AppLocale.it.buildSync().monetization;
      expect(tr.packSteps(n: 1), '1 tappa');
      expect(tr.packSteps(n: 11), '11 tappe');
      expect(
        tr.subscriptionIncludesAllowance(n: 1),
        '1 tappa accreditata ogni mese',
      );
      expect(
        tr.subscriptionIncludesAllowance(n: 2),
        '2 tappe accreditate ogni mese',
      );
      // « Manca » au singulier, « Mancano » au pluriel.
      expect(
        tr.buyOutcomeOffline(n: 1),
        'Manca 1 tappa e il pagamento richiede una connessione. '
        'Non è stato addebitato nulla.',
      );
      expect(
        tr.buyOutcomeOffline(n: 3),
        'Mancano 3 tappe e il pagamento richiede una connessione. '
        'Non è stato addebitato nulla.',
      );
    });

    test('es : el pack, el abono y el rechazo sin conexion', () {
      final tr = AppLocale.es.buildSync().monetization;
      expect(tr.packSteps(n: 1), '1 etapa');
      expect(tr.packSteps(n: 11), '11 etapas');
      expect(
        tr.subscriptionIncludesAllowance(n: 1),
        '1 etapa abonada cada mes',
      );
      expect(
        tr.subscriptionIncludesAllowance(n: 2),
        '2 etapas abonadas cada mes',
      );
      // « Te falta » au singulier, « Te faltan » au pluriel.
      expect(
        tr.buyOutcomeOffline(n: 1),
        'Te falta 1 etapa y el pago exige conexión. No se ha cobrado nada.',
      );
      expect(
        tr.buyOutcomeOffline(n: 3),
        'Te faltan 3 etapas y el pago exige conexión. No se ha cobrado nada.',
      );
    });
  });
}
