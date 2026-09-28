// L ACHAT DEPUIS LE CATALOGUE ET LA PREPARATION, ET LE BOUTON UN JOUR SANS PUB
// (tache 614, GO-73). Deux demandes de Christophe du 28/09 11:41, verbatim :
// « Il faut que l achat puisse se faire du catalogue et depuis la preparation.
// Il faut aussi un bouton 1 jour sans pub : regarder la video ».
//
// LE PREMIER DEFAUT EST COMMERCIAL, PAS ERGONOMIQUE, ET IL A ETE MESURE AVANT
// D ECRIRE UNE LIGNE. Le seul chemin d achat d un sentier partait du bouton
// « Démarrer la randonnée » (`hub_start_trek_button.dart`) : on ne pouvait donc
// payer qu a l instant OU L ON PART. Celui qui decouvre un sentier au catalogue
// et veut l acheter tout de suite, celui qui prepare depuis trois semaines et se
// decide un soir : aucun des deux n avait de bouton. Et le bouton de depart est
// GRISE tant que les trois cartes coeur de la preparation ne sont pas faites —
// il ne pouvait donc rien vendre a ce deuxieme-la du tout.
//
// CE QUE CE GROUPE EXIGE, ET C EST LA FORME QUI COMPTE AUTANT QUE LE NOMBRE :
// TROIS PORTES, UN SEUL CHEMIN. Pas trois implementations du meme achat — un
// seul geste ([acheterSentier]) appele depuis trois endroits, exactement comme
// `choisirSentier` a unifie la bascule de sentier au lot 606. Trois
// implementations auraient derive en trois prix, d autant que le catalogue est
// desormais DISTANT (tache 605) : un sentier recu par le reseau n a pas le
// nombre d etapes du sentier compile du meme nom.
//
// LE SECOND DEFAUT EST L INVERSE : TOUT EXISTAIT SAUF L ENDROIT OU APPUYER. Le
// service de pub recompensee, l octroi de 24 h en base avec son echeance, la
// lecture de l etat, l identifiant d unite publicitaire — tout tournait. Une
// seule entree existait, au fond de la vitrine d achat, c est-a-dire la ou l on
// vient pour PAYER et pas la ou la publicite gene. Le bouton se pose donc SUR
// la banniere, et son libelle dit ce qu on OBTIENT avant ce qu on fait.
//
// TESTS ECRITS AVANT LA CORRECTION.
library;

import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moteur_gr/core/config/feature_flags.dart';
import 'package:moteur_gr/core/config/mare_a_mare_centre_demo_trail_config.dart';
import 'package:moteur_gr/core/config/mare_a_mare_centre_trail_config.dart';
import 'package:moteur_gr/core/config/trail_catalog.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/network/connectivity_monitor.dart';
import 'package:moteur_gr/core/providers/database_provider.dart';
import 'package:moteur_gr/core/services/monetization_service.dart';
import 'package:moteur_gr/core/services/wallet_iap_service.dart';
import 'package:moteur_gr/core/services/wallet_store.dart';
import 'package:moteur_gr/features/ads/data/banner_ad_presenter.dart';
import 'package:moteur_gr/features/ads/presentation/banner_ad_slot.dart';
import 'package:moteur_gr/features/ads/providers/ads_providers.dart';
import 'package:moteur_gr/features/hub/presentation/widgets/hub_buy_trek_button.dart';
import 'package:moteur_gr/features/trail/presentation/trail_catalog_screen.dart';
import 'package:moteur_gr/i18n/translations.g.dart';
import 'package:moteur_gr/shared/widgets/paywall_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Le sentier PAYANT du catalogue, et le sentier GRATUIT qui le fait decouvrir.
const _sentierPayant = mareAMareCentreTrailConfig;
const _sentierGratuit = mareAMareCentreDemoTrailConfig;

/// Regie de publicite SIMULEE : elle ne contacte rien, et elle COMPTE.
///
/// Meme mecanique que `pub_v1_595_test.dart` : « rien a l ecran » se truque avec
/// un widget invisible, « aucune demande partie » ne se truque pas.
class _RegieSimulee implements BannerAdPresenter {
  final List<BannerAdRequest> demandes = <BannerAdRequest>[];

  @override
  Future<LoadedBanner?> load(BannerAdRequest request) async {
    demandes.add(request);
    return LoadedBanner(
      view: const SizedBox(key: ValueKey('banniere-simulee')),
      height: 50,
      dispose: () async {},
    );
  }
}

class _ReseauEnLigne extends ConnectivityMonitor {
  @override
  Future<ConnectivityStatus> checkStatus() async =>
      ConnectivityStatusValues.online;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late WalletStore portefeuille;
  late DateTime maintenant;
  late _RegieSimulee regie;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    FeatureFlags.clearOverrides();
    db = AppDatabase(NativeDatabase.memory());
    portefeuille = WalletStore(
      db: db,
      prefs: await SharedPreferences.getInstance(),
    );
    addTearDown(portefeuille.dispose);
    maintenant = DateTime(2026, 9, 28, 11, 41);
    regie = _RegieSimulee();
  });

  tearDown(() async {
    FeatureFlags.clearOverrides();
    await db.close();
  });

  /// Monte le monde : monetisation REELLE sur base memoire, regie simulee,
  /// consentement publicitaire pilote.
  Future<MonetizationService> service({bool pubAutorisee = true}) async {
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
      connectivityMonitor: _ReseauEnLigne(),
      nowFn: () => maintenant,
      prefs: prefs,
      freeTrailIds: TrailCatalog.freeIds,
    );
    await monetisation.load();
    return monetisation;
  }

  /// LE CONTENEUR VIT PLUS LONGTEMPS QUE L ARBRE, ET CE N EST PAS UN DETAIL.
  ///
  /// Un `ProviderScope` pose dans l arbre se DETRUIT pendant le demontage du
  /// widget, donc a l interieur du temps simule du test : les abonnements Drift
  /// qu il ferme posent alors un minuteur a duree nulle que le test n a plus
  /// l occasion de faire tourner, et `flutter test` echoue sur « A Timer is
  /// still pending » — un message qui ne parle pas de ce qu on mesure. On cree
  /// donc le conteneur ICI et on le detruit en `addTearDown`, apres la fin du
  /// corps du test. C est la meme precaution que `pub_v1_595_test.dart`.
  ProviderContainer conteneur(
    MonetizationService monetisation, {
    bool pubAutorisee = true,
  }) {
    final c = ProviderContainer(
      overrides: <Override>[
        databaseProvider.overrideWithValue(db),
        monetizationServiceProvider.overrideWithValue(monetisation),
        monetizationReadyProvider.overrideWith((ref) async => monetisation),
        adsReadyProvider.overrideWith((ref) async => pubAutorisee),
        bannerAdPresenterProvider.overrideWithValue(regie),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  /// Une fenetre haute : le catalogue porte quatre sentiers, et chaque carte a
  /// grandi d un bouton. Un ListView ne CONSTRUIT pas ce qui est hors champ.
  void fenetreHaute(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 6000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
  }

  Widget monterEcran(MonetizationService monetisation, Widget ecran) {
    return UncontrolledProviderScope(
      container: conteneur(monetisation, pubAutorisee: false),
      child: TranslationProvider(
        child: MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: '/x',
            routes: [
              GoRoute(path: '/x', builder: (_, __) => ecran),
              GoRoute(
                path: '/home',
                builder: (_, __) => const Scaffold(body: Text('STUB HOME')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Marque un sentier comme ACHETE, par la base, sans passer par le magasin.
  Future<void> marquerAchete(String trailId) async {
    await db.trekEntitlementsDao.upsert(
      TrekEntitlementsCompanion.insert(
        trailId: trailId,
        owned: const Value(true),
        updatedAt: maintenant,
      ),
    );
  }

  /// Tous les fichiers Dart de `lib/`.
  List<File> sourcesDeLib() => Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();

  // =========================================================================
  // A1 — TROIS PORTES, UN SEUL CHEMIN DE PAIEMENT
  // =========================================================================
  group('A1 — un seul geste d achat, appele de trois endroits', () {
    test('la VITRINE n a qu UN SEUL appelant dans tout lib/', () {
      // LA MESURE QUI COMPTE. Avant la tache 614, `showPaywallSheet` etait
      // publique et SIX fichiers l appelaient, chacun avec son propre
      // `totalStages` — donc six occasions d afficher le mauvais prix. Elle est
      // devenue privee ; son unique appelant est [acheterSentier], dans le
      // fichier qui la porte. Ce test refuse un septieme chemin d achat.
      final fautifs = <String>[];
      for (final f in sourcesDeLib()) {
        final chemin = f.path.replaceAll(r'\', '/');
        if (chemin.endsWith('shared/widgets/paywall_sheet.dart')) continue;
        final source = f.readAsStringSync();
        for (final interdit in const ['showPaywallSheet', 'PaywallSheet(']) {
          if (source.contains(interdit)) fautifs.add('$chemin : $interdit');
        }
      }
      expect(fautifs, isEmpty,
          reason: 'la vitrine ne s ouvre QUE par acheterSentier. Un ecran qui '
              'l ouvre lui-meme refait le chemin de paiement, et refait donc '
              'le prix.\n  ${fautifs.join('\n  ')}');
    });

    test('les TROIS points d entree empruntent ce geste', () {
      // Les trois endroits que Christophe a nommes : le catalogue, la
      // preparation, et le depart (qui existait deja seul).
      const portes = <String, String>{
        'catalogue': 'lib/features/trail/presentation/trail_catalog_screen.dart',
        'preparation':
            'lib/features/hub/presentation/widgets/hub_buy_trek_button.dart',
        'depart':
            'lib/features/hub/presentation/widgets/hub_start_trek_button.dart',
      };
      for (final entree in portes.entries) {
        final f = File(entree.value);
        expect(f.existsSync(), isTrue,
            reason: 'le point d achat « ${entree.key} » doit exister : '
                '${entree.value}');
        expect(f.readAsStringSync(), contains('acheterSentier('),
            reason: 'l achat depuis « ${entree.key} » doit emprunter le geste '
                'unique, pas un chemin de paiement a lui');
      }
    });

    test('la preparation du cockpit POSE reellement son bouton', () {
      // Un widget qui existe sans etre monte est un bouton que personne ne peut
      // atteindre — c est exactement le defaut que cette tache repare pour la
      // video. On ne le reproduit pas pour l achat.
      final cockpit =
          File('lib/features/hub/presentation/hub_screen.dart').readAsStringSync();
      expect(cockpit, contains('HubBuyTrekButton('),
          reason: 'le bouton d achat de la preparation doit etre POSE dans le '
              'cockpit, pas seulement ecrit');
    });
  });

  // =========================================================================
  // A2 — L ACHAT DEPUIS LE CATALOGUE
  // =========================================================================
  group('A2 — acheter depuis le catalogue', () {
    testWidgets('la carte d un sentier PAYANT porte un bouton d achat qui ouvre '
        'la vitrine', (tester) async {
      fenetreHaute(tester);
      final monetisation = await service();
      await tester.pumpWidget(
        monterEcran(monetisation, const TrailCatalogScreen()),
      );
      await tester.pumpAndSettle();

      final bouton = find.byKey(ValueKey('catalog-buy-${_sentierPayant.id}'));
      expect(bouton, findsOneWidget,
          reason: 'le randonneur qui DECOUVRE un sentier doit pouvoir l acheter '
              'sans entrer dedans, preparer trois cartes et rencontrer un refus');

      await tester.tap(bouton);
      await tester.pumpAndSettle();
      expect(find.byType(PaywallSheet), findsOneWidget,
          reason: 'le bouton doit ouvrir LA vitrine — la meme que partout');
    });

    testWidgets('AUCUN bouton d achat sur un sentier GRATUIT', (tester) async {
      fenetreHaute(tester);
      final monetisation = await service();
      await tester.pumpWidget(
        monterEcran(monetisation, const TrailCatalogScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(ValueKey('catalog-buy-${_sentierGratuit.id}')),
          findsNothing,
          reason: 'un sentier gratuit n a rien a vendre : proposer de le '
              'debloquer est un bouton qui ment');
      // Et il reste bien au catalogue, avec son entree normale.
      expect(find.byKey(ValueKey('catalog-enter-${_sentierGratuit.id}')),
          findsOneWidget);
    });

    testWidgets('le bouton DISPARAIT du catalogue une fois le sentier achete',
        (tester) async {
      fenetreHaute(tester);
      final monetisation = await service();
      await tester.pumpWidget(
        monterEcran(monetisation, const TrailCatalogScreen()),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(ValueKey('catalog-buy-${_sentierPayant.id}')),
          findsOneWidget);

      // L achat s ecrit en base. AUCUNE invalidation ici : si la carte se
      // repeint, c est que la condition est branchee sur cette ecriture.
      await marquerAchete(_sentierPayant.id);
      await tester.pumpAndSettle();

      expect(find.byKey(ValueKey('catalog-buy-${_sentierPayant.id}')),
          findsNothing,
          reason: 'vendre deux fois la meme chose au meme randonneur');
    });
  });

  // =========================================================================
  // A3 — L ACHAT DEPUIS LA PREPARATION
  // =========================================================================
  group('A3 — acheter depuis la preparation', () {
    testWidgets('le cockpit de preparation porte un bouton d achat qui ouvre '
        'la vitrine', (tester) async {
      final monetisation = await service();
      await tester.pumpWidget(
        monterEcran(
          monetisation,
          Scaffold(body: HubBuyTrekButton(trailId: _sentierPayant.id)),
        ),
      );
      await tester.pumpAndSettle();

      final bouton = find.byKey(const Key('hub-buy-trek-button'));
      expect(bouton, findsOneWidget,
          reason: 'celui qui prepare depuis trois semaines et se decide un soir '
              'n avait AUCUN bouton : « Démarrer » est grise tant que les trois '
              'cartes coeur ne sont pas faites');

      await tester.tap(bouton);
      await tester.pumpAndSettle();
      expect(find.byType(PaywallSheet), findsOneWidget);
    });

    testWidgets('il affiche le PRIX du service, pas une formule a lui',
        (tester) async {
      final monetisation = await service();
      await tester.pumpWidget(
        monterEcran(
          monetisation,
          Scaffold(body: HubBuyTrekButton(trailId: _sentierPayant.id)),
        ),
      );
      await tester.pumpAndSettle();

      final attendu = monetisation
          .eurPriceForSteps(
            monetisation.stepPriceForTrail(
              totalStages: _sentierPayant.totalStages,
            ),
          )
          .toStringAsFixed(2);
      expect(
        find.text(t.monetization.buyCtaWithPrice(price: attendu)),
        findsOneWidget,
        reason: 'un second calcul de prix dans un ecran est la meme faute que '
            'un second chemin d achat, sur le montant',
      );
    });

    testWidgets('il s efface quand le sentier est ACHETE', (tester) async {
      final monetisation = await service();
      await marquerAchete(_sentierPayant.id);
      await tester.pumpWidget(
        monterEcran(
          monetisation,
          Scaffold(body: HubBuyTrekButton(trailId: _sentierPayant.id)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('hub-buy-trek-button')), findsNothing);
    });

    testWidgets('il s efface aussi sur un sentier GRATUIT', (tester) async {
      final monetisation = await service();
      await tester.pumpWidget(
        monterEcran(
          monetisation,
          Scaffold(body: HubBuyTrekButton(trailId: _sentierGratuit.id)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('hub-buy-trek-button')), findsNothing,
          reason: 'rien a debloquer sur un sentier dont le prix est nul');
    });
  });

  // =========================================================================
  // V1 — LE BOUTON « UN JOUR SANS PUBLICITE » EST SUR LA BANNIERE
  // =========================================================================
  group('V1 — l entree du sans-pub 24 h existe enfin', () {
    Widget monterBanniere(
      MonetizationService monetisation,
      String trailId, {
      bool pubAutorisee = true,
    }) {
      return UncontrolledProviderScope(
        container: conteneur(monetisation, pubAutorisee: pubAutorisee),
        child: TranslationProvider(
          child: MaterialApp(
            home: Scaffold(bottomNavigationBar: BannerAdSlot(trailId: trailId)),
          ),
        ),
      );
    }

    testWidgets('la banniere affichee PORTE le bouton', (tester) async {
      final monetisation = await service();
      await tester.pumpWidget(monterBanniere(monetisation, _sentierPayant.id));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('banniere-simulee')), findsOneWidget,
          reason: 'la publicite est bien affichee dans ce monde');
      expect(find.byKey(const Key('rewarded-no-ads-button')), findsOneWidget,
          reason: 'le moteur de la recompense existait en ENTIER et il n y '
              'avait nulle part ou appuyer : zero bouton dans banner_ad_slot');
    });

    testWidgets('AUCUN bouton quand le sans-pub est DEJA actif (recompense en '
        'cours)', (tester) async {
      final monetisation = await service();
      await monetisation.grantRewardNoAds();
      await tester.pumpWidget(monterBanniere(monetisation, _sentierPayant.id));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('rewarded-no-ads-button')), findsNothing,
          reason: 'un bouton qui propose ce qu on a deja est un bouton qui '
              'ment — et il ne peut pas apparaitre, puisqu il vit sur la '
              'banniere qui n existe alors pas');
      expect(find.byKey(const ValueKey('banniere-simulee')), findsNothing);
      expect(regie.demandes, isEmpty,
          reason: 'sans-pub veut dire qu on ne CHARGE pas, pas qu on cache');
    });

    testWidgets('AUCUN bouton sur un trek ACHETE', (tester) async {
      final monetisation = await service();
      await marquerAchete(_sentierPayant.id);
      await tester.pumpWidget(monterBanniere(monetisation, _sentierPayant.id));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('rewarded-no-ads-button')), findsNothing);
    });

    testWidgets('AUCUN bouton pour un ABONNE actif', (tester) async {
      final monetisation = await service();
      await monetisation.onSubscriptionValidated();
      await tester.pumpWidget(monterBanniere(monetisation, _sentierPayant.id));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('rewarded-no-ads-button')), findsNothing,
          reason: 'l abonne est sans pub PARTOUT : rien a lui proposer');
    });

    testWidgets('AUCUN bouton quand la publicite n est meme pas disponible',
        (tester) async {
      final monetisation = await service();
      await tester.pumpWidget(
        monterBanniere(monetisation, _sentierPayant.id, pubAutorisee: false),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('rewarded-no-ads-button')), findsNothing,
          reason: 'sans consentement ni SDK, la video n existe pas : un bouton '
              'qui la promet est un bouton mort');
    });

    test('le bouton est le MEME que celui de la vitrine, pas une copie', () {
      // IL VIVAIT EN WIDGET PRIVE DANS LA VITRINE, donc utilisable nulle part
      // ailleurs. Deux boutons auraient voulu dire deux libelles et deux
      // mecaniques a maintenir.
      final vitrine =
          File('lib/shared/widgets/paywall_sheet.dart').readAsStringSync();
      expect(vitrine, contains('RewardedNoAdsButton()'),
          reason: 'la vitrine doit poser le bouton PARTAGE');
      expect(vitrine, isNot(contains('class _RewardedNoAdsButton')),
          reason: 'le bouton prive doit avoir quitte la vitrine, pas y rester '
              'en double');
      final emplacement =
          File('lib/features/ads/presentation/banner_ad_slot.dart')
              .readAsStringSync();
      expect(emplacement, contains('RewardedNoAdsButton('),
          reason: 'la banniere doit poser LE MEME bouton');
    });
  });

  // =========================================================================
  // V2 — LE LIBELLE DIT CE QU ON OBTIENT, PAS CE QU ON FAIT
  // =========================================================================
  group('V2 — le libelle, dans les cinq langues', () {
    // ARBITRAGE DE PRODUIT : « un jour sans publicite » d abord, « regarder une
    // video » ensuite. C est la contrepartie qui decide d appuyer, pas le geste.
    // L ancien libelle disait l inverse (« Regarder une pub (sans pub 24 h) »).
    const attendu = <AppLocale, (String, String)>{
      AppLocale.fr: ('jour sans publicité', 'vidéo'),
      AppLocale.en: ('day without ads', 'video'),
      AppLocale.es: ('día sin anuncios', 'vídeo'),
      AppLocale.de: ('Tag ohne Werbung', 'Video'),
      AppLocale.it: ('giorno senza pubblicità', 'video'),
    };

    for (final entree in attendu.entries) {
      test('${entree.key.languageCode} : le gain avant le geste', () {
        final libelle =
            entree.key.buildSync().monetization.rewardedCta;
        final (gain, geste) = entree.value;
        expect(libelle, contains(gain));
        expect(libelle, contains(geste));
        expect(libelle.indexOf(gain), lessThan(libelle.indexOf(geste)),
            reason: 'le libelle doit dire ce qu on OBTIENT avant ce qu on '
                'fait : « $libelle »');
      });
    }
  });

  // =========================================================================
  // V3 — L OCTROI DURE BIEN 24 H, ET PAS UNE MINUTE DE PLUS
  // =========================================================================
  group('V3 — vingt-quatre heures, jamais a vie', () {
    test('la recompense est active tout de suite, et 23 h 59 plus tard',
        () async {
      final monetisation = await service();
      await monetisation.grantRewardNoAds();

      expect(await monetisation.isRewardNoAdsActive(), isTrue);
      maintenant = maintenant.add(const Duration(hours: 23, minutes: 59));
      expect(await monetisation.isRewardNoAdsActive(), isTrue,
          reason: 'la contrepartie de la video couvre la journee entiere');
    });

    test('elle ne vaut PLUS rien 24 h 01 plus tard', () async {
      final monetisation = await service();
      await monetisation.grantRewardNoAds();

      maintenant = maintenant.add(const Duration(hours: 24, minutes: 1));
      expect(await monetisation.isRewardNoAdsActive(), isFalse,
          reason: 'la regle d or #99404 interdit le sans-pub A VIE : une video '
              'ne peut pas eteindre la publicite pour toujours');
      expect(await monetisation.isNoAdsActive(_sentierPayant.id), isFalse,
          reason: 'et la source unique doit le dire aussi');
    });
  });
}
