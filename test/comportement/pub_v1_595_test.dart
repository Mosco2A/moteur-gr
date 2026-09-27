// LA PUBLICITE DE LA V1 (tache 595, GO-66) — CE QUE CE TEST EXIGE.
//
// LE POINT DE DEPART EST BRUTAL ET IL A ETE COMPTE : la banniere n'existait
// pas. Pas « en mode test » — INEXISTANTE. Zero `BannerAd`, zero `AdWidget`
// dans tout `lib/`. Ce qui existait, c'est la logique qui decide QUAND
// l'afficher (`shouldShowBannerProvider`), et elle etait meme testee
// (`ads_gating_test.dart`) : une decision parfaitement rendue, que personne
// n'executait. Un gating sans banniere, c'est un interrupteur sans ampoule.
//
// CE TEST EST ECRIT AVANT LA BANNIERE, ET IL EST ROUGE A L'ECRITURE. Il ne
// verifie pas qu'une classe se compile : il verifie CE QUE VOIT LE RANDONNEUR,
// et surtout ce qu'il NE VOIT PAS.
//
// LES SIX CHOSES QU'IL TIENT :
//
//  B1 — LA BANNIERE S'AFFICHE. Un trek libre, la pub consentie : quelque chose
//       apparait, avec une hauteur reelle. C'est la seule facon de distinguer
//       « branche » de « cable dans le vide ».
//
//  B2 — LA REGLE D'OR #99404 COMMANDE CET AFFICHAGE, et elle n'a pas
//       d'exception : JAMAIS de sans-pub a vie, TOUJOURS lie a un etat ACTIF.
//       Abonne actif, trek achete, recompense de 24 h — trois etats, trois
//       silences. Et la separation qui fait tout le modele : les CREDITS sont
//       acquis a vie, ils n'achetent PAS le sans-pub. Un portefeuille plein sur
//       un trek non achete, c'est de la publicite.
//       Le test ne se contente pas de « rien a l'ecran » : il compte les
//       DEMANDES faites a la regie. Sans-pub veut dire qu'on ne CHARGE pas —
//       pas qu'on charge et qu'on cache.
//
//  B3 — LES IDENTIFIANTS NE SONT PLUS ECRITS EN DUR. L'App ID de TEST public
//       de Google vivait en clair dans `AndroidManifest.xml`, et il n'etait pas
//       injectable — contrairement aux emplacements publicitaires, eux
//       proprement prevus. iOS n'avait RIEN, alors que le SDK EXIGE la cle. Ce
//       groupe verifie la MECANIQUE d'injection, jamais une valeur de
//       production : aucune cle reelle n'entre dans ce depot.
//
//  B4 — LE CONSENTEMENT PUBLICITAIRE FAIT PARTIE DU DISPOSITIF. Il vivait a
//       cote : l'appli a un consentement granulaire complet, horodate,
//       versionne, avec refus global et effacement de l'article 9 — et la
//       publicite n'en etait pas. Desormais elle est une finalite comme les
//       autres : elle a sa bascule, « Tout refuser » l'emporte, et son refus
//       PRODUIT UN EFFET MESURABLE (la demande part non personnalisee).
//
//  B5 — LE SOS NE PORTE AUCUNE PUBLICITE. C'est aujourd'hui la decision la
//       mieux respectee du modele, et ce test est la pour qu'elle le reste
//       quand quelqu'un, dans six mois, cherchera un emplacement de plus.
//
//  B6 — RETIRE. Il mesurait une regle « EN MODE TREK JAMAIS » qui a vecu une
//       demi-journee : posee le 27/09 au matin, RETIREE par Chris le meme jour
//       a 14:41, verbatim : « TOUT PORTER LA PUB sauf si tu es abonne ou sur le
//       trek que tu as achete .. Pas la peine de mettre plus de regles ». Deux
//       exceptions, plus la recompense de 24 h du modele du 08/09 (#99404) —
//       toutes trois portees par la source unique `isNoAdsActive`, que B2 mesure
//       deja. Ses six tests sont partis avec elle plutot que d'etre retournes :
//       ils affirmaient l'inverse de la regle en vigueur. Le seul cas qu'ils
//       couvraient vraiment — marcher sans avoir paye — n'existe plus que sur un
//       sentier GRATUIT, et B7 le mesure en le disant.
library;

import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moteur_gr/core/config/ad_config.dart';
import 'package:moteur_gr/core/config/feature_flags.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/network/connectivity_monitor.dart';
import 'package:moteur_gr/core/providers/database_provider.dart';
import 'package:moteur_gr/core/providers/service_providers.dart';
import 'package:moteur_gr/core/services/consent_service.dart';
import 'package:moteur_gr/core/services/monetization_service.dart';
import 'package:moteur_gr/core/services/wallet_iap_service.dart';
import 'package:moteur_gr/core/services/wallet_store.dart';
import 'package:moteur_gr/features/ads/data/banner_ad_presenter.dart';
import 'package:moteur_gr/features/ads/presentation/banner_ad_slot.dart';
import 'package:moteur_gr/features/ads/providers/ads_providers.dart';
import 'package:moteur_gr/features/after/providers/adventure_recap_provider.dart'
    show latestTrekSessionProvider;
import 'package:moteur_gr/features/consent/presentation/consent_settings_screen.dart';
import 'package:moteur_gr/features/trek/domain/models/trek_session.dart';
import 'package:moteur_gr/features/trek/providers/tracking_providers.dart';
import 'package:moteur_gr/i18n/translations.g.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Regie de publicite SIMULEE : elle ne contacte rien, et elle COMPTE.
///
/// Le comptage est le coeur de B2. « Pas de banniere a l'ecran » se truque
/// avec un widget invisible ; « aucune demande partie a la regie » ne se truque
/// pas. La difference n'est pas theorique : une pub chargee puis cachee a ete
/// demandee, donc payee en donnees et en batterie, et l'identifiant de
/// l'appareil est parti chez Google. Un trek achete doit ETRE sans pub, pas
/// SEMBLER sans pub.
class _RegieSimulee implements BannerAdPresenter {
  _RegieSimulee({this.echoue = false});

  /// Simule une regie qui ne rend aucune banniere (reseau, remplissage vide).
  final bool echoue;

  /// Les demandes REELLEMENT parties, dans l'ordre.
  final List<BannerAdRequest> demandes = <BannerAdRequest>[];

  /// Les bannieres liberees (une par `dispose` appele).
  int liberations = 0;

  @override
  Future<LoadedBanner?> load(BannerAdRequest request) async {
    demandes.add(request);
    if (echoue) return null;
    return LoadedBanner(
      view: const SizedBox(key: ValueKey('banniere-simulee')),
      height: 50,
      dispose: () async => liberations++,
    );
  }
}

class _ReseauEnLigne extends ConnectivityMonitor {
  @override
  Future<ConnectivityStatus> checkStatus() async =>
      ConnectivityStatusValues.online;
}

/// Session de tracking FIGEE dans un etat donne (rando en cours, ou pas).
///
/// Sert a mettre le monde du test « en mode trek » par le chemin de la session
/// VIVANTE, sans faire tourner de GPS.
class _TrackingFige extends TrekSessionManagerNotifier {
  _TrackingFige(this._etat);

  final TrackingSessionState _etat;

  @override
  TrackingSessionState build() => _etat;
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
    maintenant = DateTime(2026, 9, 26, 20);
    regie = _RegieSimulee();
  });

  tearDown(() async {
    FeatureFlags.clearOverrides();
    await db.close();
  });

  /// Monte le monde minimal : monetisation reelle (sur base memoire), regie
  /// simulee, consentement publicitaire pilote.
  ///
  /// `pubAutorisee` = ce que rend le CMP (UMP) ; `pubPersonnalisee` = la
  /// finalite locale du dispositif de consentement. Les deux sont distincts,
  /// et c'est voulu : le premier dit si l'on a le DROIT de demander une pub,
  /// le second ce que la demande a le droit d'emporter.
  ///
  /// `tracking` et `sessionPersistee` sont les DEUX chemins par lesquels
  /// l'application se sait « en mode trek » (session vivante en memoire,
  /// session encore ouverte en base apres un redemarrage). Par defaut : aucune
  /// rando en cours.
  Future<(ProviderContainer, MonetizationService)> monterLeMonde({
    bool pubAutorisee = true,
    bool? pubPersonnalisee,
    TrackingSessionStatus tracking = TrackingSessionStatus.idle,
    TrekSession? sessionPersistee,
    Set<String> sentiersGratuits = const <String>{},
  }) async {
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
      freeTrailIds: sentiersGratuits,
    );
    await monetisation.load();

    final consentement = ConsentService(prefs: prefs);
    await consentement.initialize();
    if (pubPersonnalisee != null) {
      if (pubPersonnalisee) {
        await consentement.grant(ConsentPurpose.advertising);
      } else {
        await consentement.revoke(ConsentPurpose.advertising);
      }
    }

    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        monetizationServiceProvider.overrideWithValue(monetisation),
        monetizationReadyProvider.overrideWith((ref) async => monetisation),
        adsReadyProvider.overrideWith((ref) async => pubAutorisee),
        bannerAdPresenterProvider.overrideWithValue(regie),
        consentServiceReadyProvider.overrideWith((ref) async => consentement),
        // Les DEUX chemins du « mode trek » (cf. l'en-tete de cette fonction).
        trekSessionManagerProvider.overrideWith(
          () => _TrackingFige(TrackingSessionState(status: tracking)),
        ),
        latestTrekSessionProvider.overrideWith((ref) async => sessionPersistee),
      ],
    );
    addTearDown(container.dispose);
    // LA BASE A PARLE AVANT QU'ON DEMANDE QUOI QUE CE SOIT. La decision
    // publicitaire repond « en rando » tant que la session persistee est
    // inconnue (doute tranche du cote du randonneur, cf. `enModeTrekProvider`).
    // Un test qui ne laisserait pas cette lecture aboutir mesurerait donc la
    // fenetre d'amorce et non la regle qu'il croit verifier. Cette fenetre a son
    // propre test, dans B6.
    await container.read(latestTrekSessionProvider.future);
    return (container, monetisation);
  }

  // =========================================================================
  // B1 — LA BANNIERE EXISTE, ET ELLE S'AFFICHE
  // =========================================================================
  group('B1 — la banniere qui n existait pas', () {
    test('un trek libre, la pub consentie : une banniere est DEMANDEE et rendue',
        () async {
      final (c, _) = await monterLeMonde();
      final banniere = await c.read(bannerAdProvider('gr20').future);

      expect(banniere, isNotNull,
          reason: 'la decision d afficher etait deja prise et testee ; ce qui '
              'manquait, c est la chose qui s affiche');
      expect(banniere!.height, greaterThan(0),
          reason: 'une banniere de hauteur nulle n est pas une banniere');
      expect(regie.demandes, hasLength(1));
      expect(regie.demandes.single.unitId, isNotEmpty,
          reason: 'la demande doit porter un emplacement publicitaire');
    });

    testWidgets('l emplacement POSE dans un ecran affiche la banniere',
        (tester) async {
      final (c, _) = await monterLeMonde();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: const MaterialApp(
            home: Scaffold(
              bottomNavigationBar: BannerAdSlot(trailId: 'gr20'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('banniere-simulee')), findsOneWidget);
    });

    testWidgets('une regie qui ne rend rien ne casse RIEN (zero hauteur)',
        (tester) async {
      regie = _RegieSimulee(echoue: true);
      final (c, _) = await monterLeMonde();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: const MaterialApp(
            home: Scaffold(
              bottomNavigationBar: BannerAdSlot(trailId: 'gr20'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byType(BannerAdSlot)).height,
        0,
        reason: 'pas de pub disponible ne doit pas reserver un trou blanc au '
            'bas de l ecran',
      );
    });
  });

  // =========================================================================
  // B2 — LA REGLE D'OR #99404 : JAMAIS A VIE, TOUJOURS LIEE A UN ETAT ACTIF
  // =========================================================================
  group('B2 — la regle d or commande l affichage', () {
    test('ABONNE ACTIF : sans pub PARTOUT, et rien n est meme demande',
        () async {
      final (c, monetisation) = await monterLeMonde();
      await monetisation.onSubscriptionValidated();

      expect(await c.read(bannerAdProvider('gr20').future), isNull);
      expect(await c.read(bannerAdProvider('mare-a-mare').future), isNull,
          reason: 'l abonnement couvre TOUS les treks, pas celui-la seulement');
      expect(regie.demandes, isEmpty,
          reason: 'un abonne ne doit generer AUCUNE demande a la regie — une '
              'pub chargee puis cachee reste une pub demandee');
    });

    test('TREK ACHETE : sans pub sur CE trek, avec pub sur les autres',
        () async {
      final (c, _) = await monterLeMonde();
      await db.trekEntitlementsDao.upsert(
        TrekEntitlementsCompanion.insert(
          trailId: 'gr20',
          owned: const Value(true),
          updatedAt: maintenant,
        ),
      );

      expect(await c.read(bannerAdProvider('gr20').future), isNull);
      expect(await c.read(bannerAdProvider('mare-a-mare').future), isNotNull,
          reason: 'acheter UN trek n achete pas le silence sur les autres');
    });

    test('RECOMPENSE VIDEO : 24 h de silence, puis la pub revient', () async {
      final (c, monetisation) = await monterLeMonde();
      await monetisation.grantRewardNoAds();

      expect(await c.read(bannerAdProvider('gr20').future), isNull,
          reason: 'la recompense vient d etre accordee');

      // 24 h plus tard, a la minute pres : l echeance est passee.
      //
      // UNE DATE QUI PASSE N'EMET AUCUN EVENEMENT — aucune base ne previent
      // qu'une echeance est arrivee. La decision est donc re-prise au montage
      // suivant d'un emplacement (`shouldShowBannerProvider` est autoDispose),
      // et c'est ce que simule cette invalidation. Sans cela, la recompense de
      // 24 h vaudrait sans-pub pour toute la duree du processus : exactement le
      // « sans-pub a vie » que la regle d or interdit.
      maintenant = maintenant.add(const Duration(hours: 24, minutes: 1));
      c.invalidate(shouldShowBannerProvider);
      expect(await c.read(bannerAdProvider('gr20').future), isNotNull,
          reason: 'le sans-pub de la recompense est TEMPORAIRE — jamais a vie');
    });

    test('LES CREDITS NE SONT PAS LE SANS-PUB : portefeuille plein, pub quand '
        'meme', () async {
      final (c, _) = await monterLeMonde();
      await portefeuille.credit(50);

      expect(await c.read(bannerAdProvider('gr20').future), isNotNull,
          reason: 'les credits sont acquis A VIE et SEPARES du sans-pub : ils '
              'donnent le droit de realiser, pas celui de ne plus voir de pub');
    });

    testWidgets('ACHETER PENDANT L AFFICHAGE fait DISPARAITRE la banniere, et '
        'LIBERE la pub chargee', (tester) async {
      final (c, _) = await monterLeMonde();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: const MaterialApp(
            home: Scaffold(
              bottomNavigationBar: BannerAdSlot(trailId: 'gr20'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('banniere-simulee')), findsOneWidget);

      // Le randonneur achete le trek pendant que la banniere est a l'ecran.
      // AUCUNE INVALIDATION ICI, ET C'EST TOUT LE TEST : la seule chose qui se
      // produit est l'ecriture du droit en base. Si la banniere s'eteint, c'est
      // que la decision est branchee sur cette ecriture — pas qu'un test l'a
      // gentiment poussee.
      await db.trekEntitlementsDao.upsert(
        TrekEntitlementsCompanion.insert(
          trailId: 'gr20',
          owned: const Value(true),
          updatedAt: maintenant,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('banniere-simulee')), findsNothing,
          reason: 'le sans-pub est immediat, pas au prochain demarrage');
      expect(regie.liberations, greaterThan(0),
          reason: 'la banniere chargee doit etre LIBEREE, pas seulement '
              'retiree de l arbre — sinon elle continue de vivre, de se '
              'rafraichir et de consommer');
    });

    test('la pub NON consentie (CMP) coupe tout, meme sur un trek libre',
        () async {
      final (c, _) = await monterLeMonde(pubAutorisee: false);
      expect(await c.read(bannerAdProvider('gr20').future), isNull);
      expect(regie.demandes, isEmpty);
    });
  });

  // =========================================================================
  // B3 — LES IDENTIFIANTS : LA MECANIQUE, JAMAIS LA VALEUR
  // =========================================================================
  group('B3 — les identifiants sont injectes, pas ecrits en dur', () {
    /// Identifiants de TEST publics de Google (documentes, libres d'usage).
    /// Ce sont les SEULES valeurs qui ont le droit d'exister dans ce depot.
    const appIdTestGoogle = 'ca-app-pub-3940256099942544~3347511713';
    const editeurTestGoogle = 'ca-app-pub-3940256099942544';

    File fichier(String chemin) {
      final f = File(chemin);
      expect(f.existsSync(), isTrue, reason: '$chemin doit exister');
      return f;
    }

    test('ANDROID : le manifeste porte un PLACEHOLDER, plus une valeur', () {
      final manifeste =
          fichier('android/app/src/main/AndroidManifest.xml').readAsStringSync();

      expect(
        manifeste,
        contains(r'${admobAppId}'),
        reason: 'l App ID doit venir du build, pas du manifeste',
      );
      expect(
        manifeste.contains(appIdTestGoogle),
        isFalse,
        reason: 'aucune valeur d App ID ne doit plus etre figee dans le '
            'manifeste — c etait le defaut mesure : non injectable',
      );
    });

    test('ANDROID : le build DEFINIT le placeholder et le lit de l exterieur',
        () {
      final gradle = fichier('android/app/build.gradle.kts').readAsStringSync();

      expect(gradle, contains('manifestPlaceholders'),
          reason: 'il n y en avait AUCUN — c est ce qui manquait');
      expect(gradle, contains('admobAppId'));
      expect(gradle, contains('ADMOB_APP_ID_ANDROID'),
          reason: 'le nom du canal d injection doit etre explicite');
      expect(gradle, contains('System.getenv'),
          reason: 'une valeur de production arrive par l environnement de '
              'build ou une propriete gradle — jamais par un fichier versionne');
      expect(gradle, contains(appIdTestGoogle),
          reason: 'le DEFAUT reste l App ID de TEST public de Google : un '
              'build sans injection doit rester fonctionnel et inoffensif');
    });

    test('IOS : la cle EXIGEE par le SDK existe, et elle est injectee', () {
      final plist = fichier('ios/Runner/Info.plist').readAsStringSync();

      expect(plist, contains('GADApplicationIdentifier'),
          reason: 'le SDK AdMob EXIGE cette cle ; elle etait absente — l appli '
              'iOS ne pouvait pas demarrer le SDK');
      expect(plist, contains(r'$(ADMOB_APP_ID_IOS)'),
          reason: 'la valeur vient d un reglage de build, pas du plist');
      expect(plist, contains('SKAdNetworkItems'),
          reason: 'Apple exige la liste d attribution des reseaux publicitaires');
      expect(plist, contains('NSUserTrackingUsageDescription'),
          reason: 'Apple exige le texte de suivi publicitaire ; sans lui, le '
              'SDK ne peut rien demander et l app est refusee en revue');
    });

    test('IOS : le reglage de build a un defaut de TEST, jamais une cle reelle',
        () {
      final debug = fichier('ios/Flutter/Debug.xcconfig').readAsStringSync();
      final release = fichier('ios/Flutter/Release.xcconfig').readAsStringSync();

      for (final (nom, contenu) in [('Debug', debug), ('Release', release)]) {
        expect(contenu, contains('ADMOB_APP_ID_IOS'),
            reason: '$nom doit definir le reglage injecte');
        expect(contenu, contains(editeurTestGoogle),
            reason: '$nom doit retomber sur l identifiant de TEST de Google');
      }
    });

    test('AUCUNE CLE DE PRODUCTION n est ecrite en clair dans le depot', () {
      // Tout identifiant AdMob commence par `ca-app-pub-`. Le SEUL compte
      // autorise dans ce depot est le compte de TEST public de Google. Ce test
      // est la garde qui empechera, un jour de hate, qu une vraie cle soit
      // collee « juste pour essayer ».
      final aFouiller = <File>[
        File('android/app/src/main/AndroidManifest.xml'),
        File('android/app/build.gradle.kts'),
        File('ios/Runner/Info.plist'),
        File('ios/Flutter/Debug.xcconfig'),
        File('ios/Flutter/Release.xcconfig'),
        File('lib/core/config/ad_config.dart'),
      ];
      final motif = RegExp(r'ca-app-pub-\d+');
      final fautives = <String>[];
      for (final f in aFouiller) {
        if (!f.existsSync()) continue;
        for (final trouve in motif.allMatches(f.readAsStringSync())) {
          if (trouve.group(0) != editeurTestGoogle) {
            fautives.add('${f.path} : ${trouve.group(0)}');
          }
        }
      }
      expect(fautives, isEmpty,
          reason: 'UNE CLE ADMOB REELLE EST ECRITE EN CLAIR DANS LE DEPOT. '
              'Les valeurs de production s injectent au build '
              '(ADMOB_APP_ID_ANDROID / ADMOB_APP_ID_IOS / --dart-define) et '
              'ne sont JAMAIS versionnees.\n  ${fautives.join('\n  ')}');
    });

    test('les emplacements publicitaires restent injectables (deja acquis)',
        () {
      // Ce point-la etait DEJA propre avant la tache : on le verrouille pour
      // qu il le reste, sans se l attribuer.
      expect(AdConfig.bannerUnitId(), isNotEmpty);
      expect(AdConfig.rewardedUnitId(), isNotEmpty);
      expect(AdConfig.hasProductionUnits, isFalse,
          reason: 'un build de test ne porte aucun emplacement de production');
    });
  });

  // =========================================================================
  // B4 — LE CONSENTEMENT PUBLICITAIRE FAIT PARTIE DU DISPOSITIF
  // =========================================================================
  group('B4 — la publicite entre dans le consentement de l appli', () {
    test('la publicite est une finalite du dispositif, comme les autres', () {
      expect(ConsentPurpose.values, contains(ConsentPurpose.advertising),
          reason: 'elle vivait a cote du dispositif ; elle en fait partie');
      expect(ConsentPurpose.advertising.isReinforced, isFalse,
          reason: 'la publicite n est pas une donnee de l article 9 — seule la '
              'sante l est, et son isolement ne doit pas etre dilue');
      expect(ConsentPurpose.advertising.storageKey, 'consent_advertising');
    });

    test('« TOUT REFUSER » emporte AUSSI la publicite', () async {
      final prefs = await SharedPreferences.getInstance();
      final service = ConsentService(prefs: prefs);
      await service.initialize();
      await service.grant(ConsentPurpose.advertising);
      expect(service.hasConsent(ConsentPurpose.advertising), isTrue);

      // Le refus global parcourt ConsentPurpose.values : la publicite y est
      // desormais, donc elle tombe avec le reste. C'est tout l interet de la
      // faire entrer dans l enum plutot que de lui bricoler un interrupteur.
      for (final p in ConsentPurpose.values) {
        await service.revoke(p);
      }
      expect(service.hasConsent(ConsentPurpose.advertising), isFalse);
      expect(service.stateOf(ConsentPurpose.advertising).decidedAt, isNotNull,
          reason: 'un refus est une DECISION horodatee, pas un silence');
    });

    test('REFUSER produit un effet MESURABLE : la demande part NON '
        'personnalisee', () async {
      final (c, _) = await monterLeMonde(pubPersonnalisee: false);
      await c.read(bannerAdProvider('gr20').future);

      expect(regie.demandes, hasLength(1));
      expect(regie.demandes.single.personalized, isFalse,
          reason: 'refuser la publicite personnalisee doit changer CE QUI PART '
              'de l appareil. Un interrupteur qui ne change rien est un '
              'mensonge poli.');
    });

    test('ACCORDER laisse la demande personnalisee', () async {
      final (c, _) = await monterLeMonde(pubPersonnalisee: true);
      await c.read(bannerAdProvider('gr20').future);

      expect(regie.demandes.single.personalized, isTrue);
    });

    test('SANS DECISION, la demande part non personnalisee (ferme par defaut)',
        () async {
      final (c, _) = await monterLeMonde();
      await c.read(bannerAdProvider('gr20').future);

      expect(regie.demandes.single.personalized, isFalse,
          reason: 'le dispositif est en opt-in : rien n est accorde par '
              'defaut. Le modele economique tient quand meme — la publicite '
              'reste affichee, elle est seulement non ciblee.');
    });

    testWidgets('« Options de confidentialite » a UNE PORTE dans l ecran de '
        'consentement', (tester) async {
      // LE DEFAUT MESURE : `showPrivacyOptionsForm()` etait ecrit, teste, et
      // AUCUN geste de l application ne l appelait. C est un ecran de plus que
      // personne ne peut ouvrir — exactement ce que l invariante des portes
      // traque. Sa porte est un bouton sur l ecran de consentement, qui lui a
      // deja la sienne (Reglages). AUCUNE ROUTE NOUVELLE : le formulaire CMP
      // est une vue NATIVE, pas un ecran Flutter — l invariante reste verte.
      final prefs = await SharedPreferences.getInstance();
      final consentement = ConsentService(prefs: prefs);
      await consentement.initialize();

      // Surface haute : l'ecran de consentement est une liste paresseuse, et
      // un bouton hors champ n'y est tout simplement pas construit. On regarde
      // l'ecran en entier, sinon le test mesurerait la taille de la fenetre.
      tester.view.physicalSize = const Size(1000, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            consentServiceReadyProvider.overrideWith((ref) async => consentement),
            adsPrivacyOptionsRequiredProvider.overrideWith((ref) async => true),
          ],
          child: TranslationProvider(
            // L'en-tete universel s'appuie sur GoRouter : routeur minimal.
            child: MaterialApp.router(
              routerConfig: GoRouter(
                initialLocation: '/consent',
                routes: [
                  GoRoute(
                    path: '/consent',
                    builder: (_, __) => const ConsentSettingsScreen(),
                  ),
                  GoRoute(
                    path: '/my-treks',
                    builder: (_, __) => const SizedBox(),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('consent-ads-privacy-options')),
        findsOneWidget,
        reason: 'le point d entree des options de confidentialite pub doit '
            'etre atteignable par un doigt',
      );
      expect(
        find.byKey(const ValueKey('consent-toggle-advertising')),
        findsOneWidget,
        reason: 'la publicite doit avoir sa bascule sur le MEME ecran que les '
            'autres finalites — c est ca, « en faire partie »',
      );
    });
  });

  // =========================================================================
  // B5 — LE SOS NE PORTE AUCUNE PUBLICITE, NULLE PART, JAMAIS
  // =========================================================================
  group('B5 — la limite qui ne se discute pas', () {
    /// Tout le chemin du secours : le bouton, sa confirmation, l ecran
    /// d urgence, la fiche medicale et le signalement terrain.
    const cheminDuSecours = <String>[
      'lib/features/safety/presentation/sos_button.dart',
      'lib/features/safety/presentation/sos_confirmation_dialog.dart',
      'lib/features/safety/presentation/emergency_screen.dart',
      'lib/features/safety/presentation/health_info_screen.dart',
      'lib/features/safety/presentation/signalement_screen.dart',
    ];

    test('AUCUN ecran du chemin du secours ne porte de publicite', () {
      final fautifs = <String>[];
      for (final chemin in cheminDuSecours) {
        final f = File(chemin);
        expect(f.existsSync(), isTrue, reason: '$chemin doit exister');
        final source = f.readAsStringSync();
        for (final interdit in const [
          'BannerAdSlot',
          'AdWidget',
          'BannerAd(',
          'bannerAdProvider',
          'showPaywallSheet',
        ]) {
          if (source.contains(interdit)) fautifs.add('$chemin : $interdit');
        }
      }
      expect(fautifs, isEmpty,
          reason: 'AUCUNE monetisation sur le chemin du secours. Ni pub, ni '
              'paywall, jamais, nulle part. C est la decision la mieux '
              'respectee du modele et elle le reste.\n  '
              '${fautifs.join('\n  ')}');
    });

    test('la publicite ne s invite pas non plus dans le repertoire safety', () {
      final fautifs = <String>[];
      final racine = Directory('lib/features/safety');
      for (final e in racine.listSync(recursive: true)) {
        if (e is! File || !e.path.endsWith('.dart')) continue;
        final source = e.readAsStringSync();
        if (source.contains('features/ads/') ||
            source.contains('google_mobile_ads')) {
          fautifs.add(e.path);
        }
      }
      expect(fautifs, isEmpty,
          reason: 'le module du secours ne doit meme pas CONNAITRE le module '
              'publicitaire.\n  ${fautifs.join('\n  ')}');
    });
  });

  // =========================================================================
  // B7 — LA PUBLICITE SUR UN SENTIER GRATUIT (tache 601)
  // =========================================================================
  group('B7 — un sentier GRATUIT, la pub, et le mode trek', () {
    // L'ARBITRAGE, ET SA RAISON. Le sentier de demonstration de StepWays est
    // desormais un SENTIER GRATUIT du catalogue, entierement jouable. La question
    // qu'il pose est neuve : etant gratuit, est-il avec ou sans publicite ?
    //
    // CE QUE DIT LE MODELE, ET CHRIS L'A RESIMPLIFIE LE 27/09 A 14:41, verbatim :
    // « TOUT PORTER LA PUB sauf si tu es abonne ou sur le trek que tu as achete
    // .. Pas la peine de mettre plus de regles ». Deux exceptions, plus la
    // recompense video de 24 h de son modele du 08/09 (#99404). Le sans-pub est
    // donc la contrepartie d'avoir PAYE, et rien d'autre. Un sentier gratuit n'a
    // aucun de ces trois etats : il porte la pub.
    //
    // ET CE QUE COUTERAIT L'INVERSE. Un sentier de demonstration sans publicite
    // offrirait GRATUITEMENT le benefice principal de l'abonnement a 2 euros —
    // « pub nulle part ». La demonstration cesserait de demontrer le produit
    // payant pour le concurrencer. C'est exactement ce que faisait le drapeau
    // vitrine, qui resolvait le sentier en « possede ».
    //
    // ET EN MARCHANT ? LA PUB AUSSI, ET C'EST ASSUME. Une garde « en mode trek
    // jamais » a existe une demi-journee dans la decision ; Chris l'a retiree
    // avec la phrase ci-dessus, apres qu'on lui ait montre ce cas precis. Sur un
    // sentier PAYANT la question ne se pose pas — on ne le realise qu'en l'ayant
    // achete, donc il est deja sans pub. Le sentier GRATUIT est le seul endroit
    // ou l'on marche sans avoir paye, donc le seul ou la banniere peut
    // apparaitre pendant la realisation. Le test ci-dessous le DIT, pour que
    // personne ne le prenne pour un oubli et ne remette une garde.
    const gratuit = 'sentier-gratuit';

    test('hors mode trek : le sentier gratuit est AVEC pub', () async {
      final (c, _) = await monterLeMonde(sentiersGratuits: {gratuit});

      expect(await c.read(bannerAdProvider(gratuit).future), isNotNull,
          reason: 'gratuit = avec pub (modele eco section 2). Le sans-pub se '
              'paie : sentier achete, abonnement actif, ou recompense video');
      expect(regie.demandes, hasLength(1),
          reason: 'la demande part REELLEMENT a la regie — on ne mesure pas '
              'des pixels');
    });

    test('EN MARCHANT sur le sentier gratuit : la pub EST la, et c est voulu',
        () async {
      final (c, _) = await monterLeMonde(
        sentiersGratuits: {gratuit},
        tracking: TrackingSessionStatus.recording,
      );

      expect(await c.read(bannerAdProvider(gratuit).future), isNotNull,
          reason: 'CE TEST DIT L INVERSE DE CE QU IL DISAIT LE MATIN DU 27/09, '
              'et ce n est pas un relachement : Chris a retire sa garde « en '
              'mode trek jamais » a 14:41 — « TOUT PORTER LA PUB sauf si tu es '
              'abonne ou sur le trek que tu as achete .. Pas la peine de mettre '
              'plus de regles ». Deux exceptions, pas trois. Un sentier gratuit '
              'n est ni abonne ni achete, meme quand on le marche. NE REMETS PAS '
              'DE GARDE ICI : ce serait ajouter la regle qu il vient d enlever');
      expect(regie.demandes, hasLength(1));
    });

    test('marcher un sentier ACHETE reste sans pub — l exception suffit',
        () async {
      final (c, monetisation) = await monterLeMonde(
        tracking: TrackingSessionStatus.recording,
      );
      await portefeuille.credit(10);
      expect((await monetisation.buyTrail('gr20', totalStages: 10)).isOwned,
          isTrue);

      expect(await c.read(bannerAdProvider('gr20').future), isNull,
          reason: 'VOILA POURQUOI LA GARDE ETAIT REDONDANTE SUR LES SENTIERS '
              'PAYANTS, et c est le raisonnement que Chris tenait lui-meme le '
              'matin : « il paye FORCEMENT en mode trek ». On ne realise un trek '
              'payant qu en l ayant achete (verrou canRealizeTrail, lot 594), et '
              'un trek achete est deja sans pub. L exception « sentier achete » '
              'couvre donc toute la realisation payante, sans regle de plus');
      expect(regie.demandes, isEmpty);
    });

    test('un ABONNE actif : aucune pub sur le sentier gratuit non plus',
        () async {
      final (c, monetisation) =
          await monterLeMonde(sentiersGratuits: {gratuit});
      await monetisation.onSubscriptionValidated();

      expect(await c.read(bannerAdProvider(gratuit).future), isNull,
          reason: 'l abonnement a 2 euros donne « pub nulle part » tant qu il '
              'est actif — un sentier gratuit n y fait pas exception');
      expect(regie.demandes, isEmpty);
    });

    test('le sentier gratuit ne porte PAS le sans-pub permanent d un achat',
        () async {
      final (c, monetisation) =
          await monterLeMonde(sentiersGratuits: {gratuit});
      await portefeuille.credit(10);
      expect((await monetisation.buyTrail('gr20', totalStages: 10)).isOwned,
          isTrue);

      expect(await c.read(bannerAdProvider('gr20').future), isNull,
          reason: 'le sentier ACHETE est sans pub, et le reste');
      expect(await c.read(bannerAdProvider(gratuit).future), isNotNull,
          reason: 'le sentier GRATUIT, lui, n a rien paye : cette difference '
              'est le coeur de la tache 601 — un achat donne un privilege '
              'permanent, la gratuite n en donne aucun');
    });
  });
}
